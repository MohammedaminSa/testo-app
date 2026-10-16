# Supabase Database Setup Guide for Exam Practice App

This guide will help you set up your Supabase database from scratch with actual university-level data.

## Step 1: Create/Verify Your Supabase Project

1. Go to https://app.supabase.com
2. Sign in or create an account
3. Check if your project `wpxkwxoalubibrnbdejo` exists
   - If it exists but is paused, click "Restore project"
   - If it doesn't exist, create a new project and update `lib/config/supabase_config.dart` with new credentials

## Step 2: Create Database Tables

Go to your Supabase Dashboard → SQL Editor and run these commands **one by one**:

### 2.1 Enable UUID Extension (Required for Auto-Generated IDs)

**What this does:** Enables automatic generation of unique IDs (UUIDs) for your database records. Without this, you can't use `uuid_generate_v4()` in the next steps.

**How to do it:**
1. Go to Supabase Dashboard → **SQL Editor**
2. Click **"New Query"**
3. Copy and paste this exact code:

```sql
-- Enable UUID generation (Universal Unique Identifier)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

4. Click **"Run"** (or press Ctrl+Enter)
5. You should see: ✅ **"Success. No rows returned"**

**What is UUID?**
- UUID = Universal Unique Identifier
- Example: `d1111111-1111-1111-1111-111111111111`
- It's a unique ID that looks like: 8 digits - 4 digits - 4 digits - 4 digits - 12 digits
- Every record in your database will get a unique ID automatically

**Why do we need this?**
Instead of manually creating IDs like `1, 2, 3...`, PostgreSQL will automatically generate unique IDs like:
- `a7f3bc21-4f8e-4d2a-9c1b-7e3d4f5a6b8c`
- `f2e9d8c7-6b5a-4f3e-2d1c-0b9a8e7d6c5b`

This ensures no two records ever have the same ID, even across different tables or databases.

### 2.2 Create Departments Table
```sql
CREATE TABLE departments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2.3 Create Papers Table
```sql
CREATE TABLE papers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  year INTEGER NOT NULL,
  duration_minutes INTEGER NOT NULL,
  total_marks INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2.4 Create Questions Table
```sql
CREATE TABLE questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  paper_id UUID NOT NULL REFERENCES papers(id) ON DELETE CASCADE,
  order_number INTEGER NOT NULL,
  text TEXT NOT NULL,
  marks INTEGER NOT NULL DEFAULT 1,
  question_type TEXT NOT NULL CHECK (question_type IN ('multiple-choice', 'written')),
  correct_answer TEXT,
  explanation TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2.5 Create Options Table (for MCQs)
```sql
CREATE TABLE options (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  letter TEXT NOT NULL CHECK (letter IN ('A', 'B', 'C', 'D', 'E', 'F')),
  text TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2.6 Create Study Materials Table
```sql
CREATE TABLE materials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2.7 Create Attempts Table
```sql
CREATE TABLE attempts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  paper_id UUID NOT NULL REFERENCES papers(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  submitted_at TIMESTAMPTZ,
  score INTEGER,
  total_marks INTEGER NOT NULL,
  answers JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Step 3: Set Up Row Level Security (RLS)

Run these commands to enable RLS and create policies:

### 3.1 Enable RLS on All Tables
```sql
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE papers ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE options ENABLE ROW LEVEL SECURITY;
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE attempts ENABLE ROW LEVEL SECURITY;
```

### 3.2 Create Public Read Policies (anyone can view content)
```sql
-- Departments: Public read
CREATE POLICY "Anyone can view departments"
  ON departments FOR SELECT
  USING (true);

-- Papers: Public read
CREATE POLICY "Anyone can view papers"
  ON papers FOR SELECT
  USING (true);

-- Questions: Public read
CREATE POLICY "Anyone can view questions"
  ON questions FOR SELECT
  USING (true);

-- Options: Public read
CREATE POLICY "Anyone can view options"
  ON options FOR SELECT
  USING (true);

-- Materials: Public read
CREATE POLICY "Anyone can view materials"
  ON materials FOR SELECT
  USING (true);
```

### 3.3 Create Attempts Policies (users can only see their own)
```sql
-- Users can view their own attempts
CREATE POLICY "Users can view own attempts"
  ON attempts FOR SELECT
  USING (auth.uid() = user_id);

