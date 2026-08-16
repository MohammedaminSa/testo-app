# Testo — Code Walkthrough (in execution order)

This guide explains the whole app **in the order the code actually runs**,
starting from the moment the app boots. Every block is explained step by step,
written for someone new to Flutter.

---

## The journey at a glance

```
1. main()  ──────────────────────────────────────────────  lib/main.dart
     │  starts Flutter, connects to Supabase
2. TestoApp  ────────────────────────────────────────────  lib/main.dart
     │  MaterialApp + theme, then checks: logged in?
     ├── NO  → AuthScreen (sign in / sign up)  ────────── lib/screens/auth_screen.dart
     │          user signs in → StreamBuilder rebuilds →
     └── YES → HomeScreen  ─────────────────────────────  lib/screens/home_screen.dart
                ├─ loads stats (from ProgressService)
                ├─ loads quiz list (from QuizService) ──  lib/services/*
                ├─ user taps a quiz → QuizScreen  ─────── lib/screens/quiz_screen.dart
                │     user answers → screen returns the score
                │     → HomeScreen saves the attempt + shows result dialog
                └─ History button → HistoryScreen  ────── lib/screens/history_screen.dart
```

Data shapes used everywhere are defined in `lib/models/models.dart`.
All styling lives in `lib/core/theme.dart`.

---

## Step 0 — Before any code runs: `pubspec.yaml`

Think of `pubspec.yaml` as the app's "shopping list". It lists the packages
(libraries) the app depends on:

```yaml
dependencies:
  flutter:          # the UI framework itself
    sdk: flutter
  supabase_flutter: # lets us talk to our cloud database
```

`supabase_flutter` is the only real dependency. Everything else is built-in Flutter.

---

## Step 1 — `lib/main.dart`: the entry point

Every Dart app starts at a function called `main`.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initSupabase();
  runApp(const TestoApp());
}
```

| Line | What it does |
|------|--------------|
| `Future<void> main() async` | `main` is the start point. `async` because we wait on setup. |
| `WidgetsFlutterBinding.ensureInitialized()` | Boilerplate that makes sure Flutter's engine is ready before we touch plugins (like Supabase). |
| `await AppConfig.initSupabase()` | Connects to the Supabase cloud project. `await` pauses here until the connection is done. |
| `runApp(const TestoApp())` | Tells Flutter: "build this widget as the root of the whole app." |

Then the root widget:

```dart
class TestoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Testo',
      theme: AppTheme.light(),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;
          if (session != null) return const HomeScreen();
          return const AuthScreen();
        },
      ),
    );
  }
}
```

- `MaterialApp` is the widget that configures the whole app (name, theme, and the first screen to show).
- **StatelessWidget vs StatefulWidget**: `StatelessWidget` has no changing data — it just builds UI once. Screens that change (forms, quizzes) use `StatefulWidget` (more on this in Step 5).
- `StreamBuilder<AuthState>`: listens to a *stream* (a source that emits events over time). Supabase emits an event every time login state changes.
- `builder:` re-runs whenever a new event arrives. It reads the current `session`:
  - `session != null` → user is logged in → `HomeScreen`
  - otherwise → `AuthScreen`

**So Step 1's only job is: boot up, connect to the cloud, and pick the first screen based on whether you're logged in.**

---

## Step 2 — `lib/core/config.dart`: app settings

`main.dart` called `AppConfig.initSupabase()`. Here's what that does:

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://YOUR-PROJECT.supabase.co',
);
```

- `String.fromEnvironment('SUPABASE_URL', ...)` reads a value passed at launch:
  ```bash
  flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  ```
- `defaultValue` is used when the flag was NOT passed — which is why the app
  falls back to demo quizzes when not configured.

```dart
static bool get isConfigured =>
    supabaseUrl.contains('YOUR-PROJECT') == false &&
    supabaseAnonKey.contains('YOUR-ANON-KEY') == false;
```

`isConfigured` is `true` only when real keys were provided. `HomeScreen` uses this
to decide: fetch from the cloud, or use bundled demo data.

```dart
static Future<void> initSupabase() async {
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
}
```

Creates the global connection. The last line of the file:

```dart
SupabaseClient get supabase => Supabase.instance.client;
```

is a shortcut so any file can just write `supabase` to reach the database.

---

## Step 3 — `lib/core/theme.dart`: the look and feel

A dictionary of colors and reusable styles:

```dart
static const Color primary = Color(0xFF2563EB); // brand blue
static const Color success = Color(0xFF16A34A); // green = correct/passed
static const Color error   = Color(0xFFDC2626); // red = wrong/failed
```

