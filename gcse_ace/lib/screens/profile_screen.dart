import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/attempt.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);

    if (user == null) {
      return const AppScaffold(
        appBar: GlassAppBar(title: Text('Profile')),
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Not signed in',
          subtitle: 'Sign in to see your stats and attempt history.',
          gradient: AppColors.sunset,
        ),
      );
    }

    final attemptsAsync = ref.watch(attemptsProvider(user.id));

    return AppScaffold(
      appBar: const GlassAppBar(title: Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _IdentityCard(email: user.email ?? 'Student'),
          const SizedBox(height: 20),
          attemptsAsync.when(
            loading: () => const _StatsSkeleton(),
            error: (_, _) => const SizedBox.shrink(),
            data: (attempts) => _StatsSection(attempts: attempts),
          ),
          const SizedBox(height: 24),
          attemptsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (attempts) => _AttemptHistory(attempts: attempts),
          ),
          const SizedBox(height: 24),
          GlassCard(
            radius: 24,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.school_rounded,
                  iconColor: AppColors.primary,
                  title: 'Exam board ready',
                  subtitle: 'Questions are graded locally, instantly.',
                ),
                const Divider(height: 1, indent: 68),
                _InfoTile(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: AppColors.secondary,
                  title: 'AI explanations',
                  subtitle: 'Get any wrong answer broken down step by step.',
                ),
                const Divider(height: 1, indent: 68),
                _InfoTile(
                  icon: Icons.history_rounded,
                  iconColor: AppColors.accent,
                  title: 'Full history',
                  subtitle: 'Every attempt is saved to your account.',
                  onTap: () => context.push('/history'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              await AuthService.instance.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'GCSE Ace',
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = email.characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.aurora,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'SIGNED IN',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.attempts});

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
          label: 'Exams',
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

class _AttemptHistory extends StatelessWidget {
  const _AttemptHistory({required this.attempts});

  final List<Attempt> attempts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (attempts.isEmpty) {
      return GlassCard(
        radius: 24,
        child: Column(
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 42,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text('No attempts yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Your results will show up here after your first exam.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Recent attempts',
          action: TextButton(
            onPressed: () => context.push('/history'),
            child: const Text('See all'),
          ),
        ),
        GlassCard(
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < attempts.take(4).length; i++) ...[
                if (i > 0) const Divider(indent: 64),
                _AttemptTile(attempt: attempts[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({required this.attempt});

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: attempt.isCompleted
                  ? gradient
                  : const LinearGradient(
                      colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                    ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: attempt.isCompleted
                ? Text(
                    pct.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : const Icon(
                    Icons.hourglass_bottom_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 3),
                Text(
                  '${attempt.departmentName ?? 'Practice'} • '
                  '${DateFormat('d MMM yyyy').format(attempt.startedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (attempt.isCompleted)
            Text(
              '${attempt.score}/${attempt.totalMarks}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: gradient.colors.first,
              ),
            )
          else
            Text(
              'In progress',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
