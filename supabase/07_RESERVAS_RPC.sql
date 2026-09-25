-- ============================================================
-- MediReserva - CRUD de reservas y reserva atomica (RPC)
--
-- PROBLEMA QUE CORRIGE  (observado por el tutor en el E1)
--   RF-06 dice que cancelar libera el bloque. Con un UNIQUE simple
--   sobre disponibilidad_id, una reserva CANCELADA seguiria ocupando
--   el indice y el bloque no se podria volver a reservar.
--   Ademas, POST /reservas recibia paciente_id desde el cliente.
--
-- COMO LO RESUELVE
--   1. reservar_cita()  -> inserta la cita Y marca el bloque en una
--      sola transaccion, con bloqueo FOR UPDATE para que dos intentos
--      simultaneos sobre el mismo horario no puedan ganar los dos.
--   2. paciente_id sale SIEMPRE de auth.uid(): el cliente nunca lo
--      envia (el servidor no confia en el cliente).
--   3. cancelar_cita()  -> da de baja con estado 'cancelled' y libera
--      el bloque. No se borra la fila: la trazabilidad se conserva.
--   4. cambiar_estado_reserva() -> el "editar" del CRUD, con dominio
--      cerrado y autorizacion por rol.
--
-- COMO APLICARLO
--   Supabase -> SQL Editor -> New query -> pegar todo -> Run.
--   Idempotente.
--
-- ORDEN: despues de supabase/05_ROLES_Y_RLS.sql.
-- ============================================================