`ThemeData` centralizes how buttons, text fields, and cards look. Because the
whole app uses `AppTheme.light()`, changing one color here restyles everything.

---

## Step 4 — `lib/screens/auth_screen.dart`: sign in / sign up

Shown when the user is **not** logged in. It's a `StatefulWidget` because it has
data that changes: the form text, a loading flag, and whether we're in
login-or-signup mode.

The State's data:

```dart
final _emailController = TextEditingController();  // holds what user types
final _passwordController = TextEditingController();
bool _isLogin = true;       // true = login mode, false = signup mode
bool _isLoading = false;    // true while talking to server (disable button)
bool _obscurePassword = true; // password hidden (show/hide eye icon)
```

**TextEditingController** = a Flutter object that holds the text in a text field.
Flutter owns the text as the user types; the controller is our handle to read it later.

The action happens in `_submit()`:

```dart
if (!_formKey.currentState!.validate()) return;  // check all validators passed
setState(() => _isLoading = true);               // show spinner, disable button
try {
  if (_isLogin) {
    await supabase.auth.signInWithPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  } else {
    await supabase.auth.signUp(...);
  }
} on AuthException catch (e) {
  // show a snackbar (little popup at the bottom) with the error message
} catch (e) {
  // generic fallback error message
} finally {
  if (mounted) setState(() => _isLoading = false);
}
```

- `.validate()` runs every field's `validator:` function (e.g. "email must contain @", "password at least 6 chars"). If any fails, we stop.
- `try / on AuthException / catch / finally` is error handling: *try* the call; if Supabase throws a known `AuthException` handle it specially; any other error → generic message; `finally` always runs → stop the spinner.
- **The magic**: after a successful `signInWithPassword`, the auth stream in `main.dart` emits → `StreamBuilder` rebuilds → `AuthScreen` is swapped for `HomeScreen`. *The screen itself never navigates — it just vanishes when the stream updates.*

---

## Step 5 — `lib/screens/home_screen.dart`: the main screen

Now the user is logged in. HomeScreen loads two things in the background:
progress stats, and the list of available quizzes.

```dart
class _HomeScreenState extends State<HomeScreen> {
  final _progressService = ProgressService();
  final _quizService = QuizService();
  bool _loadingStats = true;
  Map<String, dynamic> _stats = {};
  List<Quiz>? _quizzes;
  bool _loadingQuizzes = true;
  bool _quizError = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadQuizzes();
  }
```

- `initState()` runs once when the screen is created, before the first `build()`. It kicks off both network loads.
- Notice the pattern everywhere: a **state flag** (`_loadingQuizzes`) + the **actual data** (`_quizzes`). `build()` reads these to decide what to draw.

### Loading quizzes (our recent change)

```dart
Future<void> _loadQuizzes() async {
  if (!AppConfig.isConfigured) {          // no Supabase keys → use bundled demo
    setState(() {
      _quizzes = DemoQuizzes.quizzes;
      _loadingQuizzes = false;
    });
    return;
  }
  setState(() => _loadingQuizzes = true);
  try {
    final quizzes = await _quizService.fetchQuizzes();
    if (mounted) {
      setState(() {
        _quizzes = quizzes;
        _loadingQuizzes = false;
        _quizError = false;
      });
    }
  } catch (_) {
    if (mounted) setState(() {
      _loadingQuizzes = false;
      _quizError = true;
    });
  }
}
```

| Branch | Result |
|--------|--------|
| Not configured | Load `DemoQuizzes.quizzes` (bundled sample data) |
| Fetch succeeds | Store real quizzes from the cloud |
| Fetch fails (`catch`) | `_quizError = true` → the UI shows an error card with a Retry button |

`if (mounted)` protects against updating a screen the user already left while the
network call was in flight (see the "mounted" rule in the earlier guide).

### `build()` — drawing the screen

```dart
return Scaffold(
  appBar: AppBar(
    title: const Text('Testo'),
    actions: [ IconButton(History…), IconButton(Sign out…) ],
  ),
  body: RefreshIndicator(          // pull-to-refresh
    onRefresh: () async {
      await Future.wait([_loadStats(), _loadQuizzes()]);
    },
    child: ListView(               // scrollable, top-to-bottom
      padding: const EdgeInsets.all(16),
      children: [
        // headline text…
        _buildStatsCard(),         // progress card (or spinner)
        const Text('Available Quizzes'),
        ..._buildQuizCards(),      // one Card per quiz
      ],
    ),
  ),
);
```

- `_buildQuizCards()` returns a list of widgets. The `...` **spread operator** pours that list into the `children` list.
- `ListTile` inside `_buildQuizCard` is a pre-built list row (icon + title + subtitle + arrow). Its `onTap` starts the quiz:

