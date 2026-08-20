# Testo - Complete Code Explanation Guide

This document explains every important file in the Testo app, line by line, organized by functional area.

---

## 📋 Table of Contents

1. [Project Structure Overview](#project-structure-overview)
2. [Configuration Files](#configuration-files)
3. [App Entry Point](#app-entry-point)
4. [Core Architecture](#core-architecture)
5. [Data Models](#data-models)
6. [Repositories (Database Layer)](#repositories-database-layer)
7. [Providers (State Management)](#providers-state-management)
8. [Services (Utilities)](#services-utilities)
9. [Screens (UI)](#screens-ui)
10. [Database Schema](#database-schema)

---

## 📁 Project Structure Overview

```
testo/
├── lib/
│   ├── main.dart                    # App entry point - starts everything
│   ├── core/                        # Core configuration
│   │   ├── config.dart              # Environment variables & Supabase setup
│   │   ├── router.dart              # Navigation routes & auth guards
│   │   └── theme.dart               # App colors & styling
│   ├── models/
│   │   └── models.dart              # Data structures (Quiz, Question, etc.)
│   ├── repositories/                # Database access layer
│   │   ├── auth_repository.dart     # Sign in/up/out logic
│   │   ├── quiz_repository.dart     # Fetch quizzes from database
│   │   ├── progress_repository.dart # Grade & save attempts
│   │   └── profile_repository.dart  # User profile updates
│   ├── providers/                   # State management (Riverpod)
│   │   ├── auth_providers.dart      # Auth state
│   │   ├── quiz_providers.dart      # Quiz list & caching
│   │   ├── progress_providers.dart  # History & stats
│   │   └── profile_providers.dart   # User profile
│   ├── services/                    # Utility services
│   │   ├── quiz_cache.dart          # Offline quiz storage
│   │   ├── quiz_storage.dart        # Resume quiz feature
│   │   ├── analytics_service.dart   # PostHog analytics
│   │   └── crash_reporter.dart      # Sentry crash reporting
│   ├── screens/                     # UI screens
│   │   ├── auth_screen.dart         # Login/signup
│   │   ├── home_screen.dart         # Quiz list
│   │   ├── quiz_screen.dart         # Take quiz
│   │   ├── review_screen.dart       # Results after quiz
│   │   ├── history_screen.dart      # Past attempts
│   │   └── profile_screen.dart      # User settings
│   └── data/
│       └── demo_quizzes.dart        # Offline demo quizzes
├── supabase/
│   ├── schema.sql                   # Database tables & functions
│   └── seed.sql                     # Sample quiz data
├── android/                         # Android-specific files
├── ios/                            # iOS-specific files
├── test/                           # Unit & widget tests
├── pubspec.yaml                    # Dependencies & app metadata
└── env.json                        # Your Supabase credentials (gitignored)
```

**Architecture Pattern:**
```
UI (Screens) 
    ↓ watches
Providers (State Management)
    ↓ calls
Repositories (Database Logic)
    ↓ connects to
Supabase (Backend)
```

---

## ⚙️ Configuration Files

### `pubspec.yaml` - Project Dependencies

```yaml
name: testo                          # App package name
description: "A new Flutter project."
publish_to: 'none'                   # Don't accidentally publish to pub.dev
version: 1.0.0+1                     # Version number + build number

environment:
  sdk: ^3.11.4                       # Dart version required

dependencies:
  flutter:
    sdk: flutter
  
  # UI
  cupertino_icons: ^1.0.8            # iOS-style icons
  
  # Backend & Auth
  supabase_flutter: ^2.16.0          # Supabase client (database + auth)
  
  # State Management
  flutter_riverpod: ^3.3.2           # Reactive state management
  
  # Navigation
  go_router: ^17.5.0                 # Routing with auth guards
  
  # Storage
  shared_preferences: ^2.5.3         # Local key-value storage (cache, resume)
  
  # Analytics & Monitoring
  posthog_flutter: ^5.36.2           # User analytics
  sentry_flutter: ^9.27.0            # Crash reporting
  
  # Utilities
  url_launcher: ^6.3.2               # Open URLs (privacy policy, terms)

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0              # Code quality rules
  integration_test:
    sdk: flutter
  flutter_launcher_icons: ^0.14.4    # Generate app icons

# App icon configuration
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"
  adaptive_icon_background: "#2563EB"  # Brand blue
  adaptive_icon_foreground: "assets/icon/icon_foreground.png"

flutter:
  uses-material-design: true         # Use Material Design widgets
```

**What each dependency does:**
- `supabase_flutter`: Connects to your database and handles authentication
- `flutter_riverpod`: Manages app state reactively (like Redux but simpler)
- `go_router`: Handles navigation between screens with auth protection
- `shared_preferences`: Saves data locally (quiz cache, resume state)
- `posthog_flutter`: Tracks user behavior (optional)
- `sentry_flutter`: Reports crashes and errors (optional)

---

### `env.json` - Your Configuration (NOT in git)

```json
{
  "SUPABASE_URL": "https://yourproject.supabase.co",
  "SUPABASE_ANON_KEY": "eyJhbG...",
  "POSTHOG_API_KEY": "",          // Optional: analytics
  "SENTRY_DSN": ""                // Optional: crash reporting
}
```

**Purpose:** These values are injected at compile time via `--dart-define-from-file=env.json`

---

## 🚀 App Entry Point

### `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'providers/auth_providers.dart';
import 'providers/message_controller.dart';
import 'providers/observability_providers.dart';
import 'services/analytics_service.dart';
import 'services/crash_reporter.dart';

Future<void> main() async {
  // Line 1: Make sure Flutter is ready before we do anything
  WidgetsFlutterBinding.ensureInitialized();
  
  // Line 2: Connect to Supabase (reads SUPABASE_URL and SUPABASE_ANON_KEY)
  await AppConfig.initSupabase();
  
  // Line 3: Initialize Sentry for crash reporting (only if SENTRY_DSN provided)
  await initCrashReporting();
  
  // Line 4: Initialize PostHog for analytics (only if POSTHOG_API_KEY provided)
  final analytics = AnalyticsService();
  await analytics.init();
  
  // Line 5: Start the app
  runApp(
    // ProviderScope: Riverpod's root widget - all state lives here
    ProviderScope(
      // Override: inject the analytics service so any screen can use it
      overrides: [analyticsProvider.overrideWithValue(analytics)],
      child: const TestoApp(),
    ),
  );
}
```

**What happens when app starts:**
1. Flutter initializes
2. App connects to your Supabase project
3. Crash reporting starts listening
4. Analytics starts tracking
5. The main UI tree begins

---

```dart
class TestoApp extends ConsumerWidget {
  const TestoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to auth state changes
    // When a user logs in, send their ID to analytics
    ref.listen<AsyncValue<User?>>(currentUserProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        ref.read(analyticsProvider).identify(user.id);
      }
    });
    
    // Get the router (navigation system)
    final router = ref.watch(routerProvider);
    
    // Build the app
    return MaterialApp.router(
      title: 'Testo',
      debugShowCheckedModeBanner: false,  // Hide debug banner
      theme: AppTheme.light(),            // Colors & styling
      routerConfig: router,               // Navigation routes
      builder: (context, child) =>
          // MessageHost: Shows all error messages as snackbars
          MessageHost(child: child ?? const SizedBox.shrink()),
    );
  }
}
```

**What ConsumerWidget means:**
- Normal Widget = can't access Riverpod state
- ConsumerWidget = can read and watch state via `ref`

**What `ref.watch` does:**
- Rebuilds this widget when the value changes
- Like listening to a stream or observable

**What `ref.listen` does:**
- Runs a callback when value changes
- Doesn't rebuild the widget

---

```dart
/// MessageHost: Centralized error/success message display
/// Any screen can do: ref.read(messageControllerProvider.notifier).show('Error!')
/// and this widget automatically shows it as a snackbar
class MessageHost extends ConsumerStatefulWidget {
  const MessageHost({super.key, required this.child});

  final Widget child;  // The actual app content

  @override
  ConsumerState<MessageHost> createState() => _MessageHostState();
}

class _MessageHostState extends ConsumerState<MessageHost> {
  @override
  Widget build(BuildContext context) {
    // Listen for messages from the messageController
    ref.listen<String?>(messageControllerProvider, (previous, next) {
      // If there's a new message
      if (next == null || next == previous) return;
      
      // Show it as a snackbar
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(next)));
      
      // Clear the message so it doesn't show again
      ref.read(messageControllerProvider.notifier).clear();
    });
    
    // Return the child (the rest of the app)
    return widget.child;
  }
}
```

**Why MessageHost exists:**
- Without it: Every screen would need `ScaffoldMessenger.of(context).show...`
- With it: Any screen just calls `messageControllerProvider.notifier.show('message')`
- Centralized, cleaner, testable

---

## 🎨 Core Architecture

### `lib/core/config.dart` - Configuration & Environment

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  // Read environment variables (from --dart-define-from-file=env.json)
  // If not provided, use placeholder defaults
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR-PROJECT.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR-ANON-KEY',
  );

  static const String posthogApiKey = String.fromEnvironment(
    'POSTHOG_API_KEY',
    defaultValue: '',
  );

  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  // Check if Supabase is configured with real values
  static bool get isConfigured =>
      supabaseUrl.contains('YOUR-PROJECT') == false &&
      supabaseAnonKey.contains('YOUR-ANON-KEY') == false;

  // Check if optional services are configured
  static bool get analyticsConfigured => posthogApiKey.isNotEmpty;
  static bool get crashReportingConfigured => sentryDsn.isNotEmpty;

  // Initialize Supabase connection
  static Future<void> initSupabase() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }
}

// Global shortcut to access Supabase client
SupabaseClient get supabase => Supabase.instance.client;
```

**How it works:**
1. When you run `flutter run --dart-define-from-file=env.json`
2. Flutter reads the JSON and makes them available via `String.fromEnvironment`
3. If you run without the flag, it uses the `defaultValue` (the placeholder)
4. `isConfigured` checks if real values were provided
5. If not configured, app falls back to demo mode (offline quizzes)

**Why this pattern:**
- Never commit secrets to git
- Same code works for dev, staging, production (just different env.json)
- Easy to test offline (no env.json = demo mode)

---

### `lib/core/router.dart` - Navigation & Auth Guards

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/auth_providers.dart';
import '../screens/auth_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/review_screen.dart';

/// Helper class to rebuild router when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    // Listen to auth changes and tell the router to rebuild
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();  // Clean up when done
    super.dispose();
  }
}
```

**What this does:**
- Connects go_router to the Supabase auth stream
- When user signs in/out, the router automatically redirects

---

```dart
final routerProvider = Provider<GoRouter>((ref) {
  // Get the auth repository
  final authRepository = ref.watch(authRepositoryProvider);
  
  // Create a stream that notifies when auth changes
  final refreshStream = GoRouterRefreshStream(
    authRepository.onAuthStateChange
  );
  
  // Clean up when provider is disposed
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    initialLocation: '/',  // Start at home screen
    refreshListenable: refreshStream,  // Rebuild on auth changes
    
    // REDIRECT LOGIC (Auth Guard)
    redirect: (_, state) {
      final loggedIn = authRepository.currentSession != null;
      final location = state.matchedLocation;
      
      // Public screens (anyone can access)
      final isPublic = location == '/auth' || location == '/forgot-password';

      // If not logged in and trying to access protected screen → go to login
      if (!loggedIn && !isPublic) return '/auth';
      
      // If logged in and trying to access login screen → go to home
      if (loggedIn && location == '/auth') return '/';
      
      // Otherwise, allow navigation
      return null;
    },
    
    // ROUTES (URL → Screen mapping)
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const HomeScreen(),
      ),
      
      GoRoute(
        path: '/auth',
        builder: (_, _) => const AuthScreen(),
      ),
      
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      
      GoRoute(
        path: '/quiz',
        builder: (_, state) => QuizScreen(
          // Pass the Quiz object via "extra" (not URL params)
          quiz: state.extra! as Quiz
        ),
      ),
      
      GoRoute(
        path: '/review',
        builder: (_, state) {
          // Pass quiz + result together
          final args = state.extra! as ReviewArgs;
          return ReviewScreen(quiz: args.quiz, result: args.result);
        },
      ),
      
      GoRoute(
        path: '/history',
        builder: (_, _) => const HistoryScreen(),
      ),
      
      GoRoute(
        path: '/profile',
        builder: (_, _) => const ProfileScreen(),
      ),
    ],
  );
});
```

**How navigation works:**
```dart
// Navigate to a screen
context.push('/history');

