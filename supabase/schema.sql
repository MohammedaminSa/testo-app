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

-- ============================================================================
-- Quiz engine RPCs (server-side grading)
-- `get_quizzes` returns questions WITHOUT the correct answer so answers can
-- never be read from the API. `grade_attempt` grades a submission server-side
-- against the real options, persists the attempt, and returns the graded
-- result for the review screen.
-- ============================================================================

create or replace function public.get_quizzes()
returns jsonb
language sql
stable
security definer set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', q.id,
        'title', q.title,
        'description', q.description,
        'category', q.category,
        'difficulty', q.difficulty,
        'tags', q.tags,
        'time_limit_seconds', q.time_limit_seconds,
        'paper_size', q.paper_size,
        'questions', (
          select coalesce(
            jsonb_agg(
              jsonb_build_object(
                'id', qq.id,
                'position', qq.position,
                'text', qq.text,
                'explanation', qq.explanation,
                'topic', qq.topic,
                'options', (
                  select coalesce(
                    jsonb_agg(
                      jsonb_build_object(
                        'position', o.position,
                        'text', o.text
                      ) order by o.position
                    ), '[]'::jsonb
                  )
                  from public.options o
                  where o.question_id = qq.id
                )
              ) order by qq.position
            ), '[]'::jsonb
          )
          from public.questions qq
          where qq.quiz_id = q.id
        )
      ) order by q.id
    ), '[]'::jsonb
  )
  from public.quizzes q;
$$;

create or replace function public.grade_attempt(
  p_quiz_id text,
  p_answers jsonb
)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_quiz_title text;
  v_graded jsonb;
  v_questions_order jsonb;
  v_total integer;
  v_correct integer;
  v_score numeric(5,2);
  v_attempt_id uuid;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select q.title into v_quiz_title
    from public.quizzes q
    where q.id = p_quiz_id;

  if v_quiz_title is null then
    raise exception 'Quiz not found';
  end if;

  -- Every submitted answer must reference a question in this quiz.
  if (select count(*) from jsonb_array_elements(p_answers) a
      left join public.questions qu
        on qu.id = a->>'question_id' and qu.quiz_id = p_quiz_id
      where qu.id is null) > 0 then
    raise exception 'Invalid answer set';
  end if;

  v_total := jsonb_array_length(p_answers);

  select
    coalesce(jsonb_agg(graded order by t.ord), '[]'::jsonb),
    coalesce(jsonb_agg(t.a->>'question_id' order by t.ord), '[]'::jsonb)
  into v_graded, v_questions_order
  from jsonb_array_elements(p_answers) with ordinality as t(a, ord)
  left join lateral (
    select
      qu.id as question_id,
      qu.text as question_text,
      qu.topic,
      (t.a->>'selected_index')::int as selected_index,
      (o_correct.position - 1)::int as correct_index,
      (
        select o.text
        from public.options o
        where o.question_id = qu.id
          and o.position = ((t.a->>'selected_index')::int + 1)
      ) as selected_text,
      o_correct.text as correct_text,
      ((t.a->>'selected_index')::int = (o_correct.position - 1)) as is_correct,
      qu.explanation
    from public.questions qu
    join public.options o_correct
      on o_correct.question_id = qu.id and o_correct.is_correct
    where qu.id = t.a->>'question_id'
      and qu.quiz_id = p_quiz_id
    limit 1
  ) graded on true;

  select count(*) into v_correct
  from jsonb_array_elements(v_graded) g
  where (g->>'is_correct')::boolean;

  v_score := case
    when v_total = 0 then 0
    else round((v_correct::numeric / v_total * 100)::numeric, 2)
  end;

  insert into public.quiz_attempts (
    user_id, quiz_id, quiz_title, total_questions, correct_answers,
    score_percent, questions_order, answers
  )
  values (
    v_user_id, p_quiz_id, v_quiz_title, v_total, v_correct,
    v_score, v_questions_order, v_graded
  )
  returning id into v_attempt_id;

  return jsonb_build_object(
    'attempt_id', v_attempt_id,
    'quiz_id', p_quiz_id,
    'quiz_title', v_quiz_title,
    'total_questions', v_total,
    'correct_answers', v_correct,
    'score_percent', v_score,
    'questions_order', v_questions_order,
    'answers', v_graded
  );
end;
$$;

revoke execute on function public.get_quizzes() from public;
grant execute on function public.get_quizzes() to authenticated;
revoke execute on function public.grade_attempt(text, jsonb) from public;
grant execute on function public.grade_attempt(text, jsonb) to authenticated;