```dart
final correctCount = await Navigator.of(context).push<int>(
  MaterialPageRoute(builder: (_) => QuizScreen(quiz: quiz)),
);
if (correctCount != null) _saveAttempt(quiz, correctCount);
```

`Navigator.push` opens QuizScreen "on top" of this one. When QuizScreen finishes
it does `Navigator.pop(score)` — and that `int` score becomes the value of the
`await` here. **So HomeScreen waits for the quiz to finish, gets the score, and saves it.**

---

## Step 6 — `lib/services/`: the network layer

These classes know how to talk to Supabase. They know nothing about UI.

### `quiz_service.dart`

```dart
class QuizService {
  Future<List<Quiz>> fetchQuizzes() async {
    final data = await supabase
        .from('quizzes')
        .select('*, questions(*, options(*))')  // fetch quizzes + questions + options
        .order('id');
    return (data as List)
        .map((row) => Quiz.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
```

- `Future<List<Quiz>>` = "eventually returns a list of quizzes". Because it's a network call, it returns a promise immediately; `await` waits for the real value.
- `.select('*, questions(*, options(*))')` = one request that fetches a quiz **and** all its questions **and** all those questions' options (nested / embedded). This is a Supabase feature that avoids many separate calls.
- `.map((row) => Quiz.fromMap(...))` = convert every raw database row into a proper `Quiz` object (Step 7).

### `progress_service.dart`

Same pattern for results. Key methods:

- `saveAttempt(attempt)` → `INSERT`s one quiz result into the `quiz_attempts` table.
- `fetchAttempts()` → `SELECT`s the logged-in user's past attempts, newest first (`.order('completed_at', ascending: false)`).
- `fetchStats(attempts)` → computes averages/best score in plain Dart loops (no database needed).

Notice: **the service returns raw `Map`s / typed objects, and screens turn them into UI.** Services don't touch `setState` — that's the screen's job.

---

## Step 7 — `lib/models/models.dart`: the data shapes

When the service gets rows from the DB, it needs to turn JSON maps into typed objects.
That's what the `factory fromMap(...)` constructors do.

Raw JSON row from Supabase (simplified):

```json
{
  "id": "flutter_basics",
  "title": "Flutter Basics",
  "questions": [
    { "text": "What is 2+2?", "position": 1,
      "options": [ {"text": "3", "is_correct": false, "position": 1},
                   {"text": "4", "is_correct": true,  "position": 2} ] }
  ]
}
```

```dart
factory Question.fromMap(Map<String, dynamic> map) {
  final optionRows =
      ((map['options'] as List?) ?? const []).cast<Map<String, dynamic>>();
  optionRows.sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
  return Question(
    text: map['text'] as String,
    options: optionRows.map((o) => o['text'] as String).toList(),
    correctIndex: optionRows.indexWhere((o) => o['is_correct'] == true),
    explanation: map['explanation'] as String? ?? '',
  );
}
```

Explained line by line:

| Code | Meaning |
|------|---------|
| `(map['options'] as List?) ?? const []` | Get the options list; if it's null, use an empty list. |
| `.cast<Map<String, dynamic>>()` | Tell Dart "each item is a map". |
| `.sort((a, b) => (a['position'] as int).compareTo(...))` | Order options by their `position` column (DB order isn't guaranteed). |
| `optionRows.map((o) => o['text'] as String).toList()` | Pull just the text of each option into `List<String>`. |
| `optionRows.indexWhere((o) => o['is_correct'] == true)` | The DB marks the right answer with a flag; we find its index (0-based position). |

`Quiz.fromMap` does the same at the quiz level, converting each question row with
`Question.fromMap` and sorting questions by `position`.

`QuizAttempt` at the bottom of the file has **two** directions:
- `fromMap(...)` — convert a DB row (attempt history) into an object.
- `toMap()` — convert an object back into a map to send **to** the DB (when saving a result).

---

## Step 8 — `lib/screens/quiz_screen.dart`: answering questions

HomeScreen pushed this screen with a `Quiz`. The State keeps the quiz-in-progress data:

```dart
int _currentIndex = 0;    // which question we're on
int? _selectedIndex;      // which option the user picked (null = none yet)
bool _answered = false;   // answered the current question yet?
int _correctCount = 0;    // running score
```

### Tapping an answer

```dart
void _selectOption(int index) {
  if (_answered) return;                       // can't change once answered
  setState(() {
    _selectedIndex = index;
    _answered = true;
    if (index == _question.correctIndex) _correctCount++;
  });
}
```

1. `if (_answered) return;` — locks the answer once chosen.
2. `setState` updates the data, which rebuilds the screen to show green/red highlights + the explanation.

### Next / Finish

```dart
void _next() {
  if (_isLast) {
    Navigator.of(context).pop(_correctCount);  // return the score to HomeScreen
    return;
  }
  setState(() { _currentIndex++; _selectedIndex = null; _answered = false; });
}
```

The score is **returned** via `pop(_correctCount)`, which is exactly the value
`HomeScreen` was `await`ing in Step 5.

### `_buildOption` — the highlight logic

```dart
if (_answered) {
  if (isCorrect) {         // the green option: mark correct
    borderColor = AppTheme.success; ...
  } else if (isSelected) { // the red option: user picked wrong
    borderColor = AppTheme.error; ...
  }
}
```

Colors only appear *after* the user answers (`_answered == true`). The correct
answer turns green; a wrong pick turns red. An explanation box
(`_buildExplanation`) appears underneath.

---

## Step 9 — Back on HomeScreen: saving the result

After the quiz returns its score:

```dart
Future<void> _saveAttempt(Quiz quiz, int correctCount) async {
  final attempt = QuizAttempt(
    quizId: quiz.id,
    quizTitle: quiz.title,
    totalQuestions: quiz.questions.length,
    correctAnswers: correctCount,
    scorePercent: correctCount / quiz.questions.length * 100,
    completedAt: DateTime.now(),
  );
  try {
    await _progressService.saveAttempt(attempt);   // upload to cloud
    if (mounted) _showResultDialog(attempt);
  } catch (_) {
    if (mounted) _showResultDialog(attempt, saved: false); // note "couldn't save"
  }
}
```

- Builds a `QuizAttempt` from the quiz + score.
- Uploads it. Success → normal result dialog; failure → same dialog but with an orange "couldn't save" note (so the user is never blocked).
- `_showResultDialog` uses `showDialog` + `AlertDialog` — a popup window.

---

## Step 10 — `lib/screens/history_screen.dart`: past attempts

```dart
late Future<List<QuizAttempt>> _attempts;

@override
void initState() {
  super.initState();
  _attempts = _progressService.fetchAttempts();
}
```

Instead of manual `setState` + state flags, this screen stores the `Future` itself
and lets a `FutureBuilder` react to it:

```dart
FutureBuilder<List<QuizAttempt>>(
  future: _attempts,
  builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator()); // still loading
    }
    final attempts = snapshot.data ?? [];
    if (attempts.isEmpty) { ... empty-state UI ... }
    return ListView.separated(...);   // one ListTile per attempt
  },
)
```

- `FutureBuilder` watches a `Future`: shows a spinner while `waiting`, then builds UI from the result.
- Pass/fail coloring comes from `attempt.scorePercent >= 50`.
- `_formatDate` converts the UTC date back to local time for display.

---

## Step 11 — The database side: `supabase/schema.sql` & `seed.sql`

These are SQL scripts you run once in the Supabase dashboard (not Dart code).

`schema.sql` creates tables:

- `quizzes` — one row per quiz (`id`, `title`, `description`).
- `questions` — one row per question, with `position` (ordering) and `explanation`.
- `options` — one row per answer choice, with `is_correct` flag.
- `quiz_attempts` — one row per finished attempt, tied to the user.

**Foreign keys** link them: `questions.quiz_id → quizzes.id`,
`options.question_id → questions.id`. Delete a quiz → its questions and options
are deleted too (`on delete cascade`).

**RLS (Row Level Security)** = a safety rule on each table. For content tables:
`using (auth.role() = 'authenticated')` — *only signed-in users may read*.
For attempts: users can only see/insert **their own** rows
(`auth.uid() = user_id`).

`seed.sql` just inserts the sample quizzes so the app has content after setup.
That's why you run schema first, then seed.

---

## Cheat sheet — patterns to remember

| Pattern | Where it appears | What it does |
|---------|------------------|--------------|
| `StatefulWidget` + `State` | all screens | UI whose data can change |
| `setState(() { ... })` | all screens | update data + rebuild UI |
| `initState()` | home/auth | run once on screen open |
| `if (mounted)` | after every `await` | don't touch a destroyed screen |
| `async` / `await` / `Future` | services, loads | handle slow network work |
| `factory ...fromMap` | models | convert DB row → Dart object |
| `Navigator.push` / `pop` | home → quiz → home | open a screen; send a value back |
| `StreamBuilder` / `FutureBuilder` | main / history | rebuild UI when data arrives |
| `try / catch / finally` | saves, auth | fail gracefully instead of crashing |

**The one rule to rule them all:**
> Data lives in `State`. `build()` draws the screen from that data.
> Change data → `setState` → the screen redraws.