// Navigate with data
context.push('/quiz', extra: myQuiz);

// Go back
context.pop();
```

**Auth guard logic:**
- User not logged in + tries to visit `/profile` → redirected to `/auth`
- User logged in + tries to visit `/auth` → redirected to `/`
- This happens automatically on every navigation

---

### `lib/core/theme.dart` - App Styling

```dart
import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFF2563EB);  // Blue
  static const Color success = Color(0xFF16A34A);  // Green (correct answers)
  static const Color error = Color(0xFFDC2626);    // Red (wrong answers)
  
  // Light theme
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      
      // Button styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Text field styling
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
      
      // Card styling
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
```

**Why centralized theme:**
- Change one color → entire app updates
- Consistent spacing and styling
- Easy to add dark mode later

---

## 📊 Data Models

### `lib/models/models.dart` - Data Structures

```dart
/// A single quiz question
class Question {
  final String id;
  final String text;                    // Question text
  final List<String> options;           // Answer choices
  final int correctIndex;               // Which option is correct (0-3)
                                        // -1 = unknown (server-graded quiz)
  final String explanation;             // Why this answer is correct
  final String topic;                   // Category for weak-area tracking

  const Question({
    required this.id,
    required this.text,
    required this.options,
    this.correctIndex = -1,
    required this.explanation,
    required this.topic,
  });

