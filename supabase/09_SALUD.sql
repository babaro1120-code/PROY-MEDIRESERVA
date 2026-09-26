-- ============================================================
-- MediReserva - Ruta de salud de la API
--
-- QUE HACE
--   Expone GET /rest/v1/rpc/salud: una ruta publica que confirma
--   que la API y la base de datos estan operativas. Sigue la
--   convencion del Modulo 4: 200 { "estado": "ok" }.
--
-- POR QUE
--   MediReserva usa Supabase como plataforma de backend, de modo que
--   la API es la que PostgREST genera desde PostgreSQL. Esta funcion
--   le da al proyecto una ruta de salud propia y verificable, sin
--   agregar una segunda base de codigo.
--
-- COMO APLICARLO
--   Supabase -> SQL Editor -> New query -> pegar todo -> Run.
--   Idempotente.
--
-- ORDEN: despues de supabase/07_RESERVAS_RPC.sql.
-- ============================================================

create or replace function public.salud()
returns jsonb
language sql
stable                     -- STABLE es lo que permite invocarla por GET
set search_path = public
as $$
  select jsonb_build_object(
    'estado',   'ok',
    'servicio', 'MediReserva',
    'version',  '1.0.0',
    'hora',     now()
  );
$$;

-- Ruta publica: puede consultarla tanto un visitante (anon) como un
-- usuario autenticado. No expone ningun dato del sistema.
grant execute on function public.salud() to anon, authenticated;

-- Fuerza a PostgREST a recargar su cache de esquema, para que exponga
-- la funcion de inmediato (si no, puede responder 404 por unos minutos).
notify pgrst, 'reload schema';

-- ------------------------------------------------------------
-- Verificacion: debe devolver {"estado":"ok", ...}
-- ------------------------------------------------------------
select public.salud() as salud;
