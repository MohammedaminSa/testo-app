import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../data/demo_quizzes.dart';
import '../models/models.dart';
import '../services/progress_service.dart';
import '../services/quiz_service.dart';
import 'history_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

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

  Future<void> _loadQuizzes() async {
    if (!AppConfig.isConfigured) {
      setState(() {
        _quizzes = DemoQuizzes.quizzes;
        _loadingQuizzes = false;
        _quizError = false;
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
      if (mounted) {
        setState(() {
          _loadingQuizzes = false;
          _quizError = true;
        });
      }
    }
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final attempts = await _progressService.fetchAttempts();
      final stats = await _progressService.fetchStats(attempts);
      if (mounted) {
        setState(() {
          _stats = stats;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
  }

  void _startQuiz(Quiz quiz) async {
    final correctCount = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => QuizScreen(quiz: quiz)),
    );
    if (correctCount != null) {
      _saveAttempt(quiz, correctCount);
    }
    _loadStats();
  }

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
      await _progressService.saveAttempt(attempt);
      if (mounted) _showResultDialog(attempt);
    } catch (_) {
      if (mounted) _showResultDialog(attempt, saved: false);
    }
  }

  void _showResultDialog(QuizAttempt attempt, {bool saved = true}) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score: ${attempt.scorePercent.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${attempt.correctAnswers} of ${attempt.totalQuestions} correct',
            ),
            if (!saved) ...[
              const SizedBox(height: 8),
              const Text(
                'Note: result could not be saved to the cloud yet.',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testo'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadStats(), _loadQuizzes()]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Learn. Practice. Pass.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pick a quiz and track your progress.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _buildStatsCard(),
            const SizedBox(height: 24),
            const Text(
              'Available Quizzes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._buildQuizCards(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_loadingStats) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final avgScore = (_stats['avgScore'] as double?) ?? 0;
    final bestScore = (_stats['bestScore'] as double?) ?? 0;
    final attempts = _stats['totalAttempts'] as int? ?? 0;
    final quizzesTaken = _stats['quizzesTaken'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'Your Progress',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _statItem('Avg Score', '${avgScore.toStringAsFixed(0)}%'),
                _statItem('Best Score', '${bestScore.toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statItem('Attempts', '$attempts'),
                _statItem('Quizzes', '$quizzesTaken'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildQuizCards() {
    if (_loadingQuizzes) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_quizError) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.black38),
                const SizedBox(height: 12),
                const Text(
                  'Could not load quizzes.\nCheck your connection and try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loadQuizzes,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    return (_quizzes ?? const <Quiz>[]).map(_buildQuizCard).toList();
  }

  Widget _buildQuizCard(Quiz quiz) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: AppTheme.primary,
          child: Icon(Icons.quiz, color: Colors.white),
        ),
        title: Text(
          quiz.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(quiz.description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _startQuiz(quiz),
      ),
    );
  }
}
