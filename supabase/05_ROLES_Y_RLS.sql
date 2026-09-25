-- ============================================================
-- MediReserva - roles y autorizacion por rol (RF-13, RNF-02)
--
-- QUE HACE
--   1. Agrega la columna profiles.role con dominio cerrado.
--   2. Vincula cada profesional (doctors) con su cuenta de Auth.
--   3. Crea rol_actual() y es_administrador() como helpers RLS.
--   4. IMPIDE que el autorregistro se regale un rol privilegiado
--      (el "error de seguridad mas caro" del Modulo 4 / P3).
--   5. Reescribe las politicas RLS por rol.
--
-- COMO APLICARLO
--   Supabase -> SQL Editor -> New query -> pegar todo -> Run.
--   Es idempotente: se puede ejecutar varias veces.
--
-- ORDEN: ejecutar DESPUES de supabase/schema.sql.
-- ============================================================

-- ------------------------------------------------------------
-- PASO 1. Columna role con dominio cerrado (nunca texto libre).
--   4 tipos de usuario -> 3 roles:
--     recepcionista NO es un rol aparte: es un administrador.
-- ------------------------------------------------------------
alter table public.profiles
  add column if not exists role text not null default 'paciente';

alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check
  check (role in ('paciente', 'profesional', 'administrador'));

create index if not exists profiles_role_idx on public.profiles(role);

-- ------------------------------------------------------------
-- PASO 2. Enlace profesional <-> cuenta de Auth.
--   Sin esto, un profesional no puede ver su propia agenda.
-- ------------------------------------------------------------
alter table public.doctors
  add column if not exists profile_id uuid references public.profiles(id) on delete set null;

create unique index if not exists doctors_profile_id_uidx
  on public.doctors(profile_id)
  where profile_id is not null;

-- ------------------------------------------------------------
-- PASO 3. Helpers de autorizacion.
--   SECURITY DEFINER: leen profiles saltando RLS. Sin esto, una
--   politica sobre profiles que consulte profiles entra en
--   recursion infinita.
-- ------------------------------------------------------------
create or replace function public.rol_actual()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select p.role from public.profiles p where p.id = auth.uid()),
    'anonimo'
  );
$$;

create or replace function public.es_administrador()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.rol_actual() = 'administrador';
$$;

-- El profesional dueno de esa fila de doctors.
create or replace function public.es_mi_agenda(p_doctor_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.doctors d
    where d.id = p_doctor_id
      and d.profile_id = auth.uid()
  );
$$;

-- El paciente atendido por el profesional autenticado.
create or replace function public.es_mi_paciente(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.appointments a
    join public.doctors d on d.id = a.doctor_id
    where a.patient_id = p_profile_id
      and d.profile_id = auth.uid()
  );
$$;

-- ------------------------------------------------------------
-- PASO 4. Blindaje del rol: el autorregistro NO elige su rol.
--   - INSERT desde la app  -> el rol se fuerza a 'paciente'.
--   - UPDATE del rol       -> solo un administrador.
--   - SQL Editor / service_role (auth.uid() nulo) -> permitido,
--     que es la via controlada para nombrar al primer admin.
-- ------------------------------------------------------------
create or replace function public.profiles_proteger_rol()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    if auth.uid() is not null and not public.es_administrador() then
      new.role := 'paciente';
    end if;

  elsif tg_op = 'UPDATE' then
    if new.role is distinct from old.role
       and auth.uid() is not null
       and not public.es_administrador() then
      raise exception 'Solo un administrador puede cambiar el rol de un usuario.'
        using errcode = '42501';
    end if;
  end if;

  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists profiles_proteger_rol_trg on public.profiles;
create trigger profiles_proteger_rol_trg
before insert or update on public.profiles
for each row execute function public.profiles_proteger_rol();

-- ------------------------------------------------------------
-- PASO 5. Politicas RLS por rol.
-- ------------------------------------------------------------
alter table public.profiles            enable row level security;
alter table public.specialties         enable row level security;
alter table public.doctors             enable row level security;
alter table public.doctor_availability enable row level security;
alter table public.appointments        enable row level security;
alter table public.notifications       enable row level security;

-- ---- profiles ----
drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_select_por_rol" on public.profiles;
create policy "profiles_select_por_rol"
on public.profiles for select
to authenticated
using (
  id = auth.uid()
  or public.es_administrador()
  or public.es_mi_paciente(id)
);

drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_update_own_o_admin" on public.profiles;
create policy "profiles_update_own_o_admin"
on public.profiles for update
to authenticated
using (id = auth.uid() or public.es_administrador())
with check (id = auth.uid() or public.es_administrador());

-- Se conserva la politica de insercion propia: la app autorrepara el
-- perfil que falte. El trigger del PASO 4 impide que se regale el rol.
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles for insert
to authenticated
with check (id = auth.uid());

