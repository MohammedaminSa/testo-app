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
  -- The randomized "paper" served for this attempt: question ids in the
  -- order they were presented, plus each question's answer. Stored so the
  -- review screen can be rebuilt and weak areas tracked fairly.
  questions_order jsonb not null default '[]'::jsonb,
  answers jsonb not null default '[]'::jsonb,
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

-- ============================================================================
-- Quiz content (quizzes, questions, options)
-- Content is read-only for users; the app fetches it with nested embeds.
-- ============================================================================

create table if not exists public.quizzes (
  id text primary key,
  title text not null,
  description text not null,
  -- Content metadata for filtering/browsing in the app.
  category text not null default 'General',
  difficulty text not null default 'Beginner',
  tags text[] not null default '{}',
  -- Optional per-question time limit in seconds (null = untimed).
  time_limit_seconds integer,
  -- Optional fixed paper length (null = use all questions).
  paper_size integer,
  created_at timestamptz not null default now()
);

create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id text not null references public.quizzes (id) on delete cascade,
  position integer not null,
  text text not null,
  explanation text not null default '',
  -- Topic used for weak-area tracking (e.g. "Algorithms").
  topic text not null default 'General',
  unique (quiz_id, position)
);

create table if not exists public.options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions (id) on delete cascade,
  position integer not null,
  text text not null,
  is_correct boolean not null default false,
  unique (question_id, position)
);

-- Index so nested selects stay fast
create index if not exists questions_quiz_id_idx on public.questions (quiz_id);
create index if not exists options_question_id_idx on public.options (question_id);

-- RLS: anyone signed in can read content; only the app owner can write
alter table public.quizzes enable row level security;
alter table public.questions enable row level security;
alter table public.options enable row level security;

drop policy if exists "Quizzes readable by users" on public.quizzes;
create policy "Quizzes readable by users"
  on public.quizzes for select
  using (auth.role() = 'authenticated');

drop policy if exists "Questions readable by users" on public.questions;
create policy "Questions readable by users"
  on public.questions for select
  using (auth.role() = 'authenticated');

drop policy if exists "Options readable by users" on public.options;
create policy "Options readable by users"
  on public.options for select
  using (auth.role() = 'authenticated');

-- ============================================================================
-- Profiles
-- One row per auth user, created automatically on signup via trigger.
-- Users can read/update only their own profile.
-- ============================================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Users read own profile" on public.profiles;
create policy "Users read own profile"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "Users insert own profile" on public.profiles;
create policy "Users insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Auto-create a profile row whenever a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', ''));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
