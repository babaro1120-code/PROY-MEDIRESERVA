-- ============================================================
-- MediReserva - integridad de la disponibilidad (RF-07)
--
-- QUE HACE
--   Impide que un profesional publique dos veces el MISMO bloque de
--   atención (mismo médico, misma fecha y misma hora). Sin esta
--   restriccion, un doble clic en la pantalla "Mi Disponibilidad"
--   dejaria dos filas identicas y el horario apareceria duplicado.
--
-- POR QUE EN UN ARCHIVO APARTE
--   Va separado de 05_ROLES_Y_RLS.sql para que un eventual duplicado
--   preexistente no haga fallar el script de roles y RLS, que es el
--   critico para el E3. Este archivo es seguro: primero limpia los
--   duplicados y despues crea el indice. Es idempotente.
--
-- COMO APLICARLO
--   Supabase -> SQL Editor -> New query -> pegar todo -> Run.
--
-- ORDEN: despues de supabase/05_ROLES_Y_RLS.sql.
-- ============================================================

-- ------------------------------------------------------------
-- PASO 1. Informe: que duplicados hay hoy (si hay).
--   Se conserva la fila mas antigua de cada grupo; el resto se quita
--   en el paso 2. No hay claves foraneas que apunten a esta tabla,
--   asi que quitar una fila duplicada no afecta a ninguna reserva.
-- ------------------------------------------------------------
select
  doctor_id,
  available_date,
  appointment_time,
  count(*) as veces
from public.doctor_availability
group by doctor_id, available_date, appointment_time
having count(*) > 1
order by veces desc;

-- ------------------------------------------------------------
-- PASO 2. Quitar los duplicados conservando el mas antiguo.
-- ------------------------------------------------------------
delete from public.doctor_availability d
using public.doctor_availability k
where d.doctor_id = k.doctor_id
  and d.available_date = k.available_date
  and d.appointment_time = k.appointment_time
  and d.id > k.id;

-- ------------------------------------------------------------
-- PASO 3. La restriccion: un bloque, una sola fila.
-- ------------------------------------------------------------
create unique index if not exists doctor_availability_slot_unique
  on public.doctor_availability(doctor_id, available_date, appointment_time);

-- ------------------------------------------------------------
-- PASO 4. Verificacion.
--   Debe devolver el indice y cero duplicados.
-- ------------------------------------------------------------
select indexname
from pg_indexes
where schemaname = 'public'
  and tablename = 'doctor_availability'
  and indexname = 'doctor_availability_slot_unique';

select count(*) as duplicados_restantes
from (
  select 1
  from public.doctor_availability
  group by doctor_id, available_date, appointment_time
  having count(*) > 1
) as d;