-- ---- catalogos: lectura para todos, escritura solo del administrador ----
drop policy if exists "specialties_read_authenticated" on public.specialties;
create policy "specialties_read_authenticated"
on public.specialties for select
to authenticated
using (active = true);

drop policy if exists "specialties_admin_write" on public.specialties;
create policy "specialties_admin_write"
on public.specialties for all
to authenticated
using (public.es_administrador())
with check (public.es_administrador());

drop policy if exists "doctors_read_authenticated" on public.doctors;
create policy "doctors_read_authenticated"
on public.doctors for select
to authenticated
using (active = true);

drop policy if exists "doctors_admin_write" on public.doctors;
create policy "doctors_admin_write"
on public.doctors for all
to authenticated
using (public.es_administrador())
with check (public.es_administrador());

-- El profesional tambien necesita leer su propia fila aunque este inactiva.
drop policy if exists "doctors_read_own_row" on public.doctors;
create policy "doctors_read_own_row"
on public.doctors for select
to authenticated
using (profile_id = auth.uid());

-- ---- disponibilidad ----
drop policy if exists "availability_read_authenticated" on public.doctor_availability;
create policy "availability_read_authenticated"
on public.doctor_availability for select
to authenticated
using (is_available = true or public.es_administrador() or public.es_mi_agenda(doctor_id));

-- El profesional gestiona SU disponibilidad; el administrador, toda.
drop policy if exists "availability_profesional_o_admin_write" on public.doctor_availability;
create policy "availability_profesional_o_admin_write"
on public.doctor_availability for all
to authenticated
using (public.es_administrador() or public.es_mi_agenda(doctor_id))
with check (public.es_administrador() or public.es_mi_agenda(doctor_id));

-- ---- appointments ----
drop policy if exists "appointments_read_own" on public.appointments;
drop policy if exists "appointments_read_por_rol" on public.appointments;
create policy "appointments_read_por_rol"
on public.appointments for select
to authenticated
using (
  patient_id = auth.uid()
  or public.es_administrador()
  or public.es_mi_agenda(doctor_id)
);

drop policy if exists "appointments_insert_own" on public.appointments;
create policy "appointments_insert_own"
on public.appointments for insert
to authenticated
with check (patient_id = auth.uid());

drop policy if exists "appointments_update_own" on public.appointments;
drop policy if exists "appointments_update_por_rol" on public.appointments;
create policy "appointments_update_por_rol"
on public.appointments for update
to authenticated
using (
  patient_id = auth.uid()
  or public.es_administrador()
  or public.es_mi_agenda(doctor_id)
)
with check (
  patient_id = auth.uid()
  or public.es_administrador()
  or public.es_mi_agenda(doctor_id)
);

-- Sin politica de DELETE a proposito: la trazabilidad se conserva
-- dando de baja con estado 'cancelled' (PATCH), no borrando la fila.

-- ---- notifications ----
drop policy if exists "notifications_read_own" on public.notifications;
create policy "notifications_read_own"
on public.notifications for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
on public.notifications for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- Sin politica de INSERT a proposito: las notificaciones solo las
-- generan los triggers (SECURITY DEFINER). Asi el cliente no puede
-- fabricar avisos oficiales.

-- ------------------------------------------------------------
-- PASO 6. Permisos explicitos.
-- ------------------------------------------------------------
grant usage on schema public to authenticated;
grant select, insert, update on table public.profiles            to authenticated;
grant select, insert, update, delete on table public.specialties to authenticated;
grant select, insert, update, delete on table public.doctors     to authenticated;
grant select, insert, update, delete on table public.doctor_availability to authenticated;
grant select, insert, update on table public.appointments        to authenticated;
grant select, update on table public.notifications               to authenticated;

-- ------------------------------------------------------------
-- PASO 7. NOMBRAR AL PRIMER ADMINISTRADOR.
--
--   El autorregistro siempre nace 'paciente'. Para crear el primer
--   administrador: registrate en la app con el correo elegido y
--   despues ejecuta esta linea cambiando el correo.
--
--   update public.profiles
--      set role = 'administrador'
--    where email = 'admin@medireserva.test';
--
--   Para nombrar un profesional, vincular su fila de doctors:
--
--   update public.doctors d
--      set profile_id = p.id
--     from public.profiles p
--    where p.email = 'profesional@medireserva.test'
--      and d.name = 'Dra. Ana Lopez';
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- PASO 8. Verificacion.
-- ------------------------------------------------------------
select
  role,
  count(*) as usuarios
from public.profiles
group by role
order by role;

select
  d.name as profesional,
  coalesce(p.email, '(sin vincular)') as cuenta,
  (d.profile_id is not null) as vinculado
from public.doctors d
left join public.profiles p on p.id = d.profile_id
order by d.name;
