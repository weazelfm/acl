-- APEX COMBAT LEAGUE — configuração inicial do banco Supabase
-- Execute o arquivo inteiro no Supabase > SQL Editor > New query.
-- Seguro para reexecutar: as policies são recriadas, as tabelas não são apagadas.

create extension if not exists pgcrypto;

create table if not exists public.acl_state (
  id smallint primary key default 1 check (id = 1),
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.acl_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.acl_applications (
  id uuid primary key default gen_random_uuid(),
  first_name text not null check (length(trim(first_name)) between 1 and 35),
  nick text not null check (length(trim(nick)) between 1 and 35),
  last_name text not null check (length(trim(last_name)) between 1 and 35),
  division text not null check (division in ('fly','bantam','feather','light','welter','middle','lightheavy','heavy','wstraw')),
  origin text not null check (length(trim(origin)) between 1 and 90),
  gym text not null default 'Equipe independente' check (length(trim(gym)) between 1 and 80),
  arts jsonb not null check (jsonb_typeof(arts) = 'array' and jsonb_array_length(arts) between 1 and 8),
  bio text not null check (length(trim(bio)) between 15 and 700),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  approved_fighter_id text,
  created_at timestamptz not null default now()
);

create index if not exists acl_applications_created_at_idx
  on public.acl_applications (created_at desc);

-- Função usada pelas policies RLS. SECURITY DEFINER permite verificar a whitelist
-- sem abrir a tabela acl_admins para os demais usuários.
create or replace function public.is_acl_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.acl_admins a where a.user_id = auth.uid()
  );
$$;

revoke all on function public.is_acl_admin() from public;
grant execute on function public.is_acl_admin() to anon, authenticated;

grant usage on schema public to anon, authenticated;

alter table public.acl_state enable row level security;
alter table public.acl_admins enable row level security;
alter table public.acl_applications enable row level security;

-- Remova/crie as policies para o script poder ser executado novamente.
drop policy if exists "acl_state_public_read" on public.acl_state;
drop policy if exists "acl_state_admin_insert" on public.acl_state;
drop policy if exists "acl_state_admin_update" on public.acl_state;
drop policy if exists "acl_admins_read_self" on public.acl_admins;
drop policy if exists "acl_applications_public_submit" on public.acl_applications;
drop policy if exists "acl_applications_admin_read" on public.acl_applications;
drop policy if exists "acl_applications_admin_update" on public.acl_applications;
drop policy if exists "acl_applications_admin_delete" on public.acl_applications;

-- A base oficial é pública para leitura, mas só administradores autenticados podem alterá-la.
create policy "acl_state_public_read"
  on public.acl_state for select to anon, authenticated
  using (true);

create policy "acl_state_admin_insert"
  on public.acl_state for insert to authenticated
  with check (public.is_acl_admin());

create policy "acl_state_admin_update"
  on public.acl_state for update to authenticated
  using (public.is_acl_admin())
  with check (public.is_acl_admin());

-- O usuário autenticado pode conferir apenas sua própria linha de whitelist.
create policy "acl_admins_read_self"
  on public.acl_admins for select to authenticated
  using (user_id = auth.uid());

-- O público só pode enviar uma ficha ainda pendente. Não pode consultar a fila
-- nem marcar uma inscrição como aprovada/recusada.
create policy "acl_applications_public_submit"
  on public.acl_applications for insert to anon, authenticated
  with check (
    status = 'pending'
    and approved_fighter_id is null
    and length(trim(first_name)) between 1 and 35
    and length(trim(nick)) between 1 and 35
    and length(trim(last_name)) between 1 and 35
    and length(trim(origin)) between 1 and 90
    and length(trim(bio)) between 15 and 700
  );

create policy "acl_applications_admin_read"
  on public.acl_applications for select to authenticated
  using (public.is_acl_admin());

create policy "acl_applications_admin_update"
  on public.acl_applications for update to authenticated
  using (public.is_acl_admin())
  with check (public.is_acl_admin());

create policy "acl_applications_admin_delete"
  on public.acl_applications for delete to authenticated
  using (public.is_acl_admin());

-- Grants explícitos: RLS decide quais linhas podem ser acessadas.
grant select on public.acl_state to anon, authenticated;
grant insert, update on public.acl_state to authenticated;
grant select on public.acl_admins to authenticated;
grant insert on public.acl_applications to anon, authenticated;
grant select, update, delete on public.acl_applications to authenticated;

-- Não existe policy de DELETE para acl_state nem de escrita pública para acl_admins.
