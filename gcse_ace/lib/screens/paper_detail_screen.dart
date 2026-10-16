import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class PaperDetailScreen extends ConsumerWidget {
  const PaperDetailScreen({super.key, required this.paperId});

  final String paperId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = ref.watch(papersProvider(null));
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: const GlassAppBar(title: Text('Paper details')),
      body: papersAsync.when(
        loading: () => const LoadingState(label: 'Loading paper...'),
        error: (e, _) => const EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load this paper',
          gradient: AppColors.ember,
        ),
        data: (papers) {
          final paper = papers.where((p) => p.id == paperId).firstOrNull;
          if (paper == null) {
            return const EmptyState(
              icon: Icons.description_outlined,
              title: 'Paper not found',
              subtitle: 'It may have been removed.',
              gradient: AppColors.sunset,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${paper.year} PAPER',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      paper.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Timed • ${paper.durationMinutes} minutes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _SpecTile(
                    icon: Icons.calendar_today_rounded,
                    value: '${paper.year}',
                    label: 'Year',
                    gradient: AppColors.brand,
                  ),
                  const SizedBox(width: 12),
                  _SpecTile(
                    icon: Icons.timer_outlined,
                    value: '${paper.durationMinutes}',
                    label: 'Minutes',
                    gradient: AppColors.mint,
                  ),
                  const SizedBox(width: 12),
                  _SpecTile(
                    icon: Icons.stars_rounded,
                    value: '${paper.totalMarks}',
                    label: 'Marks',
                    gradient: AppColors.sunset,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              GlassCard(
                radius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What to expect', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 14),
                    _ExpectRow(
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                      text:
                          'Questions are graded instantly when you submit.',
                    ),
                    const SizedBox(height: 10),
                    _ExpectRow(
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                      text:
                          'Wrong answers can be explained by AI, step by step.',
                    ),
                    const SizedBox(height: 10),
                    _ExpectRow(
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                      text: 'The timer auto-submits if you run out of time.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                onPressed: () => context.push('/exam/${paper.id}'),
                icon: Icons.play_arrow_rounded,
                child: const Text('Start exam'),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                radius: 18,
                onTap: () => context.pop(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Back to papers',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SpecTile extends StatelessWidget {
  const _SpecTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
  });

  final IconData icon;
  final String value;
  final String label;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        radius: 22,
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 17, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ExpectRow extends StatelessWidget {
  const _ExpectRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
