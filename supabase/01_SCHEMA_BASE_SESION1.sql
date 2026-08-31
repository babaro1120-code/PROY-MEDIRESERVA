create extension if not exists pgcrypto;

create table if not exists public.registros_demo (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  titulo text not null check (char_length(titulo) between 3 and 80),
  descripcion text not null default '',
  estado text not null default 'activo'
    check (estado in ('pendiente', 'activo', 'cerrado')),
  created_at timestamptz not null default now()
);

create index if not exists registros_demo_user_idx
on public.registros_demo(user_id);

alter table public.registros_demo enable row level security;

drop policy if exists "registros_select_own" on public.registros_demo;
create policy "registros_select_own"
on public.registros_demo
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "registros_insert_own" on public.registros_demo;
create policy "registros_insert_own"
on public.registros_demo
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "registros_update_own" on public.registros_demo;
create policy "registros_update_own"
on public.registros_demo
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "registros_delete_own" on public.registros_demo;
create policy "registros_delete_own"
on public.registros_demo
for delete
to authenticated
using (user_id = auth.uid());

grant usage on schema public to authenticated;
grant select, insert, update, delete
on table public.registros_demo
to authenticated;

revoke all on table public.registros_demo from anon;
