import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../services/progress_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _progressService = ProgressService();
  late Future<List<QuizAttempt>> _attempts;

  @override
  void initState() {
    super.initState();
    _attempts = _progressService.fetchAttempts();
  }

  Future<void> _refresh() async {
    setState(() {
      _attempts = _progressService.fetchAttempts();
    });
    await _attempts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: FutureBuilder<List<QuizAttempt>>(
        future: _attempts,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final attempts = snapshot.data ?? [];
          if (attempts.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
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
            onRefresh: _refresh,
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
