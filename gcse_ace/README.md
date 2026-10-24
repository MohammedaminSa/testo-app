# GCSE Ace 📚

A comprehensive exam preparation and study platform built with Flutter and Supabase, featuring AI-powered tutoring, timed mock exams, and intelligent progress tracking.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.11.4-0175C2?logo=dart)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 🎯 Overview

GCSE Ace helps students prepare for exams through timed mock exams, AI-powered tutoring, and comprehensive progress tracking.

### Key Features
- **📝 Timed Mock Exams** - Realistic exam conditions with instant grading
- **🤖 AI Tutor** - Powered by Google Gemini for personalized explanations
- **📊 Progress Tracking** - Detailed statistics and attempt history
- **📖 Study Materials** - Organized content by subject
- **👨‍💼 Admin Panel** - Complete content management system

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.x or higher
- Dart 3.11.4 or higher
- Google account (for Firebase)
- Supabase account
- Google Gemini API key

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/gcse_ace.git
cd gcse_ace
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Locally
```bash
flutter run
```

---

## 🔧 Full Deployment Guide

Follow these steps to deploy your app to production.

### Part 1: Backend Setup (Supabase)

#### Step 1: Create Supabase Project

1. Go to https://supabase.com and sign up
2. Click "New Project"
3. Fill in:
   - Project Name: `gcse-ace-prod`
   - Database Password: (create strong password)
   - Region: Choose closest to your users
   - Pricing: Free tier
4. Wait 2-3 minutes for setup
5. Save your credentials from **Settings → API**:
   - Project URL
   - Anon/Public Key

#### Step 2: Deploy Database Schema

1. Open **SQL Editor** in Supabase Dashboard
2. Click **"New Query"**
3. Copy entire content from `db/schema.sql`
4. Paste and click **"Run"**
5. Verify tables created in **Table Editor**

#### Step 3: Insert Sample Data

Run these SQL queries in SQL Editor:

**Departments:**
```sql
INSERT INTO departments (id, name, slug, description) VALUES
  ('d1111111-1111-1111-1111-111111111111', 'Computer Science', 'computer-science', 'Algorithms, Data Structures, Theory of Computation'),
  ('d2222222-2222-2222-2222-222222222222', 'Software Engineering', 'software-engineering', 'Software Design, Development, Testing'),
  ('d3333333-3333-3333-3333-333333333333', 'Information Technology', 'information-technology', 'Networks, Database Systems'),
  ('d4444444-4444-4444-4444-444444444444', 'Data Science', 'data-science', 'Machine Learning, Statistics'),
  ('d5555555-5555-5555-5555-555555555555', 'Cybersecurity', 'cybersecurity', 'Network Security, Cryptography');
```

**Papers:**
```sql
INSERT INTO papers (id, department_id, title, year, duration_minutes, total_marks) VALUES
  ('p1111111-1111-1111-1111-111111111111', 'd1111111-1111-1111-1111-111111111111', 'Data Structures & Algorithms - Midterm', 2024, 120, 100);
```

**Questions & Options:**
```sql
INSERT INTO questions (id, paper_id, order_number, text, marks, question_type, correct_answer, explanation) VALUES
  ('q1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111111', 1, 'What is the time complexity of searching in a balanced BST?', 2, 'multiple-choice', 'B', 'Balanced BST search is O(log n)');

INSERT INTO options (question_id, letter, text, is_correct) VALUES
  ('q1111111-1111-1111-1111-111111111111', 'A', 'O(n)', false),
  ('q1111111-1111-1111-1111-111111111111', 'B', 'O(log n)', true),
  ('q1111111-1111-1111-1111-111111111111', 'C', 'O(1)', false),
  ('q1111111-1111-1111-1111-111111111111', 'D', 'O(n²)', false);
```

**Study Materials:**
```sql
INSERT INTO materials (department_id, title, content) VALUES
  ('d1111111-1111-1111-1111-111111111111', 'Data Structures Guide', 
   'Arrays: O(1) access. Linked Lists: O(1) insert at head. Stacks: LIFO. Queues: FIFO. Trees: hierarchical. Hash Tables: O(1) average.');
```

#### Step 4: Update App Credentials

Edit `lib/config/supabase_config.dart`:
```dart
class SupabaseConfig {
  static const supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const supabaseAnonKey = 'YOUR_ANON_KEY';
}
```

#### Step 5: Setup AI Features

1. **Get Gemini API Key**
   - Go to https://ai.google.dev/
   - Click "Get API Key"
   - Create API key and copy it

2. **Set Supabase Secret**
   - Supabase Dashboard → Settings → Edge Functions
   - Add secret: `GEMINI_API_KEY` = `your_api_key`

3. **Install Supabase CLI**

   **Windows (using Scoop):**
   ```bash
   # Install Scoop
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   irm get.scoop.sh | iex
   
   # Add Supabase bucket
   scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
   
   # Install CLI
   scoop install supabase
   ```

4. **Deploy Edge Functions**
   ```bash
   # Login
   supabase login
   
   # Link project
   cd gcse_ace
   supabase link --project-ref YOUR_PROJECT_REF
   
   # Deploy functions
   supabase functions deploy chat
   supabase functions deploy explain-question
   ```

---

### Part 2: Deploy Web App (Firebase)

