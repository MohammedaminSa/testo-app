# Testo — Code Walkthrough (in execution order)

This guide explains the whole app **in the order the code actually runs**,
from boot to the quiz engine to server-side grading. Written for someone new
to Flutter, but it assumes you've skimmed the phase roadmap (`ROADMAP.md`).

---

## The journey at a glance

```
main() ─────────────────────────────────────────────  lib/main.dart
  │  boot Flutter → init Supabase → init Sentry/PostHog
  └─ ProviderScope + TestoApp ─────────────────────  lib/main.dart
        │  MaterialApp.router + MessageHost (snackbars)
        ├─ routerProvider ──────────────────────────  lib/core/router.dart
        │     auth-guarded go_router; redirects:
        │     signed-out → /auth, signed-in → /
        ├─ signed OUT → AuthScreen ─────────────────  lib/screens/auth_screen.dart
        │     sign in / sign up / forgot password
        └─ signed IN → HomeScreen ──────────────────  lib/screens/home_screen.dart
              ├─ quizListProvider (catalog, offline-cached)
              ├─ statsProvider (progress card)
              ├─ tap quiz → QuizScreen ─────────────  lib/screens/quiz_screen.dart
              │     shuffle a paper, answer questions
              │     → grade_attempt RPC (server quizzes)
              │        or local grading (demo quizzes)
              │     → ReviewScreen ─────────────────  lib/screens/review_screen.dart
              ├─ /history → HistoryScreen ──────────  lib/screens/history_screen.dart
              └─ /profile → ProfileScreen ──────────  lib/screens/profile_screen.dart
```

Every DB call goes through a **repository**, every screen reads state through
a **Riverpod provider**, and data shapes live in `lib/models/models.dart`.

---

## Step 0 — `pubspec.yaml`: the dependency list

The app's "shopping list". The dependencies that matter:

```yaml
dependencies:
  supabase_flutter:     # auth + database client
  flutter_riverpod:     # state management
  go_router:            # routing with auth guards
  shared_preferences:   # offline cache + resume persistence
  posthog_flutter:      # analytics (no-op when unconfigured)
  sentry_flutter:       # crash reporting (no-op when unconfigured)
  url_launcher:         # opens the privacy policy / terms links

dev_dependencies:
  flutter_test, integration_test
  flutter_lints
  image, flutter_launcher_icons   # regenerate app icons (tool/generate_icons.dart)
```

The `flutter_launcher_icons:` block at the bottom tells that tool where the
source icons live (`assets/icon/`) and the adaptive-icon colors.

---

## Step 1 — `lib/main.dart`: boot & entry point

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initSupabase();      // connect to the backend (no-op if unconfigured)
  await initCrashReporting();          // Sentry, if SENTRY_DSN provided
  final analytics = AnalyticsService(); // PostHog, if POSTHOG_API_KEY provided
  await analytics.init();
  runApp(
    ProviderScope(
      overrides: [analyticsProvider.overrideWithValue(analytics)],
      child: const TestoApp(),
    ),
  );
}
```

- `WidgetsFlutterBinding.ensureInitialized()` — makes sure the Flutter engine
  is ready before touching plugins.
- `ProviderScope` wraps the whole app. Every provider below lives inside it;
  the `analyticsProvider` is overridden with the real service instance (DI).
- **Observability is opt-in**: without `SENTRY_DSN` / `POSTHOG_API_KEY`
  dart-defines, both services are silent no-ops (see Step 12).

`TestoApp` is a `ConsumerWidget` (Riverpod's version of `StatelessWidget`):

```dart
class TestoApp extends ConsumerWidget {
  Widget build(context, ref) {
    ref.listen<User?>(currentUserProvider, (_, next) {
      if (next != null) ref.read(analyticsProvider).identify(next.id);
    });
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      routerConfig: router,          // all navigation lives in go_router
      theme: AppTheme.light(),
      builder: (context, child) =>   // one place for every snackbar
          MessageHost(child: child ?? const SizedBox.shrink()),
    );
  }
}
```

- **No auth StreamBuilder anymore.** Auth state is a Riverpod
  `StreamProvider` (`currentUserProvider`) and the router rebuilds when it
  changes. Navigation is centralized in `routerProvider`.
- `MessageHost` (`lib/main.dart`) listens to `messageControllerProvider`. Any
  screen can do `ref.read(messageControllerProvider.notifier).show('...')` and
  the message pops up as a snackbar — screens never touch
  `ScaffoldMessenger` directly.

---

## Step 2 — `lib/core/config.dart`: configuration

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL', defaultValue: 'https://YOUR-PROJECT.supabase.co',
);
static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY', defaultValue: 'YOUR-ANON-KEY',
);
```