  /// Does this question have the answer locally?
  /// Demo quizzes: true
  /// Server quizzes: false (answers stored server-side only)
  bool get hasCorrectAnswer => 
      correctIndex >= 0 && correctIndex < options.length;

  /// Convert database row to Question object
  factory Question.fromMap(Map<String, dynamic> map) {
    // Options come as array of {position: 1, text: "...", is_correct: true}
    final optionRows = ((map['options'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    
    // Sort by position
    optionRows.sort((a, b) => 
        (a['position'] as int).compareTo(b['position'] as int));
    
    return Question(
      id: map['id'] as String? ?? '',
      text: map['text'] as String,
      options: optionRows.map((o) => o['text'] as String).toList(),
      
      // Find which option has is_correct = true
      // Returns -1 if none found (server-graded)
      correctIndex: optionRows.indexWhere((o) => o['is_correct'] == true),
      
      explanation: map['explanation'] as String? ?? '',
      topic: map['topic'] as String? ?? 'General',
    );
  }

  /// Convert Question back to database format
  /// Used for caching and resume feature
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'options': [
        for (var i = 0; i < options.length; i++)
          {
            'position': i + 1,
            'text': options[i],
            'is_correct': i == correctIndex,
          },
      ],
      'explanation': explanation,
      'topic': topic,
    };
  }
}
```

**Key insight: `correctIndex = -1` means answer is hidden**
- Demo quizzes: correctIndex is 0, 1, 2, or 3 (known locally)
- Server quizzes: correctIndex is -1 (must call server to grade)
- This prevents cheating (user can't inspect app memory to find answers)

---

```dart
/// A complete quiz
class Quiz {
  final String id;
  final String title;
  final String description;
  final String category;               // e.g., "Mobile", "Software Engineering"
  final String difficulty;             // e.g., "Beginner", "Intermediate"
  final List<String> tags;             // e.g., ["Flutter", "Dart"]
  final int? timeLimitSeconds;         // Seconds per question, or null
  final int? paperSize;                // Max questions per attempt, or null
  final List<Question> questions;

  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    this.category = 'General',
    this.difficulty = 'Beginner',
    this.tags = const [],
    this.timeLimitSeconds,
    this.paperSize,
    required this.questions,
  });

  /// Convert database row to Quiz
  factory Quiz.fromMap(Map<String, dynamic> map) {
    final questionRows = ((map['questions'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    
    // Sort questions by position
    questionRows.sort((a, b) => 
        (a['position'] as int).compareTo(b['position'] as int));
    
    return Quiz(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      difficulty: map['difficulty'] as String? ?? 'Beginner',
      tags: ((map['tags'] as List?) ?? const []).cast<String>(),
      timeLimitSeconds: map['time_limit_seconds'] as int?,
      paperSize: map['paper_size'] as int?,
      
      // Convert each question row to Question object
      questions: questionRows.map(Question.fromMap).toList(),
    );
  }

  /// Convert Quiz back to database format
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'tags': tags,
      'time_limit_seconds': timeLimitSeconds,
      'paper_size': paperSize,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }
}
```

**Special features:**
- `timeLimitSeconds`: If set, quiz has a countdown timer per question
- `paperSize`: If set, quiz shows random subset (e.g., 5 random questions from 50)

---

```dart
/// User's profile
class Profile {
  final String id;           // Matches auth.users.id
  final String displayName;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.displayName,
    required this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      displayName: map['display_name'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
```

---

```dart
/// What user selected for one question
class SubmittedAnswer {
  final String questionId;
  final int? selectedIndex;  // null = no answer (time ran out)

  const SubmittedAnswer({
    required this.questionId,
    this.selectedIndex,
  });

  factory SubmittedAnswer.fromMap(Map<String, dynamic> map) {
    return SubmittedAnswer(
      questionId: map['question_id'] as String? ?? '',
      selectedIndex: map['selected_index'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question_id': questionId,
      'selected_index': selectedIndex,
    };
  }
}
```

---

```dart
/// One question's result (after grading)
class QuestionAnswer {
  final String questionId;
  final String questionText;
  final String topic;
  final int? selectedIndex;      // What user picked
  final int correctIndex;        // What was correct
  final String selectedText;     // User's answer text
  final String correctText;      // Correct answer text
  final bool isCorrect;          // True if user got it right
  final String explanation;      // Why this answer is correct

  const QuestionAnswer({
    required this.questionId,
    required this.questionText,
    required this.topic,
    required this.selectedIndex,
    required this.correctIndex,
    required this.selectedText,
    required this.correctText,
    required this.isCorrect,
    required this.explanation,
  });

  factory QuestionAnswer.fromMap(Map<String, dynamic> map) {
    return QuestionAnswer(
      questionId: map['question_id'] as String? ?? '',
      questionText: map['question_text'] as String? ?? '',
      topic: map['topic'] as String? ?? 'General',
      selectedIndex: map['selected_index'] as int?,
      correctIndex: map['correct_index'] as int? ?? 0,
      selectedText: map['selected_text'] as String? ?? '',
      correctText: map['correct_text'] as String? ?? '',
      isCorrect: map['is_correct'] == true,
      explanation: map['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question_id': questionId,
      'question_text': questionText,
      'topic': topic,
      'selected_index': selectedIndex,
      'correct_index': correctIndex,
      'selected_text': selectedText,
      'correct_text': correctText,
      'is_correct': isCorrect,
      'explanation': explanation,
    };
  }
}
```

**Used in review screen to show:**
- ✅ Questions you got right
- ❌ Questions you got wrong (with correct answer)
- 📖 Explanations for all

---

```dart
/// Complete quiz result
class QuizResult {
  final int correctCount;
  final int totalQuestions;
  final double scorePercent;
  final List<String> questionsOrder;  // Order questions were shown
  final List<QuestionAnswer> answers;

  const QuizResult({
    required this.correctCount,
    required this.totalQuestions,
    required this.scorePercent,
    required this.questionsOrder,
    required this.answers,
  });

  /// Parse from server's grade_attempt response
  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      correctCount: map['correct_answers'] as int? ?? 0,
      totalQuestions: map['total_questions'] as int? ?? 0,
      scorePercent: (map['score_percent'] as num?)?.toDouble() ?? 0,
      questionsOrder: ((map['questions_order'] as List?) ?? const [])
          .cast<String>(),
      answers: ((map['answers'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(QuestionAnswer.fromMap)
          .toList(),
    );
  }
}
```

---

```dart
/// Saved quiz attempt (history)
class QuizAttempt {
  final String quizId;
  final String quizTitle;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercent;
  final List<String> questionsOrder;
  final List<QuestionAnswer> answers;
  final DateTime completedAt;

  const QuizAttempt({
    required this.quizId,
    required this.quizTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercent,
    this.questionsOrder = const [],
    this.answers = const [],
    required this.completedAt,
  });

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      quizId: map['quiz_id'] as String? ?? '',
      quizTitle: map['quiz_title'] as String? ?? 'Quiz',
      totalQuestions: map['total_questions'] as int? ?? 0,
      correctAnswers: map['correct_answers'] as int? ?? 0,
      scorePercent: (map['score_percent'] as num?)?.toDouble() ?? 0,
      questionsOrder: ((map['questions_order'] as List?) ?? const [])
          .cast<String>(),
      answers: ((map['answers'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(QuestionAnswer.fromMap)
          .toList(),
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quiz_id': quizId,
      'quiz_title': quizTitle,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'score_percent': scorePercent,
      'questions_order': questionsOrder,
      'answers': answers.map((a) => a.toMap()).toList(),
      'completed_at': completedAt.toUtc().toIso8601String(),
    };
  }
}
```

**Stored in `quiz_attempts` table:**
- History screen shows all attempts
- Stats calculated from attempts
- Review screen rebuilt from stored `answers`

---

## 🗄️ Repositories (Database Layer)

### `lib/repositories/quiz_repository.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Handles all quiz-related database operations
class QuizRepository {
  final SupabaseClient _client;

  const QuizRepository(this._client);

  /// Fetch all quizzes from database
  /// Calls the get_quizzes() PostgreSQL function
  /// Returns quizzes WITHOUT correct answers (server-graded)
  Future<List<Quiz>> fetchQuizzes() async {
    // Call the SQL function defined in schema.sql
    final data = await _client.rpc('get_quizzes');

    // Convert JSON array to List<Quiz>
    return (data as List)
        .map((row) => Quiz.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
```

**Why use a SQL function instead of direct table query:**
- Function can hide `is_correct` field before sending to client
- More secure (answers never leave server)
- Can add complex logic (filtering, randomization) in database

---

### `lib/repositories/progress_repository.dart`

```dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class ProgressRepository {
  final SupabaseClient _client;

  const ProgressRepository(this._client);

  /// Submit answers and get graded result
  /// Server compares answers against correct_index in database
  Future<QuizResult> gradeAttempt({
    required String quizId,
    required List<SubmittedAnswer> answers,
  }) async {
    // Call grade_attempt PostgreSQL function
    final data = await _client.rpc('grade_attempt', params: {
      'p_quiz_id': quizId,
      // Convert answers to JSON string
      'p_answers': jsonEncode([
        for (final a in answers) a.toMap()
      ]),
    });

    // Parse result
    return QuizResult.fromMap(data as Map<String, dynamic>);
  }

  /// Fetch user's quiz history
  Future<List<QuizAttempt>> fetchAttempts() async {
    final data = await _client
        .from('quiz_attempts')
        .select()
        .order('completed_at', ascending: false);  // Newest first

    return (data as List)
        .map((row) => QuizAttempt.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Calculate statistics from attempts
  static Map<String, dynamic> computeStats(List<QuizAttempt> attempts) {
    if (attempts.isEmpty) {
      return {
        'attemptCount': 0,
        'averageScore': 0.0,
        'bestScore': 0.0,
        'weakTopics': <String>[],
      };
    }

    // Calculate average score
    final avgScore = attempts
        .map((a) => a.scorePercent)
        .reduce((a, b) => a + b) / attempts.length;

    // Find best score
    final bestScore = attempts
        .map((a) => a.scorePercent)
        .reduce((a, b) => a > b ? a : b);

    // Find topics with wrong answers
    final topicErrors = <String, int>{};
    for (final attempt in attempts) {
      for (final answer in attempt.answers) {
        if (!answer.isCorrect) {
          topicErrors[answer.topic] = (topicErrors[answer.topic] ?? 0) + 1;
        }
      }
    }

    // Sort topics by error count (most errors first)
    final weakTopics = topicErrors.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'attemptCount': attempts.length,
      'averageScore': avgScore,
      'bestScore': bestScore,
      'weakTopics': weakTopics.take(5).map((e) => e.key).toList(),
    };
  }
}
```

**The grading flow:**
1. User finishes quiz → app calls `gradeAttempt()`
2. Server receives answers, looks up correct answers in database
3. Server calculates score, creates `QuestionAnswer` objects
4. Server inserts attempt into `quiz_attempts` table
5. Server returns result to app
6. App shows review screen

**Security:** Client never sees correct answers until after grading

---

### `lib/repositories/auth_repository.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  const AuthRepository(this._client);

  /// Current user session (null if signed out)
  Session? get currentSession => _client.auth.currentSession;

  /// Stream of auth state changes (sign in, sign out, token refresh)
  Stream<AuthState> get onAuthStateChange => 
      _client.auth.onAuthStateChange;

  /// Sign up with email/password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},  // Stored in auth.users.raw_user_meta_data
    );
    return response;
  }

  /// Sign in with email/password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google OAuth
  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutter://login-callback/',
    );
  }

  /// Sign in with Apple OAuth
  Future<bool> signInWithApple() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.flutter://login-callback/',
    );
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.flutter://login-callback/',
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
```

**OAuth flow:**
1. User taps "Sign in with Google"
2. App opens browser to Google login
3. User approves
4. Google redirects to `io.supabase.flutter://login-callback/`
5. Deep link opens app
6. Supabase SDK handles callback automatically
7. User is signed in

---

### `lib/repositories/profile_repository.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class ProfileRepository {
  final SupabaseClient _client;

  const ProfileRepository(this._client);

  /// Fetch current user's profile
  Future<Profile> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();  // Expect exactly one row

    return Profile.fromMap(data as Map<String, dynamic>);
  }

  /// Update display name
  Future<void> updateDisplayName(String userId, String displayName) async {
    await _client
        .from('profiles')
        .update({'display_name': displayName})
        .eq('id', userId);
  }
}
```

---

## 🔌 Providers (State Management)

### `lib/providers/supabase_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';

/// Global Supabase client instance
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return supabase;  // From config.dart
});
```

**Why:** Dependency injection. Repositories receive the client via providers.

---

### `lib/providers/auth_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import 'supabase_provider.dart';

/// Auth repository instance
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseProvider));
});