-- Users can create their own attempts
CREATE POLICY "Users can create own attempts"
  ON attempts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own attempts
CREATE POLICY "Users can update own attempts"
  ON attempts FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

## Step 4: Insert Sample Data

Now let's add actual university-level content:

### 4.1 Insert Departments
```sql
INSERT INTO departments (id, name, slug, description) VALUES
  ('d1111111-1111-1111-1111-111111111111', 'Computer Science', 'computer-science', 'Algorithms, Data Structures, Theory of Computation'),
  ('d2222222-2222-2222-2222-222222222222', 'Software Engineering', 'software-engineering', 'Software Design, Development, Testing, Project Management'),
  ('d3333333-3333-3333-3333-333333333333', 'Information Technology', 'information-technology', 'Networks, Database Systems, Web Technologies'),
  ('d4444444-4444-4444-4444-444444444444', 'Data Science', 'data-science', 'Machine Learning, Statistics, Data Analytics'),
  ('d5555555-5555-5555-5555-555555555555', 'Cybersecurity', 'cybersecurity', 'Network Security, Cryptography, Ethical Hacking'),
  ('d6666666-6666-6666-6666-666666666666', 'Artificial Intelligence', 'artificial-intelligence', 'Neural Networks, NLP, Computer Vision');
```

### 4.2 Insert Sample Papers
```sql
-- Computer Science Papers
INSERT INTO papers (id, department_id, title, year, duration_minutes, total_marks) VALUES
  ('p1111111-1111-1111-1111-111111111111', 'd1111111-1111-1111-1111-111111111111', 'Data Structures & Algorithms - Midterm', 2024, 120, 100),
  ('p1111112-1111-1111-1111-111111111111', 'd1111111-1111-1111-1111-111111111111', 'Operating Systems - Final Exam', 2024, 180, 150);

-- Software Engineering Papers
INSERT INTO papers (id, department_id, title, year, duration_minutes, total_marks) VALUES
  ('p2222221-2222-2222-2222-222222222222', 'd2222222-2222-2222-2222-222222222222', 'Software Design Patterns', 2024, 120, 100);

-- IT Papers
INSERT INTO papers (id, department_id, title, year, duration_minutes, total_marks) VALUES
  ('p3333331-3333-3333-3333-333333333333', 'd3333333-3333-3333-3333-333333333333', 'Computer Networks', 2024, 120, 100);
```

### 4.3 Insert Sample Questions (Computer Science)
```sql
-- Question 1: Multiple Choice
INSERT INTO questions (id, paper_id, order_number, text, marks, question_type, correct_answer, explanation) VALUES
  ('q1111111-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111111', 1, 'What is the time complexity of searching for an element in a balanced Binary Search Tree?', 2, 'multiple-choice', 'B', 'In a balanced BST, search operations take O(log n) time due to the tree height being logarithmic');

-- Options for Question 1
INSERT INTO options (question_id, letter, text, is_correct) VALUES
  ('q1111111-1111-1111-1111-111111111111', 'A', 'O(n)', false),
  ('q1111111-1111-1111-1111-111111111111', 'B', 'O(log n)', true),
  ('q1111111-1111-1111-1111-111111111111', 'C', 'O(1)', false),
  ('q1111111-1111-1111-1111-111111111111', 'D', 'O(n²)', false);

-- Question 2: Multiple Choice
INSERT INTO questions (id, paper_id, order_number, text, marks, question_type, correct_answer, explanation) VALUES
  ('q1111112-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111111', 2, 'Which data structure uses LIFO (Last In First Out) principle?', 2, 'multiple-choice', 'C', 'Stack follows LIFO principle where the last element added is the first to be removed');

-- Options for Question 2
INSERT INTO options (question_id, letter, text, is_correct) VALUES
  ('q1111112-1111-1111-1111-111111111111', 'A', 'Queue', false),
  ('q1111112-1111-1111-1111-111111111111', 'B', 'Linked List', false),
  ('q1111112-1111-1111-1111-111111111111', 'C', 'Stack', true),
  ('q1111112-1111-1111-1111-111111111111', 'D', 'Tree', false);

-- Question 3: Written Question
INSERT INTO questions (id, paper_id, order_number, text, marks, question_type, explanation) VALUES
  ('q1111113-1111-1111-1111-111111111111', 'p1111111-1111-1111-1111-111111111111', 3, 'Explain the difference between Stack and Queue data structures with real-world examples.', 10, 'written', 'Stack: LIFO (browser history, undo/redo). Queue: FIFO (printer queue, customer service). Stack allows operations at one end, Queue at both ends.');
```