Values are passed at build/run time:

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

or, from a JSON file (see `env.example.json`):

```bash
flutter run --dart-define-from-file=env.json
```

- `isConfigured` is `true` only when real keys replaced the placeholders.
- `AppConfig.initSupabase()` calls `Supabase.initialize(...)`.
- `SupabaseClient get supabase => Supabase.instance.client;` is the shortcut
  the repositories use to reach the database.

---

## Step 3 — `lib/core/theme.dart`: look & feel

One `AppTheme.light()` `ThemeData` drives buttons, text fields, and cards. The
brand color:

```dart
static const Color primary = Color(0xFF2563EB); // brand blue
static const Color success = Color(0xFF16A34A); // correct / passed
static const Color error   = Color(0xFFDC2626); // wrong / failed
```

Because every widget uses the theme, changing one color restyles the app. The
same blue is reused in the launcher icon and the adaptive icon background.

---

## Step 4 — Repositories: who owns the database

`lib/repositories/` owns **every** Supabase call. Screens never import the
database client.

- `auth_repository.dart` — sign up/in/out, Google/Apple OAuth,
  `onAuthStateChange` stream, password reset.
- `quiz_repository.dart` — loads the quiz catalog.
- `progress_repository.dart` — grades attempts + reads history.
- `profile_repository.dart` — display name updates.

The key rule: **a repository returns typed Dart objects and never touches the
UI.** Example (current quiz fetching):

```dart
class QuizRepository {
  final SupabaseClient _client;
  const QuizRepository(this._client);

  Future<List<Quiz>> fetchQuizzes() async {
    final data = await _client.rpc('get_quizzes');   // see Step 13
    return (data as List)
        .map((row) => Quiz.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
```

Progress grading (server-side):

```dart
Future<QuizResult> gradeAttempt({
  required String quizId,
  required List<SubmittedAnswer> answers,
}) async {
  final data = await _client.rpc('grade_attempt', params: {
    'p_quiz_id': quizId,
    'p_answers': jsonEncode([for (final a in answers) a.toMap()]),
  });
  return QuizResult.fromMap(data as Map<String, dynamic>);
}
```

---

## Step 5 — Providers: state management (Riverpod)

`lib/providers/` exposes each repository and the state screens watch.

```dart
// one client instance for the whole app
final supabaseProvider = Provider<SupabaseClient>((ref) => supabase);

// repositories are DI'd through it
final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => QuizRepository(ref.watch(supabaseProvider)),
);

// the signed-in user, reactive to auth changes
final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider)
      .onAuthStateChange
      .map((state) => state.session?.user);
});
```

The quiz catalog is an `AsyncNotifier` with an offline cache:

```dart
class QuizListNotifier extends AsyncNotifier<List<Quiz>> {
  Future<List<Quiz>> build() async {
    if (!ref.read(backendConfiguredProvider)) return DemoQuizzes.quizzes;
    final cached = await ref.read(quizCacheProvider).load();
    if (cached != null && cached.isNotEmpty) {
      Future(() => refresh());   // show cache now, refresh silently
      return cached;
    }
    return _fetch(ref.read(quizRepositoryProvider));
  }
  Future<void> refresh() async {
    // fetch from network, save to cache; keep cached data on error
  }
}
```

So the home screen: shows the **cache instantly**, refreshes in the
background, and only shows an error card when there is nothing cached at all.

Attempts and stats:

```dart
final attemptsProvider = FutureProvider<List<QuizAttempt>>((ref) =>
    ref.watch(progressRepositoryProvider).fetchAttempts());

final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final attempts = await ref.watch(attemptsProvider.future);
    return ProgressRepository.computeStats(attempts);
  } catch (_) {
    return ProgressRepository.computeStats(const []); // never hard-fail
  }
});
```

---

## Step 6 — `lib/core/router.dart`: auth-guarded navigation

