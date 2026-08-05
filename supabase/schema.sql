-- Testo - Supabase schema
-- Run this in the Supabase SQL editor.

-- Quiz attempts table
create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  quiz_id text not null,
  quiz_title text not null,
  total_questions integer not null,
  correct_answers integer not null,
  score_percent numeric(5,2) not null,
  completed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- Index for fast per-user history queries
create index if not exists quiz_attempts_user_completed_idx
  on public.quiz_attempts (user_id, completed_at desc);

-- RLS: users can only see/insert their own attempts
alter table public.quiz_attempts enable row level security;

drop policy if exists "Users read own attempts" on public.quiz_attempts;
create policy "Users read own attempts"
  on public.quiz_attempts for select
  using (auth.uid() = user_id);

drop policy if exists "Users insert own attempts" on public.quiz_attempts;
create policy "Users insert own attempts"
  on public.quiz_attempts for insert
  with check (auth.uid() = user_id);
