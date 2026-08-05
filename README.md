# Testo

**Learn. Practice. Pass.**

A mobile app that helps users prepare for exams and interviews through quizzes, mock exams, and (upcoming) AI-powered explanations.

## Tech Stack

- Flutter (Dart)
- Supabase (auth + database)

## Setup

1. **Create a Supabase project** at https://supabase.com
2. Run `supabase/schema.sql` in the Supabase SQL editor
3. Provide your project URL and anon key when running:

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY
```

## Features

- Email/password authentication (sign up + sign in)
- Multiple-choice quiz engine with instant feedback and explanations
- Progress tracking: average/best scores, attempt history
- Server-side persistence of quiz attempts (Supabase, RLS-protected)