A single `GoRouter` reacts to auth changes:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final refreshStream = GoRouterRefreshStream(authRepository.onAuthStateChange);
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshStream,
    redirect: (_, state) {
      final loggedIn = authRepository.currentSession != null;
      final location = state.matchedLocation;
      final isPublic = location == '/auth' || location == '/forgot-password';
      if (!loggedIn && !isPublic) return '/auth';
      if (loggedIn && location == '/auth') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      GoRoute(path: '/forgot-password', ...),
      GoRoute(path: '/quiz', builder: (_, state) =>
          QuizScreen(quiz: state.extra! as Quiz)),          // passes the Quiz
      GoRoute(path: '/review', builder: (_, state) {
        final args = state.extra! as ReviewArgs;            // quiz + result
        return ReviewScreen(quiz: args.quiz, result: args.result);
      }),
      GoRoute(path: '/history', ...),
      GoRoute(path: '/profile', ...),
    ],
  );
});
```

- `refreshListenable` rebuilds the router when the auth stream emits, so
  sign-in/out redirects happen instantly.
- `/quiz` and `/review` pass typed objects through `extra` — no URL encoding.
- **Deep links**: the app registers the `io.supabase.flutter` URL scheme
  (Android intent-filter in `AndroidManifest.xml`, iOS `CFBundleURLTypes` in
  `Info.plist`). Supabase auth links (e.g. password reset) reopen the app
  through it; the Supabase client handles the callback.

---

## Step 7 — `lib/models/models.dart`: the data shapes

### `Question` — answers are NOT always known

```dart
class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;          // -1 = unknown (server-graded)
  final String explanation;
  final String topic;

  bool get hasCorrectAnswer =>
      correctIndex >= 0 && correctIndex < options.length;
}
```

- `Question.fromMap` computes `correctIndex` by looking for `is_correct` in
  the options. **Quizzes from the `get_quizzes` RPC omit `is_correct`**, so
  `indexWhere` returns `-1` — the client never sees the answer.
- Demo/bundled quizzes do have `correctIndex`, so
  `hasCorrectAnswer == true` and they're graded locally.
- `toMap()` round-trips a question back into a DB-shaped map so a paper can be
  persisted for resume and rebuilt with `fromMap`.

### `SubmittedAnswer` — what the user picked

```dart
class SubmittedAnswer {
  final String questionId;
  final int? selectedIndex;   // null = no answer (time ran out)
}
```

No correctness attached — the server decides that.

### `QuestionAnswer` / `QuizResult` — the graded result

`QuizResult.fromMap` parses the `grade_attempt` RPC response:

```dart
factory QuizResult.fromMap(Map<String, dynamic> map) => QuizResult(
  correctCount: map['correct_answers'] ?? 0,
  totalQuestions: map['total_questions'] ?? 0,
  scorePercent: (map['score_percent'] as num?)?.toDouble() ?? 0,
  questionsOrder: [...],          // the shuffled question order of this paper
  answers: [...].map(QuestionAnswer.fromMap).toList(),
);
```

`QuestionAnswer` carries both the user's pick and the correct answer + text +
explanation — exactly what the review screen needs. `QuizAttempt` is the
history row (same shape, plus `completedAt`), with `fromMap`/`toMap` for
reading and writing attempt rows.

---

## Step 8 — `lib/screens/home_screen.dart`: the main screen

A `ConsumerStatefulWidget` (it keeps one piece of UI state — the difficulty
filter). Everything else comes from providers:

```dart
final quizzesAsync = ref.watch(quizListProvider); // catalog
ref.watch(statsProvider).when(                     // progress card
  loading: () => spinner, error: (...) => 'Could not load progress.',
  data: _buildStatsContent,
);
```

- Pull-to-refresh calls `quizListProvider.notifier.refresh()` and
  `ref.refresh(attemptsProvider.future)`.
- The stats card shows average/best score, attempt count, and "Topics to
  review" chips (computed in `ProgressRepository.computeStats`).
- Quiz cards render title, description, and badges (difficulty / category /
  tags). Tapping one:

```dart
void _startQuiz(Quiz quiz) => context.push('/quiz', extra: quiz);
```

---

## Step 9 — `lib/screens/quiz_screen.dart`: taking a quiz

State kept in `_QuizScreenState`:

```dart
late List<Question> _paper;    // shuffled paper for this attempt
int _currentIndex = 0;
int? _selectedIndex;
bool _answered = false;
bool _finished = false;
final List<SubmittedAnswer> _answers = [];
Timer? _timer;
int? _timeLimitSeconds;
int? _secondsLeft;
```

### Setup & resume

`_initialize()` first checks `QuizStorage.load(quizId)` (persisted via
shared_preferences). If an unfinished attempt exists the user gets a
**Resume / Start over** dialog. Otherwise `_buildPaper()`:

```dart
final shuffled = [...widget.quiz.questions]..shuffle();
final size = widget.quiz.paperSize ?? shuffled.length;
_paper = shuffled.take(size.clamp(1, shuffled.length)).toList();
```

### Answering

```dart
void _selectOption(int index) {
  if (_answered) return;                 // locked once answered
  setState(() { _selectedIndex = index; _answered = true; });
  _recordAnswer();                       // push a SubmittedAnswer
  _stopTimer();
  _persist();                            // save for resume
}
```

No score is counted here. On a timed quiz a per-question countdown runs; at
zero the question is recorded as "no answer" (`selectedIndex = null`) and the
quiz advances.

### Finishing & grading

```dart
void _finish() {
  if (_finished) return;
  _finished = true;
  _stopTimer();
  QuizStorage.clear(widget.quiz.id);
  _gradeAndComplete();
}

