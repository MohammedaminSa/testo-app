# GCSE Ace 📚

A comprehensive exam preparation and study platform built with Flutter and Supabase, featuring AI-powered tutoring, timed mock exams, and intelligent progress tracking.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.11.4-0175C2?logo=dart)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 🎯 Overview

GCSE Ace is a modern, feature-rich educational app designed to help students prepare for exams through:

- **📝 Timed Mock Exams** - Realistic exam conditions with auto-grading
- **🤖 AI Tutor** - Powered by Google Gemini for personalized explanations
- **📊 Progress Tracking** - Comprehensive statistics and attempt history
- **📖 Study Materials** - Organized content by subject
- **👨‍💼 Admin Panel** - Complete content management system

---

## ✨ Features

### For Students
- **Exam Practice**
  - Browse exams by department/subject
  - Timed exams with countdown timer
  - Multiple choice and written questions
  - Instant grading and feedback
  - Detailed results with percentage scores

- **AI-Powered Learning**
  - Conversational AI tutor for Q&A
  - Step-by-step question explanations
  - Personalized learning support
  - Chat history persistence

- **Progress Tracking**
  - Comprehensive attempt history
  - Performance statistics (average, best score)
  - Visual progress indicators
  - Attempt analytics by subject

- **Study Resources**
  - Organized study materials by subject
  - Searchable content library
  - Expandable subject sections

### For Administrators
- **Content Management**
  - Department/subject management
  - Exam paper creation and editing
  - Question bank with multiple choice options
  - Study material publishing
  - Bulk operations support

- **Admin Dashboard**
  - Centralized management interface
  - Role-based access control
  - Content analytics
  - User management capabilities

---

## 🏗️ Architecture

### Tech Stack

**Frontend:**
- **Flutter 3.x** - Cross-platform UI framework
- **Dart 3.11.4** - Programming language
- **Riverpod** - State management
- **GoRouter** - Declarative routing
- **Material Design 3** - UI/UX design system

**Backend:**
- **Supabase** - Backend-as-a-Service
- **PostgreSQL** - Relational database
- **Row Level Security** - Data access control
- **Edge Functions** - Serverless AI integration