/// Current user (reactive)
/// Rebuilds widgets when user signs in/out
final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider)
      .onAuthStateChange
      .map((state) => state.session?.user);
});
```

**Usage in widgets:**
```dart
final userAsync = ref.watch(currentUserProvider);

userAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (_, __) => Text('Error'),
  data: (user) => user == null 
      ? Text('Signed out')
      : Text('Hello ${user.email}'),
);
```

---

### `lib/providers/quiz_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config.dart';
import '../data/demo_quizzes.dart';
import '../models/models.dart';
import '../repositories/quiz_repository.dart';
import '../services/quiz_cache.dart';
import 'supabase_provider.dart';

final quizCacheProvider = Provider<QuizCache>((ref) => QuizCache());

final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => QuizRepository(ref.watch(supabaseProvider)),
);

/// Is Supabase configured? (or using demo mode)
final backendConfiguredProvider =
    Provider<bool>((ref) => AppConfig.isConfigured);

/// Quiz catalog with offline support
class QuizListNotifier extends AsyncNotifier<List<Quiz>> {
  @override
  Future<List<Quiz>> build() async {
    // Demo mode: return bundled quizzes
    if (!ref.read(backendConfiguredProvider)) {
      return DemoQuizzes.quizzes;
    }

    final repo = ref.read(quizRepositoryProvider);

    // Try loading from cache first
    final cached = await ref.read(quizCacheProvider).load();
    
    if (cached != null && cached.isNotEmpty) {
      // Show cached data immediately
      // Then refresh in background
      Future(() => refresh());
      return cached;
    }

    // No cache: fetch from network
    return _fetch(repo);
  }

