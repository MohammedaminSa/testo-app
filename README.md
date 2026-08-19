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
5. Provide your project URL and anon key when running. Copy
   `env.example.json` to `env.json`, fill in your values, and run:

```bash
flutter run --dart-define-from-file=env.json
```

or pass the values inline:

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY
```

`env.json` is gitignored. Without the dart-defines the app falls back to the
bundled demo quizzes so it still runs locally.

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
- Email verification + "forgot password" reset flow (with deep-link support)
- Google and Apple OAuth sign-in buttons
- User profiles: `profiles` table auto-created on signup, editable display name
- Multiple-choice quiz engine with instant feedback (demo quizzes) or
  server-graded reviews (server quizzes)
- **Server-side grading**: questions are fetched without their answers
  (`get_quizzes`) and attempts are graded by the `grade_attempt` RPC — the
  correct answers never leave the backend
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
- Branded launcher icons + launch screen; privacy policy + terms linked from
  the in-app profile screen

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

## Release build

### Android

```bash
flutter build apk --release
# or the split App Bundle for Play Store review:
flutter build appbundle --release
```

Release signing reads `android/key.properties` (gitignored). To set it up:

```bash
keytool -genkeypair -v -keystore android/app/upload-keystore.jks \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

then create `android/key.properties`:

```properties
storePassword=<your store password>
keyPassword=<your key password>
keyAlias=upload
storeFile=upload-keystore.jks
```

**Back up the keystore and keep its passwords secret** — it is required to
sign every future update to the same app. Without `key.properties` the build
falls back to debug signing (fine for local testing, not for the store).

### iOS

An iOS build needs **macOS** (Xcode + signing), so it can't be produced on
Windows. The asset catalog (`ios/Runner/Assets.xcassets/AppIcon.appiconset`),
URL scheme, and app display name are already wired up — on a Mac, run:

```bash
flutter build ios --release
```

## Release smoke-test checklist

Run through this before every release build:

1. **Fresh install** — install the APK/build on a clean device or emulator;
   first launch shows the launch screen, then Home (or Auth when signed out).
2. **Auth** — sign up with a throwaway email, confirm the verification link,
   sign out, sign in. Forgot password sends a reset email; the link opens the
   app again (deep link).
3. **Demo mode** — run with no dart-defines; demo quizzes are shown, answers
   are revealed immediately after answering, finishing shows the review.
4. **Server mode** — run against the real project; catalog loads from the
   cache then refreshes; answers are **not** revealed during the quiz; tapping
   Finish grades via `grade_attempt` and shows the review + updates history.
5. **Grading failure** — with airplane mode on, finish a server quiz; an
   error snackbar appears and Finish works again for retry.
6. **Timed quiz** — set a short `time_limit_seconds` in the DB; the countdown
   shows, warns under 5s, and auto-submits on timeout ("No answer (time up)").
7. **Resume** — start a quiz, kill the app, reopen it; the Resume / Start
   over dialog appears and Resume restores your place.
8. **Offline catalog** — load the catalog once, go offline, restart; quizzes
   still appear from cache.
9. **History & profile** — after a quiz, History shows the attempt; Profile
   updates the display name and opens the privacy policy / terms links.
10. **Analytics/crash** — with `POSTHOG_API_KEY`/`SENTRY_DSN` set, verify
    events and a forced error appear in PostHog/Sentry.
11. **Clean slate** — sign out, take one demo quiz, then reinstall to confirm
    no leftover local state breaks a fresh run.
12. **App icon & name** — the launcher shows the branded icon and the "Testo"
    label on Android and iOS.
