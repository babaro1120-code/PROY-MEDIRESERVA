-- ============================================================
-- MediReserva - eliminar el modulo DEMO del aula
--
-- QUE BORRA
--   La tabla public.registros_demo, andamiaje de las Sesiones 1 y 2
--   del aula (boton -> Future -> HTTP -> GPS -> mapa -> registro).
--   NO pertenece al dominio de MediReserva y ninguna pantalla de la
--   aplicacion la usa.
--
-- NO BORRA
--   Ninguna tabla del sistema: profiles, specialties, doctors,
--   doctor_availability, appointments y notifications quedan intactas.
--
-- COMO APLICARLO
--   Supabase -> SQL Editor -> New query -> pegar todo -> Run.
--   Idempotente.
-- ============================================================

-- Respaldo defensivo: si la tabla tiene datos que quieras conservar,
-- comenta el DROP y ejecuta primero esto.
-- create table if not exists public._respaldo_registros_demo as
--   select * from public.registros_demo;

-- Quita las politicas antes de borrar la tabla.
drop policy if exists "registros_select_own" on public.registros_demo;
drop policy if exists "registros_insert_own" on public.registros_demo;
drop policy if exists "registros_update_own" on public.registros_demo;
drop policy if exists "registros_delete_own" on public.registros_demo;

drop table if exists public.registros_demo cascade;

-- ------------------------------------------------------------
-- Verificacion: no debe devolver ninguna fila.
-- ------------------------------------------------------------
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name like '%demo%';

-- Inventario del sistema: las 6 tablas del dominio.
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_type = 'BASE TABLE'
order by table_name;
