# GCSE Ace - Complete Beginner's Guide to Flutter & Dart

This guide explains **every single line** of code in the GCSE Ace app, assuming you're completely new to Flutter and Dart.

---

## 📚 Table of Contents

1. [What is Flutter & Dart?](#what-is-flutter--dart)
2. [Project Structure](#project-structure)
3. [Entry Point - main.dart](#entry-point---maindart)
4. [Configuration - supabase_config.dart](#configuration)
5. [Theme - app_theme.dart](#theme)
6. [Navigation - app_router.dart](#navigation)
7. [Authentication Service](#authentication-service)
8. [Data Models](#data-models)
9. [State Management (Providers)](#state-management)
10. [UI Screens](#ui-screens)
11. [Database Schema](#database-schema)

---

## 🎯 What is Flutter & Dart?

### **Dart**
- A programming language created by Google
- Similar to JavaScript, Java, C#
- Used to write Flutter apps
- Runs on mobile (iOS/Android), web, desktop

### **Flutter**
- A UI framework (toolkit for building apps)
- Write once, run on iOS, Android, Web, Windows, Mac, Linux
- Uses widgets (building blocks) to create the UI
- Like React Native, but faster and more complete

### **Key Dart Concepts You'll See:**

```dart
// 1. VARIABLES - storing data
String name = "John";        // Text
int age = 25;                // Whole number
double price = 9.99;         // Decimal number
bool isLoggedIn = true;      // true or false
List<String> items = ["a", "b"];  // Array/List
Map<String, int> scores = {"math": 95};  // Dictionary/Object

// 2. FUNCTIONS - reusable code blocks
void printName(String name) {
  print("Hello $name");  // String interpolation with $
}

// 3. CLASSES - blueprints for objects
class Person {
  final String name;     // final = can't change after creation
  final int age;
  
  Person({required this.name, required this.age});  // Constructor
}

// 4. ASYNC/AWAIT - waiting for slow operations
Future<String> fetchData() async {
  await Future.delayed(Duration(seconds: 2));  // Wait 2 seconds
  return "Data loaded!";
}

// 5. NULL SAFETY - preventing crashes
String? nullableName;     // ? means "can be null"
String name = nullableName ?? "Default";  // ?? means "if null, use this"
```

---

## 📁 Project Structure

```
gcse_ace/
├── lib/                          # All your Dart code lives here
│   ├── main.dart                 # App entry point (starts here)
│   ├── config/                   # Configuration files
│   │   └── supabase_config.dart  # Database connection setup
│   ├── theme/                    # Colors & styling
│   │   └── app_theme.dart        # App's look & feel
│   ├── router/                   # Navigation
│   │   └── app_router.dart       # Routes & auth guards
│   ├── services/                 # Business logic
│   │   ├── auth_service.dart     # Login/signup logic
│   │   └── data_service.dart     # Database queries
│   ├── providers/                # State management (Riverpod)
│   │   ├── auth_provider.dart    # Auth state
│   │   ├── data_provider.dart    # Data state
│   │   └── exam_provider.dart    # Exam state
│   ├── models/                   # Data structures
│   │   ├── department.dart       # Subject (Math, English, etc.)
│   │   ├── paper.dart            # Exam paper
│   │   ├── question.dart         # One question
│   │   └── option.dart           # One answer choice
│   ├── screens/                  # UI pages
│   │   ├── auth/                 # Login/signup screens
│   │   ├── home_screen.dart      # Home page
│   │   ├── exam_screen.dart      # Take exam page
│   │   └── ...
│   └── shell/                    # App layout
│       └── app_shell.dart        # Bottom navigation bar
├── db/                           # Database
│   └── schema.sql                # Database tables structure
├── android/                      # Android-specific files
├── ios/                          # iOS-specific files
├── pubspec.yaml                  # Dependencies (like package.json)
└── README.md                     # Project info
```

---

## 🚀 Entry Point - main.dart

### **Line-by-Line Explanation**

```dart
import 'package:flutter/material.dart';
```
**What it does:** Imports Flutter's core UI library (Material Design components)
**Think of it as:** Like `import React from 'react'` in JavaScript

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
```
**What it does:** Imports Riverpod (state management library)
**Think of it as:** Like Redux or Context API in React

```dart
import 'config/supabase_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
```
**What it does:** Imports our own files
**Relative imports:** Files in the same `lib/` folder

---

```dart
Future<void> main() async {
```
**Breaking it down:**
- `Future<void>` = This function will complete later (asynchronous)
- `main` = The entry point (like `int main()` in C/C++)
- `async` = This function can wait for other operations

**Think of it as:** The `componentDidMount()` of your entire app

---

```dart
  WidgetsFlutterBinding.ensureInitialized();
```
**What it does:** Makes sure Flutter is ready before we do anything
**Why:** We're about to talk to the database, which needs Flutter to be ready
**Rule:** Always call this if you use `async` in `main()`

---

```dart
  await SupabaseConfig.initialize();
```
**What it does:** Connects to Supabase (your database in the cloud)
**`await`:** Waits until connection is established before continuing
**Like:** Opening a database connection before starting your app

---

```dart
  runApp(const ProviderScope(child: GcseAceApp()));
```
**Breaking it down:**
- `runApp()` = Start the Flutter app (renders the UI)
- `ProviderScope` = Riverpod's root widget (makes state available everywhere)
- `GcseAceApp()` = Your actual app (defined below)
- `const` = This widget never changes (compile-time constant for performance)

**Think of it as:** `ReactDOM.render(<Provider><App /></Provider>, root)`

---

```dart
}
```
**End of `main()` function**

---

### **The App Widget**

```dart
class GcseAceApp extends ConsumerWidget {
```
**Breaking it down:**
- `class GcseAceApp` = Define a new class called GcseAceApp
- `extends ConsumerWidget` = Inherit from ConsumerWidget (Riverpod's version of StatelessWidget)
- **ConsumerWidget vs StatelessWidget:** ConsumerWidget can read reactive state via `ref`

---

```dart
  const GcseAceApp({super.key});
```
**What it does:** Constructor (creates an instance of GcseAceApp)
- `const` = Can be created at compile time
- `{super.key}` = Named parameter, passes `key` to parent class
- **Key:** Helps Flutter identify widgets (like React's `key` prop)

---

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
```
**Breaking it down:**
- `@override` = We're replacing the parent's `build` method
- `Widget` = Return type (everything in Flutter is a widget)
- `build()` = Called whenever the UI needs to be drawn
- `BuildContext context` = Information about where this widget is in the tree
- `WidgetRef ref` = Gives access to Riverpod providers (state)

**Think of it as:** The `render()` method in React

---

```dart
    final router = ref.watch(routerProvider);
```
**Breaking it down:**
- `final` = Can't be changed after assignment (like `const` in JavaScript)
- `router` = Variable name
- `ref.watch()` = Subscribe to a provider (rebuilds when it changes)
- `routerProvider` = Defined in `router/app_router.dart`

**What it does:** Gets the navigation system and listens for changes

---

```dart
    return MaterialApp.router(
```
**What it does:** The root widget of your app
- `MaterialApp` = Provides Material Design styling
- `.router` = Use custom routing (go_router) instead of Navigator

---

```dart
      title: 'GCSE Ace',
```
**What it does:** App name shown in task switcher (iOS/Android)

---

```dart
      theme: AppTheme.light,
```
**What it does:** Apply colors, fonts, button styles from `theme/app_theme.dart`

---

```dart
      routerConfig: router,
```
**What it does:** Tell the app to use our custom router for navigation

---

```dart
    );
  }
}
```
**End of build method and class**

---

## ⚙️ Configuration - supabase_config.dart

Let me read this file first:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }
}

SupabaseClient get supabase => Supabase.instance.client;
```

### **Line-by-Line:**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```
**What it does:** Import Supabase SDK (library for talking to your database)

---

```dart
class SupabaseConfig {
```
**What it does:** Create a class to hold configuration

---

```dart
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
```
**Breaking it down:**
- `static` = Belongs to the class itself, not an instance (like class methods in JS)
- `const` = Value never changes
- `String` = Text type
- `String.fromEnvironment('SUPABASE_URL')` = Get from command line (--dart-define)
- `defaultValue` = Use this if not provided

**How it works:**
```bash
# With value provided:
flutter run --dart-define=SUPABASE_URL=https://myproject.supabase.co

# Without value (uses default):
flutter run
```

---

```dart
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );
```
**What it does:** Same as above, but for the API key (like a password)

---

```dart
  static Future<void> initialize() async {
```
**What it does:** Connect to Supabase
- `static` = Can call without creating an instance: `SupabaseConfig.initialize()`
- `Future<void>` = Returns nothing, but completes later
- `async` = Can use `await` inside

---

```dart
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
```
**What it does:** Actually connect to your Supabase project
- `await` = Wait until connection is established
- `url` = Where your database lives
- `publishableKey` = Public API key (safe to expose)

---

```dart
  }
}
```
**End of method and class**

---

```dart
SupabaseClient get supabase => Supabase.instance.client;
```
**Breaking it down:**
- `SupabaseClient` = Type (class from supabase_flutter)
- `get supabase` = A getter (like a property)
- `=>` = Short syntax for returning one value
- `Supabase.instance.client` = The actual client object

**What it does:** Creates a shortcut to access Supabase anywhere
**Usage:**
```dart
// Instead of:
Supabase.instance.client.from('papers').select();

// You can do:
supabase.from('papers').select();
```

---

## 🎨 Theme - app_theme.dart

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),  // Blue color
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
```

### **Line-by-Line:**

```dart
import 'package:flutter/material.dart';
```
**What it does:** Import Material Design components

---

```dart
class AppTheme {
```
**What it does:** Container for theme configurations

---

```dart
  static final ThemeData light = ThemeData(
```
**Breaking it down:**
- `static final` = Shared across entire app, can't change
- `ThemeData` = Flutter's theme configuration object
- `light` = Name of this theme

---

```dart
    useMaterial3: true,
```
**What it does:** Use Material Design 3 (Google's latest design system)

---

```dart
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.light,
    ),
```
**Breaking it down:**
- `colorScheme` = All colors in your app (primary, secondary, background, etc.)
- `fromSeed()` = Generate all colors from one "seed" color
- `0xFF2563EB` = Hexadecimal color (FF = opacity, 2563EB = blue)
- `brightness: Brightness.light` = Light mode (vs dark mode)

**Magic:** Flutter automatically creates 20+ color variations from this one color!

---

```dart
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
```
**Breaking it down:**
- `appBarTheme` = Styling for all AppBars in the app
- `centerTitle: true` = Center the title text
- `elevation: 0` = No shadow

---

```dart
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
```
**What it does:** Style all Card widgets
- `elevation: 0` = No shadow
- `RoundedRectangleBorder` = Rounded corners
- `BorderRadius.circular(12)` = 12 pixels radius (rounded corners)

---

## 🧭 Navigation - app_router.dart

This is complex! Let me break it down section by section:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/department_papers_screen.dart';
import '../screens/exam_screen.dart';
import '../screens/paper_detail_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../services/auth_service.dart';
import '../shell/app_shell.dart';
```

### **Imports:**

```dart
import 'package:go_router/go_router.dart';
```
**What it does:** Navigation library (like React Router)

```dart
import '../screens/auth/sign_in_screen.dart';
```
**What it does:** Import UI screens
- `..` = Go up one folder
- `/` = Then go into that folder

**Path:** `router/` → `../` (go to `lib/`) → `screens/auth/sign_in_screen.dart`

---

### **The Router Provider:**

```dart
final routerProvider = Provider<GoRouter>((ref) {
```
**Breaking it down:**
- `final` = Can't reassign
- `routerProvider` = Name
- `Provider<GoRouter>` = Riverpod provider that returns a GoRouter
- `(ref)` = Function parameter (gives access to other providers)

**What is a Provider?**
Think of it as a global variable that:
1. Can be accessed anywhere
2. Automatically updates the UI when it changes
3. Is managed by Riverpod

---

```dart
  ref.watch(authStateProvider);
```
**What it does:** Watch the auth state
- When user signs in/out, this provider rebuilds
- Rebuilding = router re-runs the redirect logic
- Result: Automatic navigation on auth changes

---

```dart
  return GoRouter(
    initialLocation: '/',
```
**What it does:** Create the router
- `initialLocation` = First screen to show (`/` = home)

---

```dart
    redirect: (context, state) {
```
**What it does:** Run this function before every navigation
- `context` = Build context
- `state` = Router state (current location, params, etc.)
- Returns: New location to go to, or `null` to allow navigation

**This is the AUTH GUARD!**

---

```dart
      final user = AuthService.instance.currentUser;
```
**What it does:** Get the current logged-in user
- If logged in: `user` is a User object
- If logged out: `user` is `null`

---

```dart
      final loggingIn =
          state.matchedLocation == '/signin' ||
          state.matchedLocation == '/signup';
```
**What it does:** Check if user is trying to access login/signup pages
- `matchedLocation` = The URL they're trying to visit
- `||` = OR operator

---

```dart
      if (user == null && !loggingIn) return '/signin';
```
**What it does:** If not logged in AND not going to login page → redirect to login

**Logic:**
- User tries to visit `/exam/123`
- `user == null` (not logged in)
- `!loggingIn` = true (they're not going to `/signin`)
- Return `/signin` → They get redirected to login

---

```dart
      if (user != null && loggingIn) return '/';
```
**What it does:** If logged in AND trying to access login page → redirect to home

**Why:** Logged-in users shouldn't see the login screen

---

```dart
      return null;
```
**What it does:** Allow navigation (don't redirect)

---

### **Routes:**

```dart
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AppShell()),
```
**Breaking it down:**
- `GoRoute` = One route definition
- `path: '/'` = The URL
- `builder` = Function that returns a widget
- `=> const AppShell()` = Show the AppShell widget

**When user visits `https://yourapp.com/` → Show AppShell**

---

```dart
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
```
**What it does:** `/signin` → Show sign-in screen

---

```dart
      GoRoute(
        path: '/department/:departmentId',
        builder: (context, state) {
```
**Breaking it down:**
- `/department/:departmentId` = URL with a parameter
- `:departmentId` = Variable (can be any value)

**Examples:**
- `/department/math-123` → departmentId = "math-123"
- `/department/english-456` → departmentId = "english-456"

---

```dart
          final departmentId = state.pathParameters['departmentId']!;
```
**What it does:** Extract the departmentId from the URL
- `pathParameters` = Dictionary of URL parameters
- `['departmentId']` = Get the value
- `!` = Non-null assertion (we know it exists)

---

```dart
          final departments = ref.read(departmentsProvider).value ?? [];
```
**Breaking it down:**
- `ref.read()` = Get the current value (doesn't listen for changes)
- `departmentsProvider` = Provider that fetches departments from database
- `.value` = The actual data (AsyncValue wrapper)
- `??` = If null, use empty list

---

```dart
          final department = departments.firstWhere(
            (d) => d.id == departmentId,
            orElse: () => throw Exception('Department not found'),
          );
```
**What it does:** Find the department with matching ID
- `firstWhere()` = Array.find() in JavaScript
- `(d) => d.id == departmentId` = Condition to match
- `orElse` = If not found, throw error

---

```dart
          return DepartmentPapersScreen(department: department);
```
**What it does:** Show the DepartmentPapersScreen, passing the department object

---

```dart
      GoRoute(
        path: '/paper/:paperId',
        builder: (context, state) {
          final paperId = state.pathParameters['paperId']!;
          return PaperDetailScreen(paperId: paperId);
        },
      ),
```
**What it does:** `/paper/123` → Show paper detail screen for paper 123

---

```dart
      GoRoute(
        path: '/exam/:paperId',
        builder: (context, state) {
          final paperId = state.pathParameters['paperId']!;
          return ExamScreen(paperId: paperId);
        },
      ),
```
**What it does:** `/exam/123` → Start exam for paper 123

---

```dart
    ],
  );
});
```
**End of routes, GoRouter, and provider**

---

## 🔐 Authentication Service

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  bool get isSignedIn => _client.auth.currentSession != null;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
```

### **Line-by-Line:**

```dart
class AuthService {
  AuthService._();
```
**Breaking it down:**
- `AuthService._()` = Private constructor (the `_` makes it private)
- **Why?** We don't want people to do `AuthService()` (create multiple instances)

---

```dart
  static final AuthService instance = AuthService._();
```
**What it does:** Create ONE instance that everyone shares (Singleton pattern)

**Usage:**
```dart
// Everyone uses the same instance:
AuthService.instance.signIn(...);
AuthService.instance.signOut();
```

---

```dart
  SupabaseClient get _client => Supabase.instance.client;
```
**What it does:** Shortcut to access Supabase client
- `_client` = Private (only this class can use it)

---

```dart
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
```
**What it does:** Stream of auth events (sign in, sign out, token refresh)

**What is a Stream?**
- Like an event emitter
- Emits values over time
- You can listen to it: `onAuthStateChange.listen((event) { ... })`

---

```dart
  bool get isSignedIn => _client.auth.currentSession != null;
```
**What it does:** Check if user is logged in
- If session exists → true
- If no session → false

---

```dart
  User? get currentUser => _client.auth.currentUser;
```
**Breaking it down:**
- `User?` = Can be User or null (the `?` means nullable)
- Returns the current user object, or null if signed out

---

```dart
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }
```
**Breaking it down:**
- `Future<void>` = Async function that returns nothing
- `{required String email, required String password}` = Named parameters (MUST be provided)
- `await` = Wait for sign-in to complete
- `signInWithPassword()` = Supabase's method

**Usage:**
```dart
await AuthService.instance.signIn(
  email: 'user@example.com',
  password: 'password123',
);
```

---

```dart
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return _client.auth.signUp(email: email, password: password);
  }
```
**What it does:** Create a new user account
- `AuthResponse` = Object containing user info and session

---

```dart
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
```
**What it does:** Log out the current user

---

This is getting long! Would you like me to:

1. **Continue with the rest** (Models, Providers, Screens)?
2. **Focus on a specific area** you want to understand deeply?
3. **Create practice exercises** for each concept?
4. **Explain a specific screen in detail** (like the exam screen)?

Let me know and I'll continue! 🚀
