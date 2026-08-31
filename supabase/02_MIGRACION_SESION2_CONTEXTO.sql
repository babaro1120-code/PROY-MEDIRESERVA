alter table public.registros_demo
add column if not exists latitude double precision;

alter table public.registros_demo
add column if not exists longitude double precision;

alter table public.registros_demo
add column if not exists temperature_c double precision;

alter table public.registros_demo
add column if not exists weather_code integer;

alter table public.registros_demo
add column if not exists weather_summary text;

alter table public.registros_demo
add column if not exists context_source text;

alter table public.registros_demo
add column if not exists context_captured_at timestamptz;

grant select, insert, update, delete
on table public.registros_demo
to authenticated;
