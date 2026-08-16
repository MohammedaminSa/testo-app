# Testo — Phase Roadmap

The full plan to take Testo from a working demo to a real, shippable app.
Each phase has: **goal → tasks → why it matters**. Check items off as you go.

```text
PHASE 1  Backend & data        ✅ DONE
PHASE 2  Auth & onboarding     ✅ DONE
PHASE 3  Quiz engine          ✅ DONE
PHASE 4  Architecture         ◻ NEXT
PHASE 5  Quality & testing    ◻
PHASE 6  Shipping             ◻
```

---

## Phase 1 — Backend & data ✅ DONE

**Goal:** quiz content lives in the database instead of being hardcoded in Dart.

### Done
- [x] `supabase/schema.sql` — added `quizzes`, `questions`, `options` tables
- [x] `supabase/seed.sql` — seeded the two sample quizzes
- [x] `lib/services/quiz_service.dart` — fetches quizzes + questions + options in one query
- [x] `lib/models/models.dart` — `fromMap` factories for `Question` / `Quiz`
- [x] `lib/screens/home_screen.dart` — loads quizzes from cloud, error/retry card, demo fallback when unconfigured

### Files touched
`supabase/schema.sql`, `supabase/seed.sql`, `lib/services/quiz_service.dart`,
`lib/models/models.dart`, `lib/screens/home_screen.dart`, `README.md`

### Known catch (fix in a later phase)
`is_correct` is currently sent to the client — a hacker could read answers from the API before taking a quiz.
Fix later with a Postgres function that returns questions **without** the correct answer, and grade server-side.

---

## Phase 2 — Auth & onboarding ✅ DONE

**Goal:** users can sign up/in/professionally and have a profile.

### Done
- [x] Email confirmation flow (verify account before use)
- [x] Forgot/reset password screen
- [x] `profiles` table tied to `auth.users` (name, avatar, preferences)
  - `supabase/schema.sql` now creates `public.profiles` with an
    `on_auth_user_created` trigger that inserts a row on signup.
- [x] Google / Apple OAuth button
- [x] Splash/loading state while checking session (instead of flashing AuthScreen)
  - `SessionGate` in `lib/main.dart` reads the persisted session synchronously.
- [x] Form polish: confirm-password field, "already registered?" hints, name on signup

### Files touched
`supabase/schema.sql`, `lib/main.dart`, `lib/screens/auth_screen.dart`,
`lib/screens/forgot_password_screen.dart`, `lib/screens/profile_screen.dart`,
`lib/screens/splash_screen.dart`, `lib/services/profile_service.dart`,
`lib/models/models.dart`, `lib/screens/home_screen.dart`, `README.md`

### Follow-ups (later phases)
- Password-reset **deep link handling** needs the platform URL scheme wired up
  (see README) to let the reset email reopen the app directly.
- OAuth buttons need the provider client IDs configured per platform.

---

## Phase 3 — Quiz engine ✅ DONE

**Goal:** quizzes feel like real exam prep, not a fixed linear list.

### Done
- [x] **Randomize** question order per attempt — each attempt builds a shuffled
  "paper"; the order + every answer is stored on the attempt (`questions_order`,
  `answers` jsonb) so results are fair and reviewable.
- [x] **Timed mode** — optional per-question countdown (from
  `quizzes.time_limit_seconds`), red warning under 5s, auto-submit on timeout
  (records "no answer").
- [x] **Review screen** — after a quiz the app shows a full breakdown: score,
  each question, your answer vs the correct one, and the explanation
  (`lib/screens/review_screen.dart`).
- [x] **Weak-area tracking** — each question's `topic` + correctness is recorded;
  review screen and home stats card both surface "Topics to review".
- [x] Question banks + fixed-length papers — `quizzes.paper_size` lets a bank
  serve a random N-question paper from a larger pool.
- [x] **Resume an unfinished quiz** — in-progress papers persist locally via
  `shared_preferences` (`lib/services/quiz_storage.dart`); reopening offers
  Resume / Start over.
- [x] Content metadata in DB — `category`, `difficulty`, `tags` on quizzes +
  difficulty filter chips and metadata badges on the home screen.

### Files touched
`supabase/schema.sql`, `supabase/seed.sql`, `lib/models/models.dart`,
`lib/services/quiz_storage.dart` (new), `lib/services/progress_service.dart`,
`lib/screens/quiz_screen.dart`, `lib/screens/review_screen.dart` (new),
`lib/screens/home_screen.dart`, `lib/data/demo_quizzes.dart`,
`test/models_test.dart` (new), `pubspec.yaml`, `README.md`

### Follow-ups (later phases)
- Server-side grading: questions are still fetched with `is_correct`; move
  grading into a Postgres function so answers can't be read from the API.
- Resume persistence uses `shared_preferences`; Phase 4's offline cache (hive)
  can absorb this and add "current attempt" to the home screen.

---

## Phase 4 — Architecture & state management ◻

**Goal:** replace the fragile "every screen manages its own `setState`" pattern.

### Tasks
- [ ] Introduce **Riverpod** (recommended) or **Bloc**
- [ ] Move auth + quiz + progress state into providers/repositories
- [ ] `go_router` for navigation with **auth guards** (redirect to login when signed out)
- [ ] Central error handling + load states (no scattered `catch (_)` in screens)
- [ ] Offline support: cache quizzes with `hive` or Supabase's built-in offline
- [ ] DI/bin the global `supabase` getter behind a small repository layer

### Why
More screens + features will make per-screen state unmaintainable. This phase
keeps the app sane as it grows. Do it **before** adding many new features.

---

## Phase 5 — Quality & testing ◻

**Goal:** the app is verifiably correct and safe to change.

### Tasks
- [ ] Unit tests: `models` (`fromMap`/`toMap`), service logic (mock Supabase)
- [ ] Widget tests: AuthScreen, QuizScreen (answer flow), HomeScreen states
- [ ] Integration test: sign in → take quiz → see history (using test Supabase)
- [ ] CI in GitHub Actions: `flutter analyze` + `flutter test` on every PR
- [ ] Analytics (Firebase Analytics / PostHog): which quizzes are popular
- [ ] Crash & error reporting (Sentry)

### Why
Currently there's a single placeholder test. Real tests let us add features
without breaking what already works.

---

## Phase 6 — Shipping ◻

**Goal:** a downloadable, store-quality app.

### Tasks
- [ ] Real Supabase project + proper config (.env, no placeholder defaults)
- [ ] App icons, splash screen, branding
- [ ] Android release build (`flutter build apk --release`)
- [ ] iOS: signing, asset catalog, `flutter build ios`
- [ ] Versioning + Play Store / App Store listing
- [ ] Privacy policy + terms (required for store submission)
- [ ] Frequent release build + smoke test checklist before publishing

### Why
The final step that turns working code into something people can actually install.

---

## Suggested order & dependencies

```text
Phase 3 (quiz engine) ──┐
                         ├──► Phase 4 (architecture) ──► Phase 5 (quality) ──► Phase 6 (ship)
Phase 2 (auth) ─────────┘
```

- Phase 2 & 3 are independent — either first.
- Do **Phase 4 before adding more features** past Phase 3, or you'll pay for it with refactoring pain.
- Phase 5 & 6 must come last.

## Quick checklist before each phase

- [ ] Read `CODE_WALKTHROUGH.md` to refresh how the app currently works
- [ ] Create a branch: `git checkout -b phase-N-name`
- [ ] Commit each file separately (like the current repo style)
- [ ] Run `flutter analyze` and `flutter test` — keep them green