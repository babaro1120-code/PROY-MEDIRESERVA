-- ============================================================
-- MediReserva - reparacion de perfiles faltantes  (v2)
--
-- QUE ERROR CORRIGE
--   Al pulsar "Confirmar cita":
--     PostgrestException 23503: insert or update on table "appointments"
--     violates foreign key constraint "appointments_patient_id_fkey"
--     Key is not present in table "profiles".
--
-- POR QUE PASA
--   La cuenta existe en auth.users, pero no tiene fila en public.profiles.
--   appointments.patient_id es clave foranea a profiles(id), por lo que el
--   insert se rechaza. Suele ocurrir con cuentas creadas antes de ejecutar
--   supabase/schema.sql, o si el trigger on_auth_user_created no existia.
--
-- COMO APLICARLO
--   1. Supabase -> SQL Editor -> New query.
--   2. Pega TODO el contenido de este archivo.
--   3. Pulsa Run.
--   4. La ultima consulta muestra usuarios_sin_perfil y debe valer 0.
--
-- Es idempotente: se puede ejecutar varias veces sin duplicar datos.
-- ============================================================

-- ------------------------------------------------------------
-- PASO 1. Funcion que crea el perfil al registrarse.
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

-- ------------------------------------------------------------
-- PASO 2. Trigger en auth.users (se recrea siempre).
-- ------------------------------------------------------------
drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- ------------------------------------------------------------
-- PASO 3. Permisos y RLS de public.profiles.
--   Cada usuario solo ve/crea/actualiza su propia fila.
--   Si RLS estaba desactivado, estas politicas no estorban.
-- ------------------------------------------------------------
grant select, insert, update on table public.profiles to authenticated;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select
to authenticated
using (id = auth.uid());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- ------------------------------------------------------------
-- PASO 4. Rellena los perfiles que faltan con los datos de auth.users.
--   Si la tabla tiene otras columnas, el bloque crea al menos la fila
--   con el id (que es lo que necesita la clave foranea).
-- ------------------------------------------------------------
do $$
begin
  begin
    -- Intento 1: copia todos los datos disponibles en Auth.
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
    where not exists (
      select 1 from public.profiles p where p.id = u.id
    );
  exception when others then
    begin
      -- Intento 2: tabla sin columnas phone/birth_date.
      insert into public.profiles (id, full_name, email)
      select
        u.id,
        coalesce(u.raw_user_meta_data->>'full_name', ''),
        coalesce(u.email, '')
      from auth.users u
      where not exists (
        select 1 from public.profiles p where p.id = u.id
      );
    exception when others then
      -- Intento 3: minimo imprescindible para la clave foranea.
      insert into public.profiles (id)
      select u.id
      from auth.users u
      where not exists (
        select 1 from public.profiles p where p.id = u.id
      );
    end;
  end;
end $$;

-- ------------------------------------------------------------
-- PASO 5. Verificacion: usuarios_sin_perfil debe valer 0.
-- ------------------------------------------------------------
select
  u.id,
  u.email,
  u.created_at,
  coalesce(u.raw_user_meta_data->>'full_name', '') as nombre_metadata
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null
order by u.created_at;

select count(*) as usuarios_sin_perfil
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null;