  Future<List<Quiz>> _fetch(QuizRepository repo) async {
    final quizzes = await repo.fetchQuizzes();
    // Save to cache for next time
    await ref.read(quizCacheProvider).save(quizzes);
    return quizzes;
  }

  /// Refresh from network (pull-to-refresh)
  Future<void> refresh() async {
    if (!ref.read(backendConfiguredProvider)) return;
    
    try {
      final quizzes = await _fetch(ref.read(quizRepositoryProvider));
      state = AsyncData(quizzes);  // Update state
    } catch (_) {
      // Keep cached data on error (offline mode)
    }
  }
}

final quizListProvider =
    AsyncNotifierProvider<QuizListNotifier, List<Quiz>>(
      QuizListNotifier.new
    );
```

**Offline strategy:**
1. First load: Show spinner → fetch from network → cache it
2. Second load: Show cache instantly → fetch in background → update if changed
3. Offline: Show cache, don't fail

---

### `lib/providers/progress_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/progress_repository.dart';
import 'supabase_provider.dart';

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(supabaseProvider)),
);

/// User's quiz attempt history
final attemptsProvider = FutureProvider<List<QuizAttempt>>((ref) {
  return ref.watch(progressRepositoryProvider).fetchAttempts();
});

/// Computed statistics
final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final attempts = await ref.watch(attemptsProvider.future);
    return ProgressRepository.computeStats(attempts);
  } catch (_) {
    // Return empty stats on error (don't crash app)
    return ProgressRepository.computeStats(const []);
  }
});
```

**Usage:**
```dart
final statsAsync = ref.watch(statsProvider);

statsAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (_, __) => Text('Could not load stats'),
  data: (stats) => Column(
    children: [
      Text('Attempts: ${stats['attemptCount']}'),
      Text('Average: ${stats['averageScore']}%'),
      Text('Best: ${stats['bestScore']}%'),
    ],
  ),
);
```

---

### `lib/providers/profile_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/profile_repository.dart';
import 'auth_providers.dart';
import 'supabase_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseProvider)),
);

/// Current user's profile
final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;

  return ref.watch(profileRepositoryProvider).fetchProfile(user.id);
});
```

---

### `lib/providers/message_controller.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple state notifier for showing messages
class MessageController extends StateNotifier<String?> {
  MessageController() : super(null);

  /// Show a message
  void show(String message) => state = message;

  /// Clear the message
  void clear() => state = null;
}

final messageControllerProvider =
    StateNotifierProvider<MessageController, String?>(
      (ref) => MessageController(),
    );
```

**Usage anywhere in app:**
```dart
// Show error message
ref.read(messageControllerProvider.notifier).show('Network error!');

// Show success message
ref.read(messageControllerProvider.notifier).show('Quiz completed!');
```

MessageHost (in main.dart) listens and shows as snackbar.

---

### `lib/providers/observability_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';

/// Analytics service instance
/// Injected in main.dart via overrideWithValue
final analyticsProvider = Provider<AnalyticsService>((ref) {
  throw UnimplementedError('analyticsProvider must be overridden');
});
```

---

## 🛠️ Services (Utilities)

### `lib/services/quiz_cache.dart` - Offline Storage

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class QuizCache {
  static const String _key = 'cached_quizzes';

  /// Save quizzes to device storage
  Future<void> save(List<Quiz> quizzes) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert quizzes to JSON
    final json = jsonEncode(
      quizzes.map((q) => q.toMap()).toList()
    );
    
    // Save to shared_preferences
    await prefs.setString(_key, json);
  }

  /// Load quizzes from device storage
  Future<List<Quiz>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    
    if (json == null) return null;

    // Parse JSON back to List<Quiz>
    final list = jsonDecode(json) as List;
    return list
        .cast<Map<String, dynamic>>()
        .map((m) => Quiz.fromMap(m))
        .toList();
  }

  /// Clear cache
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
```

