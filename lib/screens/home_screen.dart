import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../data/demo_quizzes.dart';
import '../models/models.dart';
import '../services/progress_service.dart';
import '../services/quiz_service.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';
import 'review_screen.dart';

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
  String? _difficultyFilter;

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

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _startQuiz(Quiz quiz) async {
    final result = await Navigator.of(context).push<QuizResult>(
      MaterialPageRoute(builder: (_) => QuizScreen(quiz: quiz)),
    );
    if (result == null || !mounted) return;

    final attempt = QuizAttempt(
      quizId: quiz.id,
      quizTitle: quiz.title,
      totalQuestions: result.totalQuestions,
      correctAnswers: result.correctCount,
      scorePercent: result.scorePercent,
      questionsOrder: result.questionsOrder,
      answers: result.answers,
      completedAt: DateTime.now(),
    );

    var saved = false;
    try {
      await _progressService.saveAttempt(attempt);
      saved = true;
    } catch (_) {
      // Never block the user on a failed save.
    }
    _loadStats();

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewScreen(quiz: quiz, result: result),
      ),
    );

    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Result could not be saved to the cloud yet.'),
        ),
      );
    }
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
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: _openProfile,
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
            if (!_loadingQuizzes && !_quizError) _buildFilterRow(),
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
    final weakTopics = (_stats['weakTopics'] as List?) ?? const <String>[];

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
            if (weakTopics.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Topics to review',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: weakTopics
                    .map((t) => Chip(
                          label: Text(t),
                          backgroundColor:
                              Colors.orange.withValues(alpha: 0.12),
                          side: BorderSide(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
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

  Widget _buildFilterRow() {
    final difficulties = (_quizzes ?? const <Quiz>[])
        .map((q) => q.difficulty)
        .toSet()
        .toList()
      ..sort();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _difficultyFilter == null,
            onSelected: (_) => setState(() => _difficultyFilter = null),
          ),
          ...difficulties.map(
            (d) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(d),
                selected: _difficultyFilter == d,
                onSelected: (_) => setState(() => _difficultyFilter = d),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Quiz> get _visibleQuizzes {
    final all = _quizzes ?? const <Quiz>[];
    if (_difficultyFilter == null) return all;
    return all.where((q) => q.difficulty == _difficultyFilter).toList();
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
    final quizzes = _visibleQuizzes;
    if (quizzes.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'No quizzes match this filter.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      ];
    }
    return quizzes.map(_buildQuizCard).toList();
  }

  Widget _buildQuizCard(Quiz quiz) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _startQuiz(quiz),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: Icon(Icons.quiz, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quiz.description,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _badge(quiz.difficulty, AppTheme.primary),
                        _badge(quiz.category, Colors.black54),
                        ...quiz.tags
                            .take(2)
                            .map((t) => _badge(t, Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}