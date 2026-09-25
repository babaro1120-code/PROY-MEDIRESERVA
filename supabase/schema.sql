-- ============================================================
-- MediReserva - esquema inicial para Supabase
-- Ejecutar en Supabase SQL Editor.
-- ============================================================

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text not null default '',
  phone text,
  birth_date date,
  address text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.specialties (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon_name text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.doctors (
  id uuid primary key default gen_random_uuid(),
  specialty_id uuid not null references public.specialties(id),
  name text not null,
  photo_url text,
  experience_years integer not null default 0,
  rating numeric(2,1) not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.doctor_availability (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  available_date date not null,
  appointment_time time not null,
  is_available boolean not null default true,
  unique (doctor_id, available_date, appointment_time)
);

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  reservation_number text not null unique default (
    'MR-' || to_char(now(), 'YYYYMMDD') || '-' ||
    upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8))
  ),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  specialty_id uuid not null references public.specialties(id),
  doctor_id uuid not null references public.doctors(id),
  appointment_date date not null,
  appointment_time time not null,
  status text not null default 'pending'
    check (status in ('pending','confirmed','cancelled','completed')),
  created_at timestamptz not null default now()
);

create unique index if not exists appointments_active_slot_unique
on public.appointments (doctor_id, appointment_date, appointment_time)
where status <> 'cancelled';

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null default 'info',
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- Crear perfil automáticamente al registrarse en Auth.
-- ------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, phone, birth_date)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.email, ''),
    new.raw_user_meta_data->>'phone',
    case
      when coalesce(new.raw_user_meta_data->>'birth_date', '') = '' then null
      else (new.raw_user_meta_data->>'birth_date')::date
    end
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- ------------------------------------------------------------
-- RLS
-- ------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.specialties enable row level security;
alter table public.doctors enable row level security;
alter table public.doctor_availability enable row level security;
alter table public.appointments enable row level security;
alter table public.notifications enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select
to authenticated
using (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- Permite que la app cree su propio perfil si el trigger no lo hizo.
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "specialties_read_authenticated" on public.specialties;
create policy "specialties_read_authenticated"
on public.specialties for select
to authenticated
using (active = true);

drop policy if exists "doctors_read_authenticated" on public.doctors;
create policy "doctors_read_authenticated"
on public.doctors for select
to authenticated
using (active = true);

drop policy if exists "availability_read_authenticated" on public.doctor_availability;
create policy "availability_read_authenticated"
on public.doctor_availability for select
to authenticated
using (is_available = true);

drop policy if exists "appointments_read_own" on public.appointments;
create policy "appointments_read_own"
on public.appointments for select
to authenticated
using (patient_id = auth.uid());

drop policy if exists "appointments_insert_own" on public.appointments;
create policy "appointments_insert_own"
on public.appointments for insert
to authenticated
with check (patient_id = auth.uid());

drop policy if exists "appointments_update_own" on public.appointments;
create policy "appointments_update_own"
on public.appointments for update
to authenticated
using (patient_id = auth.uid())
with check (patient_id = auth.uid());

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

-- ------------------------------------------------------------
-- Datos iniciales
-- ------------------------------------------------------------
insert into public.specialties (name, icon_name)
values
  ('Medicina General', 'medical_services'),
  ('Pediatría', 'child_care'),
  ('Cardiología', 'favorite'),
  ('Dermatología', 'face'),
  ('Ginecología', 'pregnant_woman'),
  ('Odontología', 'dentistry'),
  ('Oftalmología', 'visibility')
on conflict (name) do nothing;

insert into public.doctors
  (specialty_id, name, experience_years, rating)
select id, 'Dra. Ana López', 7, 4.9
from public.specialties
where name = 'Medicina General'
and not exists (
  select 1 from public.doctors d
  where d.name = 'Dra. Ana López'
);

insert into public.doctors
  (specialty_id, name, experience_years, rating)
select id, 'Dr. Juan Pérez', 6, 4.8
from public.specialties
where name = 'Medicina General'
and not exists (
  select 1 from public.doctors d
  where d.name = 'Dr. Juan Pérez'
);

insert into public.doctors
  (specialty_id, name, experience_years, rating)
select id, 'Dra. Laura Gómez', 5, 4.7
from public.specialties
where name = 'Medicina General'
and not exists (
  select 1 from public.doctors d
  where d.name = 'Dra. Laura Gómez'
);

-- Ejemplo de horarios para los próximos 30 días.
insert into public.doctor_availability
  (doctor_id, available_date, appointment_time)
select
  d.id,
  current_date + gs.day_offset,
  t.slot
from public.doctors d
cross join generate_series(1, 30) as gs(day_offset)
cross join (
  values
    ('08:00:00'::time),
    ('09:00:00'::time),
    ('10:00:00'::time),
    ('11:00:00'::time),
    ('12:00:00'::time),
    ('13:00:00'::time),
    ('15:00:00'::time),
    ('16:00:00'::time),
    ('17:00:00'::time)
) as t(slot)
where extract(isodow from current_date + gs.day_offset) between 1 and 5
on conflict (doctor_id, available_date, appointment_time) do nothing;
