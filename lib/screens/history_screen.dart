import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../providers/progress_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptsAsync = ref.watch(attemptsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: attemptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _buildError(context, ref),
        data: (attempts) => _buildList(context, ref, attempts),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(attemptsProvider.future),
      child: ListView(
        children: const [
          SizedBox(height: 140),
          Icon(Icons.cloud_off, size: 64, color: Colors.black26),
          SizedBox(height: 16),
          Center(
            child: Text(
              'Could not load your history.\nPull to try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<QuizAttempt> attempts,
  ) {
    if (attempts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.refresh(attemptsProvider.future),
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Icon(Icons.history, size: 64, color: Colors.black26),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No attempts yet.\nComplete a quiz to see it here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.refresh(attemptsProvider.future),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: attempts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final attempt = attempts[index];
          final passed = attempt.scorePercent >= 50;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: passed
                    ? AppTheme.success.withValues(alpha: 0.15)
                    : AppTheme.error.withValues(alpha: 0.15),
                child: Icon(
                  passed ? Icons.check : Icons.close,
                  color: passed ? AppTheme.success : AppTheme.error,
                ),
              ),
              title: Text(
                attempt.quizTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${attempt.correctAnswers}/${attempt.totalQuestions} correct\n'
                '${_formatDate(attempt.completedAt)}',
              ),
              trailing: Text(
                '${attempt.scorePercent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final months = const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }
}