-- ------------------------------------------------------------
-- 1. RESERVAR (Create). Una sola funcion = una sola transaccion.
-- ------------------------------------------------------------
create or replace function public.reservar_cita(
  p_doctor_id    uuid,
  p_specialty_id uuid,
  p_fecha        date,
  p_hora         time
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_paciente   uuid := auth.uid();
  v_bloque     public.doctor_availability;
  v_cita       public.appointments;
  v_especialidad text;
  v_medico     text;
begin
  -- (401) Sin sesion no hay reserva.
  if v_paciente is null then
    raise exception 'Debes iniciar sesion para reservar una cita.'
      using errcode = '42501';
  end if;

  -- (400) Validacion en servidor: fecha pasada.
  if p_fecha < current_date then
    raise exception 'No se pueden reservar citas en fechas pasadas.'
      using errcode = '22007';
  end if;

  -- (422) El medico debe pertenecer a la especialidad indicada.
  if not exists (
    select 1 from public.doctors d
    where d.id = p_doctor_id
      and d.specialty_id = p_specialty_id
      and d.active = true
  ) then
    raise exception 'El profesional no corresponde a la especialidad elegida.'
      using errcode = '22023';
  end if;

  -- Autorrepara el perfil si el trigger no alcanzo a crearlo.
  -- Elimina de raiz el error 23503 al reservar.
  insert into public.profiles (id, full_name, email, phone, birth_date)
  select
    u.id,
    coalesce(u.raw_user_meta_data->>'full_name', ''),
    coalesce(u.email, ''),
    u.raw_user_meta_data->>'phone',
    case
      when coalesce(u.raw_user_meta_data->>'birth_date', '') = '' then null
      else (u.raw_user_meta_data->>'birth_date')::date
    end
  from auth.users u
  where u.id = v_paciente
  on conflict (id) do nothing;

  -- Bloquea la fila del horario. El segundo intento espera aqui y
  -- al continuar ya encuentra is_available = false.
  select *
    into v_bloque
  from public.doctor_availability
  where doctor_id = p_doctor_id
    and available_date = p_fecha
    and appointment_time = p_hora
  for update;

  -- (404) El horario no existe en la oferta del profesional.
  if not found then
    raise exception 'El horario elegido no esta en la oferta del profesional.'
      using errcode = 'P0002';
  end if;

  -- (409) Alguien lo tomo un instante antes.
  if not v_bloque.is_available then
    raise exception 'Ese horario acaba de ser reservado por otro paciente.'
      using errcode = '23505';
  end if;

  -- Ocupa el bloque.
  update public.doctor_availability
     set is_available = false
   where id = v_bloque.id;

  -- Crea la cita. patient_id NUNCA viene del cliente.
  insert into public.appointments (
    patient_id, specialty_id, doctor_id, appointment_date, appointment_time, status
  )
  values (
    v_paciente, p_specialty_id, p_doctor_id, p_fecha, p_hora, 'confirmed'
  )
  returning * into v_cita;

  select s.name, d.name
    into v_especialidad, v_medico
  from public.doctors d
  left join public.specialties s on s.id = d.specialty_id
  where d.id = p_doctor_id;

  -- Misma forma que el select de la app -> Appointment.fromMap reutilizable.
  return jsonb_build_object(
    'id',               v_cita.id,
    'reservation_number', v_cita.reservation_number,
    'appointment_date', v_cita.appointment_date,
    'appointment_time', v_cita.appointment_time,
    'status',           v_cita.status,
    'specialties',      jsonb_build_object('name', v_especialidad),
    'doctors',          jsonb_build_object('name', v_medico)
  );

exception
  when unique_violation then
    raise exception 'Ese horario acaba de ser reservado por otro paciente.'
      using errcode = '23505';
end;
$$;

-- ------------------------------------------------------------
-- 2. CANCELAR / DAR DE BAJA (Update de estado + libera el bloque).
-- ------------------------------------------------------------
create or replace function public.cancelar_cita(p_cita_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cita public.appointments;
begin
  select * into v_cita
  from public.appointments
  where id = p_cita_id
  for update;

  if not found then
    raise exception 'La reserva no existe.' using errcode = 'P0002';
  end if;

  -- (403) Solo el dueno de la reserva o un administrador.
  if v_cita.patient_id <> auth.uid() and not public.es_administrador() then
    raise exception 'No puedes cancelar una reserva que no es tuya.'
      using errcode = '42501';
  end if;

  -- (409) No se cancela dos veces ni una cita ya atendida.
  if v_cita.status = 'cancelled' then
    raise exception 'Esa reserva ya estaba cancelada.' using errcode = '23505';
  end if;

  if v_cita.status = 'completed' then
    raise exception 'Una consulta ya atendida no se puede cancelar.'
      using errcode = '23514';
  end if;

  update public.appointments
     set status = 'cancelled'
   where id = p_cita_id;

  -- Libera el bloque para que otro paciente pueda reservarlo.
  update public.doctor_availability
     set is_available = true
   where doctor_id = v_cita.doctor_id
     and available_date = v_cita.appointment_date
     and appointment_time = v_cita.appointment_time;

  return jsonb_build_object('id', p_cita_id, 'status', 'cancelled');
end;
$$;

-- ------------------------------------------------------------
-- 3. EDITAR ESTADO (el "editar" del CRUD, con dominio cerrado).
--    Profesional dueno de la agenda o administrador.
-- ------------------------------------------------------------
create or replace function public.cambiar_estado_reserva(
  p_cita_id uuid,
  p_estado  text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cita public.appointments;
begin
  if p_estado not in ('pending', 'confirmed', 'cancelled', 'completed') then
    raise exception 'Estado invalido: %. Use pending, confirmed, cancelled o completed.', p_estado
      using errcode = '22023';
  end if;

  select * into v_cita
  from public.appointments
  where id = p_cita_id
  for update;

  if not found then
    raise exception 'La reserva no existe.' using errcode = 'P0002';
  end if;

  if not (public.es_administrador() or public.es_mi_agenda(v_cita.doctor_id)) then
    raise exception 'Solo el profesional asignado o un administrador pueden cambiar el estado.'
      using errcode = '42501';
  end if;

  update public.appointments
     set status = p_estado
   where id = p_cita_id;

  -- Un estado terminal libera el bloque; volver a activo lo ocupa.
  update public.doctor_availability
     set is_available = (p_estado = 'cancelled' or p_estado = 'completed')
   where doctor_id = v_cita.doctor_id
     and available_date = v_cita.appointment_date
     and appointment_time = v_cita.appointment_time;

  return jsonb_build_object('id', p_cita_id, 'status', p_estado);
end;
$$;

-- ------------------------------------------------------------
-- 4. Permisos de ejecucion.
-- ------------------------------------------------------------
revoke all on function public.reservar_cita(uuid, uuid, date, time) from public, anon;
revoke all on function public.cancelar_cita(uuid) from public, anon;
revoke all on function public.cambiar_estado_reserva(uuid, text) from public, anon;

grant execute on function public.reservar_cita(uuid, uuid, date, time) to authenticated;
grant execute on function public.cancelar_cita(uuid) to authenticated;
grant execute on function public.cambiar_estado_reserva(uuid, text) to authenticated;

-- ------------------------------------------------------------
-- 5. Verificacion.
-- ------------------------------------------------------------
select
  a.reservation_number,
  p.email as paciente,
  s.name  as especialidad,
  d.name  as profesional,
  a.appointment_date,
  a.appointment_time,
  a.status
from public.appointments a
join public.profiles  p on p.id = a.patient_id
join public.doctors   d on d.id = a.doctor_id
join public.specialties s on s.id = a.specialty_id
order by a.appointment_date desc, a.appointment_time desc
limit 20;

select
  count(*) filter (where is_available)     as bloques_libres,
  count(*) filter (where not is_available) as bloques_ocupados
from public.doctor_availability
where available_date >= current_date;