### 4.4 Insert Sample Questions (Software Engineering & Networks)
```sql
-- Software Engineering Question
INSERT INTO questions (id, paper_id, order_number, text, marks, question_type, correct_answer, explanation) VALUES
  ('q2222211-2222-2222-2222-222222222222', 'p2222221-2222-2222-2222-222222222222', 1, 'Which design pattern ensures a class has only one instance?', 2, 'multiple-choice', 'B', 'Singleton pattern restricts instantiation to one object');

INSERT INTO options (question_id, letter, text, is_correct) VALUES
  ('q2222211-2222-2222-2222-222222222222', 'A', 'Factory', false),
  ('q2222211-2222-2222-2222-222222222222', 'B', 'Singleton', true),
  ('q2222211-2222-2222-2222-222222222222', 'C', 'Observer', false),
  ('q2222211-2222-2222-2222-222222222222', 'D', 'Strategy', false);

-- Networks Question
INSERT INTO questions (id, paper_id, order_number, text, marks, question_type, correct_answer, explanation) VALUES
  ('q3333311-3333-3333-3333-333333333333', 'p3333331-3333-3333-3333-333333333333', 1, 'What layer of the OSI model is responsible for routing?', 2, 'multiple-choice', 'C', 'Network layer (Layer 3) handles routing and logical addressing');

INSERT INTO options (question_id, letter, text, is_correct) VALUES
  ('q3333311-3333-3333-3333-333333333333', 'A', 'Physical Layer', false),
  ('q3333311-3333-3333-3333-333333333333', 'B', 'Data Link Layer', false),
  ('q3333311-3333-3333-3333-333333333333', 'C', 'Network Layer', true),
  ('q3333311-3333-3333-3333-333333333333', 'D', 'Transport Layer', false);
```

