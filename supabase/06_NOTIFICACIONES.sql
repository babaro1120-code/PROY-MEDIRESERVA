-- ============================================================
-- MediReserva - notificaciones reales
--
-- PROBLEMA QUE CORRIGE
--   La pantalla de notificaciones leia la tabla public.notifications,
--   pero NADA insertaba filas nunca: siempre aparecia vacia.
--   Ademas la tabla no tenia politica de INSERT, asi que un trigger
--   que corriera como el usuario tampoco habria podido escribir.
--
-- COMO LO RESUELVE
--   Las notificaciones las generan TRIGGERS con SECURITY DEFINER.
--   No se crea politica de INSERT a proposito: asi el cliente no
--   puede fabricar avisos oficiales (menor privilegio, rutas 403).
--
-- COMO APLICARLO
--   Supabase -> SQL Editor -> New query -> pegar todo -> Run.
--   Idempotente.
--
-- ORDEN: despues de supabase/05_ROLES_Y_RLS.sql.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Aviso de bienvenida al crear la cuenta.
-- ------------------------------------------------------------
create or replace function public.notificar_bienvenida()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, title, body, type)
  values (
    new.id,
    'Bienvenido a MediReserva',
    'Tu cuenta esta lista. Ya puedes reservar una consulta medica.',
    'info'
  );

  return new;
end;
$$;

drop trigger if exists notificar_bienvenida_trg on public.profiles;
create trigger notificar_bienvenida_trg
after insert on public.profiles
for each row execute function public.notificar_bienvenida();

-- ------------------------------------------------------------
-- 2. Reserva creada -> avisa al paciente y al profesional.
-- ------------------------------------------------------------
create or replace function public.notificar_reserva_creada()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_especialidad text;
  v_medico       text;
  v_doctor_profile uuid;
  v_fecha        text;
begin
  select s.name, d.name, d.profile_id
    into v_especialidad, v_medico, v_doctor_profile
  from public.doctors d
  left join public.specialties s on s.id = d.specialty_id
  where d.id = new.doctor_id;

  v_fecha := to_char(new.appointment_date, 'DD/MM/YYYY')
             || ' a las ' || to_char(new.appointment_time, 'HH24:MI');

  -- Al paciente.
  insert into public.notifications (user_id, title, body, type)
  values (
    new.patient_id,
    'Reserva registrada',
    'Tu cita de ' || coalesce(v_especialidad, 'consulta')
      || ' con ' || coalesce(v_medico, 'el profesional')
      || ' quedo para el ' || v_fecha
      || '. Codigo: ' || new.reservation_number || '.',
    'reserva'
  );

  -- Al profesional, si su cuenta esta vinculada.
  if v_doctor_profile is not null then
    insert into public.notifications (user_id, title, body, type)
    values (
      v_doctor_profile,
      'Nueva reserva en tu agenda',
      'Se reservo un turno para el ' || v_fecha
        || '. Codigo: ' || new.reservation_number || '.',
      'agenda'
    );
  end if;

  return new;
end;
$$;

drop trigger if exists notificar_reserva_creada_trg on public.appointments;
create trigger notificar_reserva_creada_trg
after insert on public.appointments
for each row execute function public.notificar_reserva_creada();

-- ------------------------------------------------------------
-- 3. Cambio de estado -> avisa al paciente (y al profesional).
-- ------------------------------------------------------------
create or replace function public.notificar_cambio_estado()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_fecha  text;
  v_titulo text;
  v_cuerpo text;
  v_doctor_profile uuid;
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  v_fecha := to_char(new.appointment_date, 'DD/MM/YYYY')
             || ' a las ' || to_char(new.appointment_time, 'HH24:MI');

  select d.profile_id into v_doctor_profile
  from public.doctors d where d.id = new.doctor_id;

  if new.status = 'cancelled' then
    v_titulo := 'Reserva cancelada';
    v_cuerpo := 'Tu cita del ' || v_fecha || ' (codigo '
                || new.reservation_number || ') fue cancelada. '
                || 'El horario quedo liberado.';
  elsif new.status = 'confirmed' then
    v_titulo := 'Reserva confirmada';
    v_cuerpo := 'Tu cita del ' || v_fecha || ' (codigo '
                || new.reservation_number || ') fue confirmada.';
  elsif new.status = 'completed' then
    v_titulo := 'Consulta atendida';
    v_cuerpo := 'La consulta del ' || v_fecha || ' (codigo '
                || new.reservation_number || ') figura como atendida.';
  else
    v_titulo := 'Reserva actualizada';
    v_cuerpo := 'Tu reserva ' || new.reservation_number
                || ' ahora figura como ' || new.status || '.';
  end if;

  insert into public.notifications (user_id, title, body, type)
  values (new.patient_id, v_titulo, v_cuerpo, 'reserva');

  if v_doctor_profile is not null and v_doctor_profile <> new.patient_id then
    insert into public.notifications (user_id, title, body, type)
    values (
      v_doctor_profile,
      v_titulo,
      'La reserva ' || new.reservation_number || ' del ' || v_fecha
        || ' ahora figura como ' || new.status || '.',
      'agenda'
    );
  end if;

  return new;
end;
$$;

drop trigger if exists notificar_cambio_estado_trg on public.appointments;
create trigger notificar_cambio_estado_trg
after update on public.appointments
for each row execute function public.notificar_cambio_estado();

-- ------------------------------------------------------------
-- 4. Verificacion: cuantas notificaciones hay por usuario.
-- ------------------------------------------------------------
select
  p.email,
  p.role,
  count(n.id) as notificaciones
from public.profiles p
left join public.notifications n on n.user_id = p.id
group by p.email, p.role
order by notificaciones desc, p.email;
