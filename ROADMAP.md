# Testo — Phase Roadmap

The full plan to take Testo from a working demo to a real, shippable app.
Each phase has: **goal → tasks → why it matters**. Check items off as you go.

```text
PHASE 1  Backend & data        ✅ DONE
PHASE 2  Auth & onboarding     ✅ DONE
PHASE 3  Quiz engine          ✅ DONE
PHASE 4  Architecture         ✅ DONE
PHASE 5  Quality & testing    ✅ DONE
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

## Phase 4 — Architecture & state management ✅ DONE

**Goal:** replace the fragile "every screen manages its own `setState`" pattern.

### Done
- [x] **Riverpod** introduced for all state (auth, quiz catalog, progress, profile).
- [x] **Repositories** (`lib/repositories/`) own every Supabase call — auth, quiz,
  progress, profile. Screens never touch the database.
- [x] **`go_router`** with **auth guards**: `lib/core/router.dart` redirects
  signed-out users to `/auth` and signed-in users away from it, reacting live
  to the auth stream. `/quiz` + `/review` pass objects via `extra`.
- [x] **Central error handling + load states**: one `MessageHost` renders all
  snackbars from a single `messageControllerProvider`; screens draw
  loading/error/data straight from `AsyncValue` instead of scattered
  `catch (_)` + booleans.
- [x] **Offline support**: `QuizCache` (`lib/services/quiz_cache.dart`) persists
  the catalog; `QuizListNotifier` shows the cache instantly, refreshes in the
  background, and falls back to it when offline.
- [x] **DI**: the global `supabase` getter is now only touched by
  `supabaseProvider`; every repository receives its client through it.
- [x] `Quiz`/`Question` gained `toMap()` so cached data round-trips.

### Files touched
`pubspec.yaml`, `lib/main.dart`, `lib/core/router.dart` (new),
`lib/repositories/{auth,quiz,progress,profile}_repository.dart` (new),
`lib/providers/{supabase,auth,quiz,progress,profile}_providers.dart` (new),
`lib/providers/message_controller.dart` (new),
`lib/services/quiz_cache.dart` (new),
`lib/screens/{auth,forgot_password,home,quiz,history,profile,review}_screen.dart`,
`lib/models/models.dart`, `test/repositories_test.dart` (new)
Deleted: `lib/services/{quiz,progress,profile}_service.dart`,
`lib/screens/splash_screen.dart`

### Follow-ups (later phases)
- `CODE_WALKTHROUGH.md` still describes the pre-Phase-4 `setState`/`SessionGate`
  architecture — rewrite it in the next docs pass.
- `QuizCache` deliberately uses `shared_preferences` (small catalog, already a
  dependency, test-friendly). Swap to `hive` when the catalog grows, and fold
  resume storage (`quiz_storage.dart`) into the same cache.
- Server-side grading (Phase 1 follow-up) is still open.

---

## Phase 5 — Quality & testing ✅ DONE

**Goal:** the app is verifiably correct and safe to change.

### Done
- [x] **Unit tests**: `QuizCache` round-trip (mock shared_preferences) and
  `QuizListNotifier` — demo fallback, repository fetch + cache write, and
  offline-cache fallback when the network fails
  (`test/quiz_cache_test.dart`, `test/quiz_list_notifier_test.dart`).
- [x] **Widget tests** with fake repositories (`test/helpers/fakes.dart`):
  - `AuthScreen`: empty-form validation, successful sign-in, failure snackbar
  - `QuizScreen`: answer → explanation → finish saves the attempt + navigates
    to review (100% and 0% score paths)
  - `HomeScreen`: quiz cards + stats, loading spinner, error + retry, tap→quiz
- [x] **Integration test**: sign in → take a quiz → see it in history against a
  real test Supabase project (`integration_test/app_test.dart`). Not run by
  `flutter test`; runs on a device with `SUPABASE_URL`/`ANON_KEY`/
  `TEST_EMAIL`/`TEST_PASSWORD` dart-defines.
- [x] **CI in GitHub Actions**: `.github/workflows/ci.yml` runs
  `flutter analyze` + `flutter test` on every push/PR.
- [x] **Analytics (PostHog)** behind a dart-define (`POSTHOG_API_KEY`):
  `AnalyticsService` (`lib/services/analytics_service.dart`) tracks
  `sign_in`, `sign_up`, `quiz_started`, `quiz_completed`; no-op when
  unconfigured.
- [x] **Crash & error reporting (Sentry)** behind a dart-define (`SENTRY_DSN`):
  `initCrashReporting()` in `lib/services/crash_reporter.dart`.

### Files touched
`pubspec.yaml`, `.github/workflows/ci.yml` (new),
`integration_test/app_test.dart` (new),
`test/helpers/fakes.dart` (new),
`test/{auth_screen,quiz_screen,home_screen}_test.dart` (new),
`test/{quiz_cache,quiz_list_notifier}_test.dart` (new),
`lib/core/config.dart`, `lib/main.dart`,
`lib/providers/{quiz,observability}_providers.dart`,
`lib/services/{analytics_service,crash_reporter}.dart` (new),
`lib/screens/{auth,quiz}_screen.dart`, `ROADMAP.md`

### Follow-ups (later phases)
- `CODE_WALKTHROUGH.md` still describes the pre-Phase-4 `setState`/`SessionGate`
  architecture — rewrite it in the next docs pass.
- Server-side grading (Phase 1/3 follow-up) is still open: questions are still
  fetched with `is_correct`.
- Widget tests use fake repositories; an interface (abstract class) per
  repository would let tests avoid constructing `SupabaseClient` at all.
- CI only runs `flutter test`; the integration test needs a real test Supabase
  project before it can join CI.

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