-- GATO schema. Run once in the Supabase SQL editor of the GATO project.
create table if not exists public.gato_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null default '',
  body text not null default '',
  mood text,
  tags text[] not null default '{}',
  entry_date date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.gato_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null default '',
  body text not null default '',
  color text not null default 'lime',
  pinned boolean not null default false,
  checklist jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.gato_quotes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  text text not null,
  source text not null default '',
  favorite boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.gato_voice_memos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null default '',
  storage_path text not null,
  duration_ms integer not null default 0,
  markers jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists gato_entries_user_idx on public.gato_entries(user_id, entry_date desc);
create index if not exists gato_notes_user_idx on public.gato_notes(user_id, created_at desc);
create index if not exists gato_quotes_user_idx on public.gato_quotes(user_id, created_at desc);
create index if not exists gato_voice_user_idx on public.gato_voice_memos(user_id, created_at desc);

alter table public.gato_entries enable row level security;
alter table public.gato_notes enable row level security;
alter table public.gato_quotes enable row level security;
alter table public.gato_voice_memos enable row level security;

create policy gato_entries_own on public.gato_entries for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy gato_notes_own on public.gato_notes for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy gato_quotes_own on public.gato_quotes for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy gato_voice_own on public.gato_voice_memos for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

insert into storage.buckets (id, name, public) values ('gato-voice', 'gato-voice', false)
  on conflict (id) do nothing;
create policy gato_voice_files_own on storage.objects for all to authenticated
  using (bucket_id = 'gato-voice' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'gato-voice' and (storage.foldername(name))[1] = (select auth.uid())::text);
