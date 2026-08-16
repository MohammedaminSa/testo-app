import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../providers/progress_providers.dart';
import '../providers/quiz_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _difficultyFilter;

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(quizListProvider.notifier).refresh(),
      ref.refresh(attemptsProvider.future),
    ]);
  }

  void _startQuiz(Quiz quiz) {
    context.push('/quiz', extra: quiz);
  }

  @override
  Widget build(BuildContext context) {
    final quizzesAsync = ref.watch(quizListProvider);
    final quizzes = quizzesAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Testo'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
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
            if (quizzes != null && quizzes.isNotEmpty) _buildFilterRow(quizzes),
            ..._buildQuizCards(quizzesAsync),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return ref.watch(statsProvider).when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, _) => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Could not load progress.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
          ),
          data: _buildStatsContent,
        );
  }

  Widget _buildStatsContent(Map<String, dynamic> stats) {
    final avgScore = (stats['avgScore'] as double?) ?? 0;
    final bestScore = (stats['bestScore'] as double?) ?? 0;
    final attempts = stats['totalAttempts'] as int? ?? 0;
    final quizzesTaken = stats['quizzesTaken'] as int? ?? 0;
    final weakTopics = (stats['weakTopics'] as List?) ?? const <String>[];

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

  Widget _buildFilterRow(List<Quiz> quizzes) {
    final difficulties = quizzes.map((q) => q.difficulty).toSet().toList()
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

  List<Widget> _buildQuizCards(AsyncValue<List<Quiz>> quizzesAsync) {
    return quizzesAsync.when(
      loading: () => const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (_, _) => [
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
                  onPressed: () =>
                      ref.read(quizListProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
      data: (quizzes) {
        final visible = _filter(quizzes);
        if (visible.isEmpty) {
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
        return visible.map(_buildQuizCard).toList();
      },
    );
  }

  List<Quiz> _filter(List<Quiz> quizzes) {
    if (_difficultyFilter == null) return quizzes;
    return quizzes
        .where((q) => q.difficulty == _difficultyFilter)
        .toList();
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