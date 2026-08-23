-- SUPABASE schema for GCSE Ace.
-- Run once in the Supabase SQL editor.
-- Order matters: parents before children.

-- =====================================================================
-- 1) PROFILES - one row per student
-- =====================================================================
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text not null,
  created_at  timestamptz not null default now()
);

-- =====================================================================
-- 2) DEPARTMENTS - subject areas (Maths, English, Science, ...)
-- =====================================================================
create table if not exists public.departments (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,
  slug        text not null unique,
  description text,
  created_at  timestamptz not null default now()
);

-- =====================================================================
-- 3) PAPERS - an exam or a past paper, belongs to one department
-- =====================================================================
create table if not exists public.papers (
  id               uuid primary key default gen_random_uuid(),
  department_id    uuid not null references public.departments (id) on delete cascade,
  title            text not null,
  year             integer not null,
  duration_minutes integer not null,
  total_marks      integer not null,
  created_at       timestamptz not null default now()
);

-- =====================================================================
-- 4) QUESTIONS - each question inside a paper
-- =====================================================================
create table if not exists public.questions (
  id           uuid primary key default gen_random_uuid(),
  paper_id     uuid not null references public.papers (id) on delete cascade,
  order_number integer not null,
  text         text not null,
  marks        integer not null,
  question_type text not null default 'multiple_choice'
    check (question_type in ('multiple_choice', 'written')),
  correct_answer text,
  explanation   text,
  created_at   timestamptz not null default now(),
  unique (paper_id, order_number)
);

-- =====================================================================
-- 5) OPTIONS - the multiple-choice choices for a question
-- =====================================================================
create table if not exists public.options (
  id          uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions (id) on delete cascade,
  letter      text not null,
  text        text not null,
  is_correct  boolean not null default false,
  unique (question_id, letter)
);

-- =====================================================================
-- 6) MATERIALS - study notes tied to a department
-- =====================================================================
create table if not exists public.materials (
  id            uuid primary key default gen_random_uuid(),
  department_id uuid not null references public.departments (id) on delete cascade,
  title         text not null,
  content       text not null,
  created_at    timestamptz not null default now()
);

-- =====================================================================
-- 7) ATTEMPTS - one student's run of one paper
-- =====================================================================
create table if not exists public.attempts (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users (id) on delete cascade,
  paper_id      uuid not null references public.papers (id) on delete cascade,
  started_at    timestamptz not null default now(),
  submitted_at  timestamptz,
  score         integer,
  total_marks   integer not null,
  answers       jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now()
);

-- =====================================================================
-- Convenient indexes for the queries we'll write later
-- =====================================================================
create index if not exists idx_papers_department on public.papers (department_id);
create index if not exists idx_questions_paper   on public.questions (paper_id);
create index if not exists idx_options_question  on public.options (question_id);
create index if not exists idx_materials_department on public.materials (department_id);
create index if not exists idx_attempts_user     on public.attempts (user_id);
create index if not exists idx_attempts_paper    on public.attempts (paper_id);