#### Step 1: Install Firebase CLI

```bash
# Install Node.js from https://nodejs.org/ first

# Install Firebase CLI
npm install -g firebase-tools
```

#### Step 2: Create Firebase Project

1. Go to https://console.firebase.google.com/
2. Click "Add project"
3. Project name: `gcse-ace`
4. Disable Google Analytics (optional)
5. Click "Create project"

#### Step 3: Initialize Firebase

```bash
# Login to Firebase
firebase login

# Navigate to project
cd gcse_ace

# Initialize hosting
firebase init hosting
```

**Prompts:**
- Select project: `gcse-ace`
- Public directory: `build/web`
- Single-page app: `Yes`
- GitHub deploys: `No`
- Overwrite index.html: `No`

#### Step 4: Build Flutter Web

```bash
flutter build web --release
```

#### Step 5: Deploy

```bash
firebase deploy --only hosting
```

Your app is now live at: `https://gcse-ace.web.app`

---

### Part 3: Create Admin User

1. Sign up through your deployed app
2. Get your user ID from Supabase → Authentication
3. Run in SQL Editor:
   ```sql
   UPDATE profiles SET role = 'admin' WHERE id = 'YOUR_USER_ID';
   ```
4. Refresh app and you'll see Admin tab

---

## 📁 Project Structure

```
lib/
├── config/          # App configuration
├── models/          # Data models
├── providers/       # State management
├── router/          # Navigation
├── screens/         # UI screens
│   ├── admin/       # Admin panel
│   └── auth/        # Authentication
├── services/        # Business logic
├── theme/           # Styling
└── widgets/         # Reusable components

supabase/
└── functions/       # AI edge functions
    ├── chat/
    └── explain-question/

db/
└── schema.sql       # Database schema
```

---

## 🗄️ Database Schema

**Core Tables:**
- `profiles` - User profiles with roles
- `departments` - Subject areas
- `papers` - Exam papers
- `questions` - Exam questions
- `options` - Multiple choice options
- `materials` - Study materials
- `attempts` - Exam attempts
- `chat_messages` - AI conversation history

**Security:** Row Level Security (RLS) enabled on all tables with role-based access control.

---

## 🔄 Update Process

When you make changes:

```bash
# 1. Test locally
flutter run -d chrome

# 2. Build
flutter build web --release

# 3. Deploy
firebase deploy --only hosting
```

---

## 🎨 Customization

### Update App Name
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

### Update Theme
- `lib/theme/app_colors.dart`
- `lib/theme/app_theme.dart`

### Add Custom Domain (Optional)
1. Firebase Console → Hosting → Add custom domain
2. Follow DNS configuration steps
3. Free SSL auto-provisioned

---

## 🐛 Troubleshooting

**"Failed to load data"**
- Verify Supabase credentials in `supabase_config.dart`
- Check Supabase project is not paused

**"AI chat not working"**
- Verify `GEMINI_API_KEY` set in Supabase secrets
- Check edge functions deployed: Dashboard → Edge Functions

**"Admin tab not visible"**
- Ensure user role is `admin` in profiles table
- Restart app after role change

**"Build fails"**
```bash
flutter clean
flutter pub get
flutter build web --release
```

**"Deployed but showing old version"**
- Clear browser cache or use incognito mode
- Or redeploy: `firebase deploy --only hosting`

---

## 📱 Build Mobile Apps

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS (requires Mac)
```bash
flutter build ios --release
flutter build ipa --release
```

---

## 🧪 Testing

```bash
# Run tests
flutter test

# Code analysis
flutter analyze

# Coverage
flutter test --coverage
```

---

## 💰 Cost Breakdown

**Supabase (Free Tier):**
- 500MB database
- 2GB bandwidth/month
- 2GB file storage
- Edge functions: 500K invocations

**Firebase (Free Tier):**
- 10GB storage
- 360MB/day bandwidth
- Custom domain with SSL

**Google Gemini:**
- 60 requests/minute free
- Pay-as-you-go after

**Total to Start:** $0/month

---

## 📊 Monitoring

**Supabase Dashboard:**
- Database usage
- Edge function logs
- Authentication activity

**Firebase Console:**
- Hosting analytics
- Traffic statistics
- Performance monitoring

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/Feature`)
3. Commit changes (`git commit -m 'Add Feature'`)
4. Push to branch (`git push origin feature/Feature`)
5. Open Pull Request

**Standards:**
- Follow Dart style guide
- Run `flutter analyze` before committing
- Write tests for new features

---

## 📄 License

This project is licensed under the MIT License.

---

## 🙏 Acknowledgments

- Flutter team for the framework
- Supabase for backend infrastructure
- Google for Gemini API
- Material Design for UI guidelines

---

## 📞 Support

- **Documentation:** Check this README
- **Issues:** Open on GitHub
- **Supabase Logs:** Dashboard → Edge Functions → Logs
- **Firebase Logs:** Console → Hosting

---

## 🗺️ Roadmap

- [ ] Offline mode with caching
- [ ] Push notifications
- [ ] Leaderboards
- [ ] Export results to PDF
- [ ] Question bookmarking
- [ ] Dark mode
- [ ] Multi-language support
- [ ] Advanced analytics

---

**Built with ❤️ using Flutter and Supabase**

**Live Demo:** `https://your-project.web.app`