**Why:** App works offline. Cached quizzes shown even without internet.

---

### `lib/services/quiz_storage.dart` - Resume Feature

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Stores in-progress quiz state so user can resume after app closes
class QuizStorage {
  static String _key(String quizId) => 'quiz_state_$quizId';

  /// Save current quiz state
  static Future<void> save({
    required String quizId,
    required List<Question> paper,
    required int currentIndex,
    required List<SubmittedAnswer> answers,
    required int? secondsLeft,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final state = {
      'paper': paper.map((q) => q.toMap()).toList(),
      'currentIndex': currentIndex,
      'answers': answers.map((a) => a.toMap()).toList(),
      'secondsLeft': secondsLeft,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_key(quizId), jsonEncode(state));
  }

  /// Load saved quiz state
  static Future<Map<String, dynamic>?> load(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key(quizId));
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  /// Clear saved state (after quiz finished)
  static Future<void> clear(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(quizId));
  }
}
```

**Resume flow:**
1. User starts quiz
2. After each answer, `QuizStorage.save()` is called
3. User closes app mid-quiz
4. User reopens app and taps same quiz
5. App calls `QuizStorage.load()`, finds saved state
6. Shows dialog: "Resume where you left off?" or "Start over?"

---

### `lib/services/analytics_service.dart` - PostHog Analytics

```dart
import 'package:posthog_flutter/posthog_flutter.dart';
import '../core/config.dart';

