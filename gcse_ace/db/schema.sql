-- SUPABASE schema for GCSE Ace.
-- Run once in the Supabase SQL editor or via Supabase CLI migrations.
-- Order matters: parents before children.

-- =====================================================================
-- 1) PROFILES - one row per student
-- =====================================================================
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  username    text,
  full_name   text not null,
  role        text not null default 'student',
  created_at  timestamptz not null default now()
);

alter table public.profiles add column if not exists username text;

-- Auto-create a profile row when a new user signs up in auth.users
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  raw_username text;
  raw_fullname text;
begin
  raw_username := coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1));
  raw_fullname := coalesce(new.raw_user_meta_data->>'full_name', raw_username, 'Student');

  insert into public.profiles (id, username, full_name, role)
  values (
    new.id,
    raw_username,
    raw_fullname,
    'student'
  )
  on conflict (id) do update set
    username = excluded.username,
    full_name = excluded.full_name;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

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
-- 2b) COURSES - subject courses/modules under a department
-- =====================================================================
create table if not exists public.courses (
  id            uuid primary key default gen_random_uuid(),
  department_id uuid not null references public.departments (id) on delete cascade,
  name          text not null,
  code          text,
  description   text,
  created_at    timestamptz not null default now(),
  unique (department_id, name)
);

-- =====================================================================
-- 3) PAPERS - an exam or a past paper, belongs to one department and course
-- =====================================================================
create table if not exists public.papers (
  id               uuid primary key default gen_random_uuid(),
  department_id    uuid not null references public.departments (id) on delete cascade,
  course_id        uuid references public.courses (id) on delete set null,
  course_name      text,
  exam_type        text not null default 'mock' check (exam_type in ('mock', 'exit_exam')),
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
  course_id     uuid references public.courses (id) on delete set null,
  course_name   text,
  title         text not null,
  content       text not null,
  url           text,
  created_at    timestamptz not null default now()
);

alter table public.materials add column if not exists course_id uuid references public.courses (id) on delete set null;
alter table public.materials add column if not exists course_name text;

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
-- 8) CHAT MESSAGES - the AI tutor conversation, one row per message
-- =====================================================================
create table if not exists public.chat_messages (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  role       text not null check (role in ('user', 'assistant')),
  content    text not null,
  created_at timestamptz not null default now()
);

alter table public.chat_messages enable row level security;

drop policy if exists "Users can view own chat messages" on public.chat_messages;
create policy "Users can view own chat messages"
  on public.chat_messages for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own chat messages" on public.chat_messages;
create policy "Users can insert own chat messages"
  on public.chat_messages for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own chat messages" on public.chat_messages;
create policy "Users can delete own chat messages"
  on public.chat_messages for delete
  using (auth.uid() = user_id);

-- =====================================================================
-- 9) ROW-LEVEL SECURITY
-- =====================================================================

-- Helper: true when the signed-in user's profile role is 'admin'.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- Profiles: users can read their own row; admins can read all
alter table public.profiles enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id or public.is_admin());

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (
    auth.uid() = id and (
      public.is_admin() or role = (select p.role from public.profiles p where p.id = auth.uid())
    )
  );

-- Departments
alter table public.departments enable row level security;

drop policy if exists "Anyone can view departments" on public.departments;
create policy "Anyone can view departments"
  on public.departments for select
  to authenticated
  using (true);

drop policy if exists "Admins can insert departments" on public.departments;
create policy "Admins can insert departments"
  on public.departments for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "Admins can update departments" on public.departments;
create policy "Admins can update departments"
  on public.departments for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Admins can delete departments" on public.departments;
create policy "Admins can delete departments"
  on public.departments for delete
  to authenticated
  using (public.is_admin());

-- Courses
alter table public.courses enable row level security;

drop policy if exists "Anyone can view courses" on public.courses;
create policy "Anyone can view courses"
  on public.courses for select
  to authenticated
  using (true);

drop policy if exists "Admins can insert courses" on public.courses;
create policy "Admins can insert courses"
  on public.courses for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "Admins can update courses" on public.courses;
create policy "Admins can update courses"
  on public.courses for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Admins can delete courses" on public.courses;
create policy "Admins can delete courses"
  on public.courses for delete
  to authenticated
  using (public.is_admin());

