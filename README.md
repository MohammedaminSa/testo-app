  Testo App

**Learn. Practice. Pass.**

A mobile app that helps users prepare for exams and interviews through quizzes, mock exams, and (upcoming) AI-powered explanations.

## Tech Stack

- Frontend: Flutter (Dart)
- APIs: Supabase (auth + database)
- State management: Riverpod
- Navigation: go_router (auth guards)
- Offline: shared_preferences (quiz cache + resume persistence)

## Setup

1. **Create a Supabase project** at https://supabase.com
2. Run `supabase/schema.sql` in the Supabase SQL editor
3. Run `supabase/seed.sql` to load the quiz content
4. In **Authentication → Providers**, enable the providers you want (Email is
   required; Google/Apple are optional and need their own client IDs).
5. Provide your project URL and anon key when running:

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY
```

Without the dart-defines the app falls back to the bundled demo quizzes so it still runs locally.

### Email confirmation & password reset

- Signing up with email confirmation **enabled** (default) sends a verification
  link; the app shows a "check your inbox" message until the account is verified.
- The "Forgot password?" flow uses Supabase's email link. For the reset link to
  open the app, configure your deep-link scheme (see below) and add it to
  **Authentication → URL Configuration → Redirect URLs**, e.g.
  `io.supabase.flutter://login-callback/`.

### Google / Apple sign-in

- The OAuth buttons open the provider's browser flow. To return to the app, set
  up deep linking for your platform and add the redirect URL in Supabase:
  - **Android**: add an intent filter for your scheme (see
    `android/app/src/main/AndroidManifest.xml`) and set it in the Supabase
    dashboard.
  - **iOS**: add a URL scheme in `Info.plist`.
  - supabase_flutter's default scheme is `io.supabase.flutter://login-callback/`.

## Features

- Email/password authentication (sign up + sign in, confirm password, name on signup)
- Email verification + "forgot password" reset flow
- Google and Apple OAuth sign-in buttons
- User profiles: `profiles` table auto-created on signup, editable display name
- Multiple-choice quiz engine with instant feedback and explanations
- Randomized question order per attempt (fixed-length papers from question banks)
- Timed mode: per-question countdown with auto-submit
- Post-quiz review screen with explanations and weak-area ("topics to review") tracking
- Resume an unfinished quiz after the app is killed mid-attempt
- Quiz browsing by difficulty/category with metadata badges
- Offline quiz browsing: the catalog is cached and shown when there's no connection
- Auth-guarded routing (signed-out users are redirected to the sign-in screen)
- Quiz content served from Supabase (`quizzes`/`questions`/`options` tables)
- Progress tracking: average/best scores, attempt history
- Server-side persistence of quiz attempts (Supabase, RLS-protected)
- Analytics (PostHog) + crash/error reporting (Sentry) behind dart-defines

## Testing

```bash
flutter analyze
flutter test          # unit + widget tests (no network)
```

The CI workflow (`.github/workflows/ci.yml`) runs both on every push/PR.

The end-to-end flow (sign in → take a quiz → see it in history) lives in
`integration_test/app_test.dart` and needs a dedicated test Supabase project.
It is not part of `flutter test`; run it on a device/emulator with:

```bash
flutter test integration_test -d <device> \
  --dart-define=SUPABASE_URL=https://your-test-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key> \
  --dart-define=TEST_EMAIL=<test account email> \
  --dart-define=TEST_PASSWORD=<test account password>
```

### Analytics & crash reporting (optional)

The app ships with PostHog analytics and Sentry crash reporting wired in but
**disabled by default**. Enable them by passing the keys:

```bash
flutter run --dart-define=POSTHOG_API_KEY=<project api key> \
  --dart-define=SENTRY_DSN=<sentry dsn>
```

Without them every analytics/crash call is a silent no-op.
