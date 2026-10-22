# Supabase Files Explanation

This document explains each Supabase-related file in your project.

---

## 📂 Files Overview

### ✅ **KEEP - Essential Files**

#### 1. `lib/config/supabase_config.dart`
**Purpose:** Your Flutter app's connection to Supabase  
**What it does:**
- Contains your Supabase project URL: `https://wpxkwxoalubibrnbdejo.supabase.co`
- Contains your publishable API key (public, safe to include)
- Initializes the Supabase client when app starts

**Used by:** Your Flutter app (`main.dart` calls it)

**DO NOT DELETE!** Your app won't connect to database without this.

---

#### 2. `supabase/config.toml`
**Purpose:** Configuration for Supabase CLI  
**What it does:**
- Sets local development ports
- Configures Edge Functions settings
- JWT verification settings

**Used by:** Supabase CLI commands (`supabase functions deploy`)

**Keep this!** Needed to deploy Edge Functions.

---

#### 3. `supabase/functions/chat/index.ts`
**Purpose:** AI chatbot Edge Function  
**What it does:**
- Receives user messages
- Calls Gemini API
- Returns AI responses

**Used by:** Your app's AI Tutor feature

**Keep this!** Your chatbot needs it.

---

#### 4. `supabase/functions/explain-question/index.ts`
**Purpose:** Question explanation Edge Function  
**What it does:**
- Receives exam questions
- Generates educational explanations
- Returns step-by-step reasoning

**Used by:** Your app when showing answer explanations

**Keep this!** Question explanations need it.

---

### ⚠️ **AUTO-GENERATED - Don't Modify**

#### 5. `supabase/.temp/linked-project.json`
**Purpose:** CLI project link cache  
**What it does:**
- Stores which project you're linked to
- Created by `supabase link` command
- Updated automatically

**Should you delete?** No, but it's safe to delete. CLI will recreate it.

---

### 📚 **DOCUMENTATION - Optional but Helpful**

#### 6. `SUPABASE_SETUP_GUIDE.md`
**Purpose:** Setup instructions  
**What it does:**
- Step-by-step database setup
- SQL commands to run
- RLS policies

**Should you delete?** Optional, but helpful for reference!

#### 7. `db/schema.sql`
**Purpose:** Database schema definition  
**What it does:**
- Defines all tables
- Creates RLS policies
- Sets up indexes

**Should you delete?** Keep for reference/rebuilding database.

---

## 🗑️ Files You Can Delete

### Already Deleted ✅

These were created by mistake and have been removed:
- `Created directories/` (empty folder)
- `echo/` (empty folder)
- `mkdir/` (empty folder)
- `$null` (empty file)

---

## 📋 Summary

### **Essential Files (3):**
1. `lib/config/supabase_config.dart` - Flutter app connection
2. `supabase/config.toml` - CLI configuration
3. `supabase/functions/*/index.ts` - Edge Functions (2 files)

### **Optional Files (2):**
1. `SUPABASE_SETUP_GUIDE.md` - Setup instructions
2. `db/schema.sql` - Database schema

### **Auto-Generated (1):**
1. `supabase/.temp/linked-project.json` - CLI cache

---

## 💡 Why Two Supabase Configs?

**Question:** Why do I have `supabase_config.dart` AND `config.toml`?

**Answer:** They serve different purposes!

| File | Used By | Purpose |
|------|---------|---------|
| `lib/config/supabase_config.dart` | **Flutter App** | Connect app to Supabase |
| `supabase/config.toml` | **Supabase CLI** | Deploy functions & manage project |

**Think of it like:**
- `supabase_config.dart` = Your app's "phone number" to call Supabase
- `config.toml` = Your "tools" to build and deploy features

Both are needed! 👍

---

## 🔧 When to Edit These Files

### Edit `lib/config/supabase_config.dart` when:
- ✅ Creating a new Supabase project
- ✅ Changing project URL
- ✅ Updating API keys

### Edit `supabase/config.toml` when:
- ✅ Changing local development ports
- ✅ Adding new Edge Functions
- ✅ Configuring JWT settings

### Edit Edge Function files when:
- ✅ Changing AI behavior
- ✅ Updating prompts
- ✅ Switching AI providers (OpenAI → Gemini)

---

## 🚀 Quick Reference

**Deploy Edge Functions:**
```bash
cd c:\Users\hp\Downloads\testo\gcse_ace
supabase functions deploy chat
```

**Check Project Link:**
```bash
supabase status
```

**View Function Logs:**
```bash
supabase functions logs chat --follow
```

---

Need help understanding any of these files? Just ask! 😊