### 4.5 Insert Study Materials
```sql
-- Computer Science Study Material
INSERT INTO materials (department_id, title, content) VALUES
  ('d1111111-1111-1111-1111-111111111111', 'Data Structures Fundamentals', 
   E'# Data Structures Fundamentals\n\n## Arrays\n- Fixed size, contiguous memory\n- Access: O(1), Search: O(n), Insert/Delete: O(n)\n\n## Linked Lists\n- Dynamic size, non-contiguous\n- Access: O(n), Insert/Delete at head: O(1)\n\n## Stacks (LIFO)\n- Operations: push(), pop(), peek()\n- Use cases: undo/redo, browser history, expression evaluation\n- All operations: O(1)\n\n## Queues (FIFO)\n- Operations: enqueue(), dequeue(), front()\n- Use cases: task scheduling, BFS, printer queue\n- All operations: O(1)\n\n## Trees\n- Binary Tree: Each node has max 2 children\n- BST: Left < Parent < Right\n- Balanced BST: O(log n) operations\n\n## Hash Tables\n- Key-value pairs\n- Average case: O(1) for insert, delete, search\n- Worst case: O(n) due to collisions'),

  ('d1111111-1111-1111-1111-111111111111', 'Algorithm Complexity',
   E'# Algorithm Complexity Analysis\n\n## Time Complexity Classes\n\n### O(1) - Constant\n- Array access, hash table operations\n- Best possible complexity\n\n### O(log n) - Logarithmic\n- Binary search, balanced tree operations\n- Very efficient for large datasets\n\n### O(n) - Linear\n- Single loop, linear search\n- Acceptable for most cases\n\n### O(n log n) - Linearithmic\n- Merge sort, quick sort (average), heap sort\n- Best achievable for comparison-based sorting\n\n### O(n²) - Quadratic\n- Bubble sort, selection sort, insertion sort\n- Nested loops\n- Avoid for large datasets\n\n### O(2ⁿ) - Exponential\n- Recursive fibonacci, subset generation\n- Only practical for small inputs\n\n## Space Complexity\nMemory used by algorithm, excluding input\n- In-place algorithms: O(1) extra space\n- Recursive algorithms: O(n) call stack');

-- Software Engineering Study Material
INSERT INTO materials (department_id, title, content) VALUES
  ('d2222222-2222-2222-2222-222222222222', 'Design Patterns',
   E'# Common Design Patterns\n\n## Creational Patterns\n\n### Singleton\n- Ensures only one instance exists\n- Global access point\n- Example: Database connection, Logger\n\n### Factory\n- Creates objects without specifying exact class\n- Encapsulates object creation\n- Example: UI element factories\n\n### Builder\n- Constructs complex objects step by step\n- Example: Building documents, meals\n\n## Structural Patterns\n\n### Adapter\n- Makes incompatible interfaces work together\n- Example: Legacy code integration\n\n### Decorator\n- Adds behavior to objects dynamically\n- Example: Adding toppings to coffee\n\n## Behavioral Patterns\n\n### Observer\n- One-to-many dependency\n- When one object changes, dependents notified\n- Example: Event handling, MVC\n\n### Strategy\n- Defines family of algorithms\n- Makes them interchangeable\n- Example: Payment methods, sorting algorithms');

-- IT Study Material
INSERT INTO materials (department_id, title, content) VALUES
  ('d3333333-3333-3333-3333-333333333333', 'OSI Model',
   E'# OSI 7-Layer Model\n\n## 7. Application Layer\n- User interface, network services\n- Protocols: HTTP, FTP, SMTP, DNS\n\n## 6. Presentation Layer\n- Data formatting, encryption, compression\n- Examples: SSL/TLS, JPEG, ASCII\n\n## 5. Session Layer\n- Manages connections between applications\n- Session establishment, maintenance, termination\n\n## 4. Transport Layer\n- End-to-end communication, reliability\n- **TCP**: Reliable, connection-oriented\n- **UDP**: Fast, connectionless\n- Port numbers\n\n## 3. Network Layer\n- **Routing** between networks\n- Logical addressing (IP addresses)\n- Protocols: IP, ICMP, ARP\n\n## 2. Data Link Layer\n- Physical addressing (MAC addresses)\n- Frame creation, error detection\n- Examples: Ethernet, Wi-Fi\n\n## 1. Physical Layer\n- Physical transmission (bits over cable/air)\n- Hardware: cables, hubs, repeaters');
```

## Step 5: Verify Your Data

Run these queries to check your data:

```sql
-- Check departments
SELECT * FROM departments;

-- Check papers count
SELECT d.name, COUNT(p.id) as paper_count
FROM departments d
LEFT JOIN papers p ON d.id = p.department_id
GROUP BY d.name;

-- Check questions count
SELECT p.title, COUNT(q.id) as question_count
FROM papers p
LEFT JOIN questions q ON p.id = q.paper_id
GROUP BY p.title;

-- Check options count
SELECT q.text, COUNT(o.id) as option_count
FROM questions q
LEFT JOIN options o ON q.id = o.question_id
WHERE q.question_type = 'multiple-choice'
GROUP BY q.text;
```

## Step 6: Test From Your App

1. Make sure your device has internet connection
2. Restart your Flutter app
3. Navigate to departments/subjects
4. You should see:
   - 5 departments (Mathematics, English, Biology, Chemistry, Physics)
   - 3 papers total
   - Questions with multiple choice options
   - Study materials for each department

## Step 7: Enable Authentication (Optional)

If you want users to sign up and track their attempts:

```sql
-- This is already done by default in Supabase
-- But you can check auth settings in Dashboard → Authentication
```

In your Flutter app, users can sign up using the auth screens that are already built.

## Troubleshooting

### "Failed host lookup" error
- Check your internet connection
- Verify the Supabase project exists at: https://app.supabase.com
- Make sure the project isn't paused

### "No data showing"
- Run the SELECT queries above to verify data exists
- Check browser console in Supabase for errors
- Verify RLS policies are set correctly

### Need to add more content?
You can add more:
- Departments: Insert into `departments` table
- Papers: Insert into `papers` table with valid `department_id`
- Questions: Insert into `questions` table with valid `paper_id`
- Options: Only for multiple-choice questions
- Study Materials: Insert into `materials` table

## Next Steps

Once you have data:
1. Test the app on your device
2. Try taking a practice paper
3. View study materials
4. Track your progress in attempts

Need more sample questions? Let me know which subject and I'll provide more university-level questions!
