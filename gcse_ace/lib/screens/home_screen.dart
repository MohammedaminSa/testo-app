import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/attempt.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../shell/app_shell.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final departmentsAsync = ref.watch(departmentsProvider);
    final attemptsAsync = user == null
        ? null
        : ref.watch(attemptsProvider(user.id));

    return AppScaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _Header(greeting: _greeting, email: user?.email),
            const SizedBox(height: 22),
            _HeroCard(
              onStart: () =>
                  ref.read(shellIndexProvider.notifier).state = 1,
            ),
            const SizedBox(height: 26),
            if (attemptsAsync != null)
              attemptsAsync.when(
                loading: () => const _StatsSkeleton(),
                error: (_, _) => const SizedBox.shrink(),
                data: (attempts) => _StatsRow(attempts: attempts),
              ),
            const SizedBox(height: 26),
            SectionTitle(
              title: 'Subjects',
              action: TextButton(
                onPressed: () =>
                    ref.read(shellIndexProvider.notifier).state = 1,
                child: const Text('See all'),
              ),
            ),
            SizedBox(
              height: 132,
              child: departmentsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                error: (_, _) => Text(
                  'Could not load subjects',
                  style: theme.textTheme.bodyMedium,
                ),
                data: (departments) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: departments.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final dept = departments[index];
                    return SizedBox(
                      width: 158,
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        radius: 22,
                        onTap: () => context.push('/department/${dept.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GradientIcon(
                              icon: Icons.library_books_rounded,
                              size: 44,
                              iconSize: 21,
                              gradient: AppColors.accentFor(index),
                            ),
                            const Spacer(),
                            Text(
                              dept.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dept.description ?? 'Past papers & notes',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 26),
            SectionTitle(
              title: 'Recent results',
              action: TextButton(
                onPressed: () => context.push('/history'),
                child: const Text('History'),
              ),
            ),
            if (attemptsAsync == null)
              Text('Sign in to track your progress', style: theme.textTheme.bodyMedium)
            else
              attemptsAsync.when(
                loading: () => const _StatsSkeleton(),
                error: (_, _) => const SizedBox.shrink(),
                data: (attempts) {
                  if (attempts.isEmpty) {
                    return const EmptyState(
                      icon: Icons.emoji_events_outlined,
                      title: 'No results yet',
                      subtitle:
                          'Take your first mock exam and your score will show up here.',
                      gradient: AppColors.mint,
                    );
                  }
                  return Column(
                    children: [
                      for (final attempt in attempts.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AttemptRow(attempt: attempt),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.greeting, required this.email});

  final String greeting;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = (email ?? 'S').characters.first.toUpperCase();

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.brand,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: theme.textTheme.bodyMedium),
              Text(
                email ?? 'Student',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'History',
          onPressed: () => context.push('/history'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.aurora,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -30,
            child: _ring(120, Colors.white.withValues(alpha: 0.14)),
          ),
          Positioned(
            bottom: -60,
            right: 60,
            child: _ring(90, Colors.white.withValues(alpha: 0.1)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'MOCK EXAMS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Revise smarter,\nnot longer.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Timed, exam-style papers with instant grading and AI explanations.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 20),
              GlassButton(
                onPressed: onStart,
                expanded: false,
                onGradient: true,
                icon: Icons.rocket_launch_rounded,
                child: const Text('Start practising'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ring(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
  );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.attempts});

  final List<Attempt> attempts;

  @override
  Widget build(BuildContext context) {
    final completed = attempts.where((a) => a.isCompleted).toList();
    final total = completed.length;

    double average = 0;
    if (total > 0) {
      average =
          completed.fold<double>(0, (sum, a) => sum + a.percentage) / total;
    }
    final best = total > 0
        ? completed
              .map((a) => a.percentage)
              .reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Row(
      children: [
        StatTile(
          value: '$total',
          label: 'Exams taken',
          icon: Icons.checklist_rounded,
          gradient: AppColors.brand,
        ),
        const SizedBox(width: 12),
        StatTile(
          value: '${average.toStringAsFixed(0)}%',
          label: 'Average',
          icon: Icons.insights_rounded,
          gradient: AppColors.mint,
        ),
        const SizedBox(width: 12),
        StatTile(
          value: '${best.toStringAsFixed(0)}%',
          label: 'Best',
          icon: Icons.emoji_events_rounded,
          gradient: AppColors.sunset,
        ),
      ],
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: Container(
              height: 104,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({required this.attempt});

  final Attempt attempt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = attempt.percentage;
    final gradient = pct >= 70
        ? AppColors.mint
        : pct >= 50
        ? AppColors.sunset
        : AppColors.ember;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 22,
      onTap: () => context.push('/history'),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${pct.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.paperTitle ?? 'Practice paper',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  attempt.departmentName == null
                      ? DateFormat('d MMM yyyy').format(attempt.startedAt)
                      : '${attempt.departmentName} • '
                            '${DateFormat('d MMM yyyy').format(attempt.startedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
