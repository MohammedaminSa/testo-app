import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/attempt.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    final attemptsAsync = ref.watch(attemptsProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Signed in as:', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            user.email ?? 'Unknown',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          attemptsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (attempts) => _StatsSection(attempts: attempts),
          ),
          const SizedBox(height: 24),
          attemptsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (attempts) => _AttemptHistory(attempts: attempts),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () async {
              await AuthService.instance.signOut();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final List<Attempt> attempts;

  const _StatsSection({required this.attempts});

  @override
  Widget build(BuildContext context) {
    final completedAttempts = attempts.where((a) => a.isCompleted).toList();
    final totalAttempts = completedAttempts.length;

    double averageScore = 0;
    if (totalAttempts > 0) {
      final totalPercentage = completedAttempts.fold<double>(
        0,
        (sum, a) => sum + a.percentage,
      );
      averageScore = totalPercentage / totalAttempts;
    }

    final bestScore = totalAttempts > 0
        ? completedAttempts.map((a) => a.percentage).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Stats',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Total Exams',
                  value: totalAttempts.toString(),
                ),
                _StatItem(
                  label: 'Average',
                  value: '${averageScore.toStringAsFixed(1)}%',
                ),
                _StatItem(
                  label: 'Best Score',
                  value: '${bestScore.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _AttemptHistory extends StatelessWidget {
  final List<Attempt> attempts;

  const _AttemptHistory({required this.attempts});

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No exam attempts yet'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Attempts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...attempts.take(10).map((attempt) => _AttemptTile(attempt: attempt)),
          ],
        ),
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  final Attempt attempt;

  const _AttemptTile({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final date = dateFormat.format(attempt.startedAt);
    final time = timeFormat.format(attempt.startedAt);

    final Color scoreColor;
    if (attempt.percentage >= 70) {
      scoreColor = Colors.green;
    } else if (attempt.percentage >= 50) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.paperTitle ?? 'Unknown Paper',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${attempt.departmentName ?? "Unknown"} • $date at $time',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (attempt.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${attempt.score}/${attempt.totalMarks}',
                style: TextStyle(
                  color: scoreColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const Text(
              'Incomplete',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