class AnalyticsService {
  /// Initialize PostHog (if API key provided)
  Future<void> init() async {
    if (!AppConfig.analyticsConfigured) return;  // No-op if not configured

    await Posthog().setup(
      apiKey: AppConfig.posthogApiKey,
      host: 'https://app.posthog.com',
    );
  }

  /// Identify user (called when they sign in)
  void identify(String userId) {
    if (!AppConfig.analyticsConfigured) return;
    Posthog().identify(userId: userId);
  }

  /// Track an event
  void track(String event, {Map<String, dynamic>? properties}) {
    if (!AppConfig.analyticsConfigured) return;
    Posthog().capture(eventName: event, properties: properties);
  }
}
```

**Events tracked:**
- `sign_in`
- `sign_up`
- `quiz_started` (with quiz_id)
- `quiz_completed` (with score)

**Privacy:** Only tracks if `POSTHOG_API_KEY` is provided. Otherwise silent no-op.

---

### `lib/services/crash_reporter.dart` - Sentry Error Tracking

```dart
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../core/config.dart';

/// Initialize Sentry for crash reporting
Future<void> initCrashReporting() async {
  if (!AppConfig.crashReportingConfigured) return;  // No-op if not configured

  await SentryFlutter.init(
    (options) {
      options.dsn = AppConfig.sentryDsn;
      options.tracesSampleRate = 1.0;  // 100% of transactions
      options.environment = kReleaseMode ? 'production' : 'development';
    },
  );
}
```

**What it does:**
- Catches unhandled exceptions
- Catches Flutter framework errors
- Sends crash reports to Sentry dashboard
- Only if `SENTRY_DSN` provided

---

## 🖼️ Screens (UI)

I'll create a separate detailed file for screens since they're longer. Should I continue with:

1. **Screen-by-screen breakdown** (auth, home, quiz, review, etc.)
2. **Database schema explanation** (SQL functions)
3. **Demo data explanation**

Which would you like me to detail next?
