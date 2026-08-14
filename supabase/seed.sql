-- Testo - seed quiz content
-- Run this in the Supabase SQL editor AFTER schema.sql.

insert into public.quizzes (id, title, description) values
  ('flutter_basics', 'Flutter Basics', 'Core Flutter & Dart concepts for beginners.'),
  ('interview_prep', 'Interview Prep', 'Common software engineering interview questions.')
on conflict (id) do nothing;

insert into public.questions (id, quiz_id, position, text, explanation) values
  ('00000000-0000-0000-0000-000000000001', 'flutter_basics', 1,
   'What language is Flutter built with?',
   'Flutter uses Dart, a client-optimized language developed by Google.'),
  ('00000000-0000-0000-0000-000000000002', 'flutter_basics', 2,
   'What widget is the root of every Flutter app?',
   'MaterialApp (or CupertinoApp) is the root widget that configures theme, routes, and more.'),
  ('00000000-0000-0000-0000-000000000003', 'flutter_basics', 3,
   'Which widget provides the basic app structure with an AppBar?',
   'Scaffold gives the app a visual structure including AppBar, body, and FAB.'),
  ('00000000-0000-0000-0000-000000000004', 'flutter_basics', 4,
   'StatefulWidget is used when...',
   'StatefulWidget allows mutable state that triggers rebuilds via setState().'),
  ('00000000-0000-0000-0000-000000000005', 'interview_prep', 1,
   'What is the time complexity of binary search?',
   'Binary search halves the search space each step, giving O(log n).'),
  ('00000000-0000-0000-0000-000000000006', 'interview_prep', 2,
   'Which data structure operates FIFO?',
   'A Queue is First-In, First-Out; a Stack is LIFO.'),
  ('00000000-0000-0000-0000-000000000007', 'interview_prep', 3,
   'What does SOLID refer to?',
   'SOLID is a set of five object-oriented design principles.')
on conflict (id) do nothing;

insert into public.options (question_id, position, text, is_correct) values
  ('00000000-0000-0000-0000-000000000001', 1, 'JavaScript', false),
  ('00000000-0000-0000-0000-000000000001', 2, 'Dart', true),
  ('00000000-0000-0000-0000-000000000001', 3, 'Kotlin', false),
  ('00000000-0000-0000-0000-000000000001', 4, 'Swift', false),

  ('00000000-0000-0000-0000-000000000002', 1, 'Container', false),
  ('00000000-0000-0000-0000-000000000002', 2, 'Scaffold', false),
  ('00000000-0000-0000-0000-000000000002', 3, 'MaterialApp', true),
  ('00000000-0000-0000-0000-000000000002', 4, 'Center', false),

  ('00000000-0000-0000-0000-000000000003', 1, 'Row', false),
  ('00000000-0000-0000-0000-000000000003', 2, 'Scaffold', true),
  ('00000000-0000-0000-0000-000000000003', 3, 'Column', false),
  ('00000000-0000-0000-0000-000000000003', 4, 'Stack', false),

  ('00000000-0000-0000-0000-000000000004', 1, 'The UI is static', false),
  ('00000000-0000-0000-0000-000000000004', 2, 'Widget state can change over time', true),
  ('00000000-0000-0000-0000-000000000004', 3, 'You need a layout', false),
  ('00000000-0000-0000-0000-000000000004', 4, 'You are testing', false),

  ('00000000-0000-0000-0000-000000000005', 1, 'O(n)', false),
  ('00000000-0000-0000-0000-000000000005', 2, 'O(log n)', true),
  ('00000000-0000-0000-0000-000000000005', 3, 'O(n log n)', false),
  ('00000000-0000-0000-0000-000000000005', 4, 'O(1)', false),

  ('00000000-0000-0000-0000-000000000006', 1, 'Stack', false),
  ('00000000-0000-0000-0000-000000000006', 2, 'Queue', true),
  ('00000000-0000-0000-0000-000000000006', 3, 'Tree', false),
  ('00000000-0000-0000-0000-000000000006', 4, 'Graph', false),

  ('00000000-0000-0000-0000-000000000007', 1, 'A database standard', false),
  ('00000000-0000-0000-0000-000000000007', 2, 'Five design principles', true),
  ('00000000-0000-0000-0000-000000000007', 3, 'A testing framework', false),
  ('00000000-0000-0000-0000-000000000007', 4, 'A network protocol', false)
on conflict (question_id, position) do nothing;