**AI Integration:**
- **Google Gemini API** - Natural language processing
- **Streaming responses** - Real-time AI feedback

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.x or higher)
- Dart SDK (3.11.4 or higher)
- Supabase account
- Google Gemini API key (for AI features)
- IDE (VS Code, Android Studio, or IntelliJ)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/gcse_ace.git
   cd gcse_ace
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   
   Create a Supabase project at [supabase.com](https://supabase.com) and:
   
   a. Run the database schema:
   ```bash
   # Run db/schema.sql in Supabase SQL Editor
   ```
   
   b. Update credentials in `lib/config/supabase_config.dart`:
   ```dart
   static const supabaseUrl = 'YOUR_SUPABASE_URL';
   static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

4. **Set up AI features**
   
   a. Get a Gemini API key from [Google AI Studio](https://ai.google.dev/)
   
   b. Set the secret in Supabase Dashboard:
   ```bash
   # Dashboard → Edge Functions → Secrets
   # Add: GEMINI_API_KEY = your_api_key
   ```
   
   c. Deploy edge functions:
   ```bash
   supabase functions deploy chat
   supabase functions deploy explain-question
   ```

5. **Insert sample data**
   ```sql
   -- Follow steps in SUPABASE_SETUP_GUIDE.md
   -- This adds departments, papers, questions, and study materials
   ```

6. **Create an admin user**
   ```sql
   -- Sign up through the app first, then run:
   INSERT INTO profiles (id, full_name, role)
   VALUES ('USER_UUID', 'Admin Name', 'admin')
   ON CONFLICT (id) DO UPDATE SET role = 'admin';
   ```

7. **Run the app**
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

```
lib/
├── config/          # App configuration (Supabase, theme)
├── models/          # Data models (Department, Paper, Question, etc.)
├── providers/       # Riverpod state providers
├── router/          # Navigation and routing
├── screens/         # UI screens
│   ├── admin/       # Admin panel screens
│   ├── auth/        # Authentication screens
│   └── ...          # Student-facing screens
├── services/        # Business logic (Auth, Data, AI)
├── shell/           # App shell and bottom navigation
├── theme/           # Theme and styling
└── widgets/         # Reusable UI components

supabase/
├── functions/       # Edge functions
│   ├── chat/        # AI tutor endpoint
│   └── explain-question/  # Question explanations
└── config.toml      # Supabase configuration

db/
└── schema.sql       # PostgreSQL database schema
```

---

## 🗄️ Database Schema

### Core Tables
- `profiles` - User profiles with role-based access
- `departments` - Subject areas (Math, English, Science, etc.)
- `papers` - Exam papers with metadata
- `questions` - Exam questions (multiple choice & written)
- `options` - Multiple choice answer options
- `materials` - Study materials and notes
- `attempts` - Student exam attempts and scores
- `chat_messages` - AI tutor conversation history

### Security
- Row Level Security (RLS) enabled on all tables
- Role-based access control (student/admin)
- User-scoped data access
- Admin-only write permissions for content

---

## 🔧 Configuration

### Environment Variables

**Supabase Credentials** (`lib/config/supabase_config.dart`):
```dart
static const supabaseUrl = 'https://your-project.supabase.co';
static const supabaseAnonKey = 'your-anon-key';
```

**Edge Function Secrets** (Supabase Dashboard):
- `GEMINI_API_KEY` - Google Gemini API key for AI features

---

## 🧪 Testing

### Run Tests
```bash
flutter test
```

### Run Analyzer
```bash
flutter analyze
```

### Test Coverage
```bash
flutter test --coverage
```

---

## 📱 Building for Production

### Android
```bash
# Debug build
flutter build apk

# Release build
flutter build apk --release

# App bundle for Play Store
flutter build appbundle --release
```

### iOS
```bash
# Requires macOS and Xcode
flutter build ios --release
flutter build ipa --release
```

### Web
```bash
flutter build web --release
```

---

## 🎨 Customization

### Branding
- Update app name in `android/app/src/main/AndroidManifest.xml`
- Update app name in `ios/Runner/Info.plist`
- Replace app icon in `android/app/src/main/res/` and `ios/Runner/Assets.xcassets/`

### Theme
- Modify colors in `lib/theme/app_colors.dart`
- Adjust theme in `lib/theme/app_theme.dart`

---

## 📚 Documentation

- **[Supabase Setup Guide](SUPABASE_SETUP_GUIDE.md)** - Database setup with sample data
- **[Completion Report](COMPLETION_REPORT.md)** - Feature checklist and status
- **[Beginner's Guide](COMPLETE_BEGINNER_GUIDE.md)** - Code walkthrough

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Standards
- Follow Dart style guidelines
- Run `flutter analyze` before committing
- Write tests for new features
- Document public APIs

---

## 🐛 Troubleshooting

### Common Issues

**"Failed to load data"**
- Verify Supabase credentials in `lib/config/supabase_config.dart`
- Check Supabase project status (not paused)
- Ensure database schema is deployed

**"AI chat not working"**
- Verify `GEMINI_API_KEY` is set in Supabase secrets
- Check edge functions are deployed
- Review function logs in Supabase Dashboard

**"Admin tab not visible"**
- Ensure user role is set to 'admin' in profiles table
- Restart the app after role change

**"No questions showing"**
- Verify sample data is inserted (see `SUPABASE_SETUP_GUIDE.md`)
- Check foreign key relationships in database

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Authors

- **Your Name** - Initial work - [YourGitHub](https://github.com/yourusername)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for backend infrastructure
- Google for Gemini API
- Material Design team for design guidelines
- Open source community for packages and inspiration

---

## 📞 Support

For support and questions:
- Open an issue on GitHub
- Check existing documentation
- Review Supabase logs for backend issues

---

## 🗺️ Roadmap

### Planned Features
- [ ] Offline mode with local caching
- [ ] Push notifications for study reminders
- [ ] Social features (leaderboards, sharing)
- [ ] Export results to PDF
- [ ] Question bookmarking
- [ ] Practice mode (redo incorrect questions)
- [ ] Dark mode toggle
- [ ] Multi-language support
- [ ] Advanced analytics dashboard
- [ ] Gamification (badges, streaks)

---

**Built with ❤️ using Flutter and Supabase**