Future<void> _gradeAndComplete() async {
  final questionsOrder = _paper.map((q) => q.id).toList();

  // Demo quizzes know the answers locally → grade on device.
  if (widget.quiz.questions.every((q) => q.hasCorrectAnswer)) {
    _complete(_gradeLocally(questionsOrder));
    return;
  }

  // Server quizzes: submit to grade_attempt — the server is the source
  // of truth and answers never leave it.
  try {
    final result = await ref.read(progressRepositoryProvider)
        .gradeAttempt(quizId: widget.quiz.id, answers: _answers);
    ref.invalidate(attemptsProvider);   // refresh history/stats
    _complete(result);
  } catch (_) {
    ref.read(messageControllerProvider.notifier)
        .show('Could not submit your answers. Check your connection.');
    _finished = false;                  // allow retry
  }
}
```

`_gradeLocally` builds the same `QuizResult` shape using the bundled
`correctIndex` values, so the review screen works identically with or without
a backend.

### UI: no answer leakage

Option tiles are highlighted only when `reveal` is true, which requires
`_question.hasCorrectAnswer` — i.e. **only demo quizzes show green/red
feedback as you go**. Server quizzes show a neutral selection highlight
(primary blue + radio icon) and reveal correctness only on the review screen:

```dart
final reveal = _answered && _question.hasCorrectAnswer;
```

`_complete` fires a `quiz_completed` analytics event and routes to
`/review` with `ReviewArgs(quiz, result)`.

---

## Step 10 — `lib/screens/review_screen.dart`: the breakdown

Stateless — everything it needs comes in via `ReviewArgs`:

- A big score card (pass = `scorePercent >= 50`, green/red).
- "Topics to review" chips (wrong answers grouped by `topic`).
- One card per question: your answer vs the correct one (shown only when
  wrong), plus the explanation.

```dart
_answerLine('Your answer', answer.selectedText, answer.isCorrect);
if (!answer.isCorrect) {
  _answerLine('Correct answer', answer.correctText, true);
}
```

`selectedText`/`correctText` are already filled in by the server for graded
attempts, or by `_gradeLocally` for demo quizzes.

---

## Step 11 — History, Profile & Auth screens

- **`history_screen.dart`** — watches `attemptsProvider`; lists past attempts
  newest first, colored by pass/fail.
- **`profile_screen.dart`** — watches `profileProvider` (display name, email
  verification status), edits the name, signs out, and has a **Legal** section
  that opens `PRIVACY_POLICY.md` / `TERMS_OF_SERVICE.md` in the browser via
  `url_launcher`.
- **`auth_screen.dart`** — email/password sign-in + sign-up (with validation
  and confirm-password) and Google/Apple OAuth buttons.
- **`forgot_password_screen.dart`** — sends the Supabase reset email.

All of these use `ref.read(...repositoryProvider)` and show messages through
`messageControllerProvider`.

---

## Step 12 — Observability: PostHog + Sentry

`lib/services/analytics_service.dart` and `crash_reporter.dart` wrap PostHog
and Sentry behind `AppConfig.analyticsConfigured` /
`crashReportingConfigured`. When the dart-defines are absent every call is a
no-op, so local dev sends nothing. Key events: `sign_in`, `sign_up`,
`quiz_started`, `quiz_completed` (with score). The analytics instance is
injected into the app via the `analyticsProvider` override in `main.dart`.

---

## Step 13 — The database side: server-side grading

`supabase/schema.sql` defines tables (`quizzes`, `questions`, `options`,
`quiz_attempts`, `profiles`) with **row-level security**: content is readable
by signed-in users; attempts are only readable/writable by their owner. The
`handle_new_user` trigger creates a profile row on signup.

The two functions that make cheating impractical:

```sql
-- Returns the catalog WITHOUT is_correct (correctIndex becomes -1).
create or replace function public.get_quizzes()
returns jsonb language sql security definer set search_path = public ...

