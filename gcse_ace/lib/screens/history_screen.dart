import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/attempt.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return AppScaffold(
      appBar: const GlassAppBar(title: Text('History')),
      body: userAsync.when(
        loading: () => const LoadingState(label: 'Loading history...'),
        error: (e, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Something went wrong',
          subtitle: 'We could not load your history.',
          gradient: AppColors.ember,
        ),
        data: (user) {
          if (user == null) {
            return const EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Please sign in',
              subtitle: 'Sign in to see your past attempts.',
              gradient: AppColors.sunset,
            );
          }

          final attemptsAsync = ref.watch(attemptsProvider(user.id));

          return attemptsAsync.when(
            loading: () => const LoadingState(label: 'Loading history...'),
            error: (e, _) => EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Could not load history',
              subtitle: 'Check your connection and try again.',
              gradient: AppColors.ember,
            ),
            data: (attempts) {
              if (attempts.isEmpty) {
                return const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No attempts yet',
                  subtitle:
                      'Take a mock exam and every score will be logged here.',
                  gradient: AppColors.mint,
                );
              }

              final completed = attempts.where((a) => a.isCompleted).toList();
              final average = completed.isEmpty
                  ? 0.0
                  : completed.fold<double>(0, (s, a) => s + a.percentage) /
                        completed.length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Row(
                    children: [
                      _SummaryCard(
                        value: '${attempts.length}',
                        label: 'Attempts',
                        gradient: AppColors.brand,
                      ),
                      const SizedBox(width: 12),
                      _SummaryCard(
                        value: '${completed.length}',
                        label: 'Completed',
                        gradient: AppColors.mint,
                      ),
                      const SizedBox(width: 12),
                      _SummaryCard(
                        value: '${average.toStringAsFixed(0)}%',
                        label: 'Average',
                        gradient: AppColors.sunset,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  for (var i = 0; i < attempts.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AttemptCard(
                        attempt: attempts[i],
                        accent: AppColors.accentFor(i),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.value,
    required this.label,
    required this.gradient,
  });

  final String value;
  final String label;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttemptCard extends StatelessWidget {
  const _AttemptCard({required this.attempt, required this.accent});

  final Attempt attempt;
  final Gradient accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = attempt.percentage;
    final gradient = pct >= 70
        ? AppColors.mint
        : pct >= 50
        ? AppColors.sunset
        : AppColors.ember;
    final date = DateFormat('d MMM yyyy • h:mm a').format(attempt.startedAt);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: attempt.isCompleted
                  ? gradient
                  : const LinearGradient(
                      colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                    ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: attempt.isCompleted
                ? Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : const Icon(
                    Icons.hourglass_bottom_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.paperTitle ?? 'Unknown paper',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  attempt.departmentName ?? 'Practice',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(date, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (attempt.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accent.colors.first.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${attempt.score}/${attempt.totalMarks}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accent.colors.first,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'In progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