-- Papers
alter table public.papers enable row level security;

drop policy if exists "Anyone can view papers" on public.papers;
create policy "Anyone can view papers"
  on public.papers for select
  to authenticated
  using (true);

drop policy if exists "Admins can insert papers" on public.papers;
create policy "Admins can insert papers"
  on public.papers for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "Admins can update papers" on public.papers;
create policy "Admins can update papers"
  on public.papers for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Admins can delete papers" on public.papers;
create policy "Admins can delete papers"
  on public.papers for delete
  to authenticated
  using (public.is_admin());

-- Questions
alter table public.questions enable row level security;

drop policy if exists "Anyone can view questions" on public.questions;
create policy "Anyone can view questions"
  on public.questions for select
  to authenticated
  using (true);

drop policy if exists "Admins can insert questions" on public.questions;
create policy "Admins can insert questions"
  on public.questions for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "Admins can update questions" on public.questions;
create policy "Admins can update questions"
  on public.questions for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Admins can delete questions" on public.questions;
create policy "Admins can delete questions"
  on public.questions for delete
  to authenticated
  using (public.is_admin());

-- Options
alter table public.options enable row level security;

drop policy if exists "Anyone can view options" on public.options;
create policy "Anyone can view options"
  on public.options for select
  to authenticated
  using (true);

drop policy if exists "Admins can insert options" on public.options;
create policy "Admins can insert options"
  on public.options for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "Admins can update options" on public.options;
create policy "Admins can update options"
  on public.options for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Admins can delete options" on public.options;
create policy "Admins can delete options"
  on public.options for delete
  to authenticated
  using (public.is_admin());

-- Materials
alter table public.materials enable row level security;

drop policy if exists "Anyone can view materials" on public.materials;
create policy "Anyone can view materials"
  on public.materials for select
  to authenticated
  using (true);

drop policy if exists "Admins can insert materials" on public.materials;
create policy "Admins can insert materials"
  on public.materials for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "Admins can update materials" on public.materials;
create policy "Admins can update materials"
  on public.materials for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Admins can delete materials" on public.materials;
create policy "Admins can delete materials"
  on public.materials for delete
  to authenticated
  using (public.is_admin());

-- Attempts: students read/write their own rows
alter table public.attempts enable row level security;

drop policy if exists "Users can view own attempts" on public.attempts;
create policy "Users can view own attempts"
  on public.attempts for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own attempts" on public.attempts;
create policy "Users can insert own attempts"
  on public.attempts for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own attempts" on public.attempts;
create policy "Users can update own attempts"
  on public.attempts for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =====================================================================
-- Convenient indexes for the queries we'll write later
-- =====================================================================
create index if not exists idx_courses_department on public.courses (department_id);
create index if not exists idx_papers_department on public.papers (department_id);
create index if not exists idx_papers_course     on public.papers (course_id);
create index if not exists idx_papers_exam_type  on public.papers (exam_type);
create index if not exists idx_questions_paper   on public.questions (paper_id);
create index if not exists idx_options_question  on public.options (question_id);
create index if not exists idx_materials_department on public.materials (department_id);
create index if not exists idx_materials_course     on public.materials (course_id);
create index if not exists idx_attempts_user     on public.attempts (user_id);
create index if not exists idx_attempts_paper    on public.attempts (paper_id);
create index if not exists idx_chat_messages_user on public.chat_messages (user_id, created_at);

-- =====================================================================
-- 10) STORAGE BUCKET FOR READING MATERIAL PDFS
-- =====================================================================
insert into storage.buckets (id, name, public)
values ('materials', 'materials', true)
on conflict (id) do nothing;

drop policy if exists "Public view access for materials bucket" on storage.objects;
create policy "Public view access for materials bucket"
  on storage.objects for select
  using (bucket_id = 'materials');

drop policy if exists "Authenticated users can upload material pdfs" on storage.objects;
create policy "Authenticated users can upload material pdfs"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'materials');

drop policy if exists "Authenticated users can update material pdfs" on storage.objects;
create policy "Authenticated users can update material pdfs"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'materials');

drop policy if exists "Authenticated users can delete material pdfs" on storage.objects;
create policy "Authenticated users can delete material pdfs"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'materials');