-- Grades a submission against the real options, stores the attempt,
-- and returns score + per-question correctness for the review screen.
create or replace function public.grade_attempt(
  p_quiz_id text, p_answers jsonb
) returns jsonb language plpgsql security definer set search_path = public ...

revoke execute on function public.get_quizzes() from public;
grant execute on function public.get_quizzes() to authenticated;
revoke execute on function public.grade_attempt(text, jsonb) from public;
grant execute on function public.grade_attempt(text, jsonb) to authenticated;
```

`security definer` lets the functions bypass RLS to look up `is_correct`
internally, while `revoke/grant execute` ensures only signed-in users can call
them. `supabase/seed.sql` loads the sample quiz content.

The SQL functions are the only untested-by-CI part (no database in CI); run
them once in the Supabase SQL editor, then `flutter run` against the project.

---

## Step 14 — Offline: cache + resume

- `lib/services/quiz_cache.dart` — persists the fetched catalog in
  `shared_preferences`; `QuizListNotifier` uses it for instant + offline
  browsing.
- `lib/services/quiz_storage.dart` — persists the in-progress **paper**
  (questions, current index, submitted answers, timer). QuizScreen loads it on
  open for the Resume flow and clears it on finish.
- Bundled `lib/data/demo_quizzes.dart` — used only when the app is not
  configured (no Supabase keys), so the app still runs and is testable
  offline.

---

## Step 15 — Tests

- `test/helpers/fakes.dart` — fake repositories and `serverQuestion` /
  `serverQuiz` builders (correctIndex `-1`) so widget tests can exercise the
  server-graded flow without a network.
- Unit: `quiz_cache_test.dart`, `quiz_list_notifier_test.dart` (mock
  shared_preferences).
- Widget: `auth_screen_test.dart`, `home_screen_test.dart`,
  `quiz_screen_test.dart` (demo local grading + server RPC grading + error
  retry). Tests build a small `GoRouter` and wrap the app in `MessageHost` so
  snackbars render.
- Integration: `integration_test/app_test.dart` — full sign-in → quiz →
  history flow against a real test Supabase project (not part of `flutter
  test`).
- CI (`.github/workflows/ci.yml`) runs `flutter analyze` + `flutter test` on
  every push/PR.

---

## Cheat sheet — patterns to remember

| Pattern | Where | What it does |
|---------|-------|--------------|
| `ConsumerWidget` / `ConsumerStatefulWidget` | every screen | read providers via `ref` |
| `ref.watch(...)` | screens | rebuild when provider changes |
| `AsyncNotifier` / `FutureProvider` | quiz list, attempts, stats | async state: loading/error/data |
| `Provider` for repositories | providers/ | DI for `SupabaseClient` |
| `ProviderScope` + `overrideWithValue` | main, tests | inject real/fake services |
| repositories only | all DB access | screens never touch the client |
| `.rpc('get_quizzes' / 'grade_attempt')` | quiz/progress repos | server-side content + grading |
| `GoRouter.redirect` | router | auth guards |
| `MessageHost` + `messageControllerProvider` | main | one place for all snackbars |
| `fromMap` / `toMap` | models | DB/cache rows ↔ typed objects |
| `hasCorrectAnswer` | quiz screen | demo vs server-graded behavior |

**The one rule to rule them all:**
> State lives in providers. Screens watch it. Builders draw from it.
> Screens never read the database — repositories do, and grade on the server
> whenever the answers exist there.