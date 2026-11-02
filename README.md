# GCSE Ace 🎓

> A modern, AI-powered exam preparation and study platform built with Flutter and Supabase, featuring timed mock and exit exams, personalized AI tutoring, and intelligent progress tracking.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Google Gemini](https://img.shields.io/badge/AI-Google%20Gemini-8E75C2?logo=google&logoColor=white)](https://ai.google.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20Desktop-4CAF50)](#-build-for-production)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 🌟 Key Features

- **📝 Timed Mock & Exit Exams**
  - Department-wide exams covering multiple courses with realistic timers.
  - Multiple-choice questions with instant client-side grading and detailed score badges.

- **🤖 AI Tutor & Question Explainer**
  - Interactive AI study companion powered by Google Gemini.
  - Step-by-step conceptual breakdowns and personalized explanations for incorrect answers.

- **📚 Course Study Materials & PDF Viewer**
  - Curated reading notes organized by department and specific course modules.
  - Direct computer PDF upload to Supabase storage with integrated in-app PDF launching.

- **📊 Comprehensive Performance Tracking**
  - Historical exam attempt logs, score averages, and percentage achievements.
  - Student profile dashboard with customizable username and account credentials.

- **👨‍💼 Unified Admin Management**
  - Role-based access control (Admin / Student).
  - Full management of Departments, Courses, Exam Papers, Questions, and Study Materials.

---

## 🛠️ Tech Stack

| Layer | Technology |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) (Dart 3) |
| **State Management** | [Flutter Riverpod](https://riverpod.dev) |
| **Routing** | [GoRouter](https://pub.dev/packages/go_router) |
| **Backend & Database** | [Supabase](https://supabase.com) (PostgreSQL, Row-Level Security) |
| **Authentication** | Supabase Auth (Email / Password + User Metadata) |
| **Cloud Storage** | Supabase Storage (`materials` bucket for PDFs) |
| **Edge Functions** | Supabase Deno Edge Functions |
| **Artificial Intelligence** | Google Gemini API (`gemini-2.5-flash` with dynamic model discovery) |

---

## 🚀 Quick Start

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.19+)
- A [Supabase](https://supabase.com) project
- A [Google AI Studio](https://aistudio.google.com/) Gemini API Key

### 1. Clone the Repository
```bash
git clone https://github.com/MohammedaminSa/testo-app.git
cd testo-app/gcse_ace
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Supabase Credentials
Verify your Supabase project credentials in `lib/config/supabase_config.dart`:
```dart
class SupabaseConfig {
  static const supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const supabaseAnonKey = 'YOUR_ANON_PUBLIC_KEY';
}
```

### 4. Run Locally
```bash
flutter run
```

---

## 📦 Build for Production

### Android Release (APK)
Generate a production release APK for direct installation on Android devices:

```bash
cd gcse_ace
flutter build apk --release
```

The compiled standalone APK will be located at:
```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🗄️ Database Setup

The database schema, RLS policies, and triggers are defined in [`db/schema.sql`](gcse_ace/db/schema.sql).

To deploy or inspect your schema:
1. Open your project's **SQL Editor** in the [Supabase Dashboard](https://supabase.com/dashboard).
2. Run the script in [`db/schema.sql`](gcse_ace/db/schema.sql) to set up all tables (`profiles`, `departments`, `courses`, `papers`, `questions`, `options`, `materials`, `attempts`, `chat_messages`), security policies, and storage buckets.

---

## 📁 Project Structure

```text
gcse_ace/
├── assets/images/           # App icons and visual assets
├── db/                      # PostgreSQL schema and migrations
│   └── schema.sql
├── lib/
│   ├── config/              # Supabase and app configuration
│   ├── models/              # Immutable data models (Paper, Course, Attempt, etc.)
│   ├── providers/           # Riverpod state notifiers and providers
│   ├── router/              # Declarative application routing (GoRouter)
│   ├── screens/
│   │   ├── admin/           # Course, Paper, and Material management screens
│   │   ├── auth/            # Sign In, Sign Up, and Auth layout
│   │   ├── chat_screen.dart # AI Tutor conversation screen
│   │   ├── exam_screen.dart # Timed exam taking interface
│   │   └── home_screen.dart # Student dashboard and department browse
│   ├── services/            # Supabase and AI service integrations
│   ├── theme/               # Colors, typography, and aurora gradients
│   └── widgets/             # Reusable UI components (GlassCard, Buttons, etc.)
└── supabase/
    └── functions/           # Supabase Edge Functions (chat AI proxy)
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
