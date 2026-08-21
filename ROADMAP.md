# GCSE Ace - Project Roadmap

## What we're building
A Flutter mobile app (Android + iOS) for GCSE students with:
- **Mock exams** - timed, exam-style practice
- **Previous year papers** - real past papers by subject and year
- **Department-based materials** - reading/study notes organized by department (Maths, English, Science...)
- **AI explanations** - a clear explanation for every question you get wrong

## Tech decisions (locked in)
| Layer | Choice |
|-------|--------|
| App | Flutter (Dart) |
| Backend | Supabase (auth, database, edge functions) |
| State management | Riverpod |
| Navigation | go_router |
| AI | Supabase Edge Function calling an AI provider |

## The database (conceptual - designed together in Phase 3)
```
departments   -> subject areas (Maths, Science, English...)
papers        -> exams & past papers (subject, year, duration, marks)
questions     -> each question in a paper (text, marks, answer, explanation)
options       -> multiple-choice answers for a question
materials     -> study/reading notes tied to a department
profiles      -> student accounts
attempts      -> one student's run of one paper (answers, score, time)
```

## The screens (built in phases below)
1. Sign in / Sign up
2. Home dashboard
3. Browse papers (filter by department/year)
4. Take an exam (timer, questions, submit)
5. Results + review
6. Review with AI explanations
7. Study materials (by department)
8. Profile & progress history

## Build phases (each phase = learn concept -> write code -> verify -> confirm before moving on)

| Phase | What we build | What you'll learn |
|-------|---------------|-------------------|
| 0 | Roadmap & plan | *(current phase)* |
| 1 | Fresh Flutter project | Understand the folder structure, `pubspec.yaml`, generated files - no app code yet, we only *look* and understand |
| 2 | App skeleton | Theme, colors, first screen, app shell with bottom navigation |
| 3 | Database schema | Design tables in Supabase + SQL, then apply it |
| 4 | Auth | Sign up, sign in, logout, session handling, auth-guarded routing |
| 5 | Data layer | Riverpod providers + fetching papers/questions from Supabase |
| 6 | Browse & paper detail | List departments/papers, view paper info, start an exam |
| 7 | Exam engine | Question flow, timer, auto-submit, local grading |
| 8 | Results & review | Score screen, review every answer |
| 9 | AI explanations | Supabase Edge Function that generates explanations |
| 10 | Study materials | Department-based reading content |
| 11 | Progress tracking | Attempt history, stats on profile |
| 12 | Polish & ship | Loading/error states, app icon, testing, release build |

## How each phase works
1. I explain the concept in plain language
2. We write the code together file by file - you read each file with me
3. We run `flutter analyze` + run the app to verify
4. You ask questions until it clicks
5. We move on

## Backup
The old app is preserved on the git branch `backup-testo`:
```
git checkout backup-testo
```