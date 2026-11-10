-- =====================================================================
-- w3rkraum Auftragsboard · Update 1.1: "Meine ToDos"
-- Einmal im Supabase SQL Editor ausführen (New query -> einfügen -> Run).
-- Kann gefahrlos mehrfach ausgeführt werden.
-- Jede Person sieht und ändert nur ihre eigene Liste.
-- =====================================================================
create table if not exists public.board_privat (
  user_id    uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  data       jsonb not null default '{"items":[]}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.board_privat enable row level security;

drop policy if exists "privat nur selbst" on public.board_privat;
create policy "privat nur selbst" on public.board_privat for all to authenticated
  using      (user_id = auth.uid() and public.board_ist_team())
  with check (user_id = auth.uid() and public.board_ist_team());

do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and schemaname = 'public'
                   and tablename = 'board_privat') then
    alter publication supabase_realtime add table public.board_privat;
  end if;
end $$;
