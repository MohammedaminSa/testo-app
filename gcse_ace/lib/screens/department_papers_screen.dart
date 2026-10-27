import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/department.dart';
import '../models/paper.dart';
import '../providers/data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';

class DepartmentPapersScreen extends ConsumerWidget {
  const DepartmentPapersScreen({
    super.key,
    required this.departmentId,
    this.department,
  });

  final String departmentId;
  final Department? department;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(departmentsProvider);
    final resolvedDept = this.department ??
        deptsAsync.value?.where((d) => d.id == departmentId).firstOrNull;

    if (resolvedDept == null) {
      return deptsAsync.when(
        loading: () => const AppScaffold(
          body: LoadingState(label: 'Loading subject...'),
        ),
        error: (e, _) => AppScaffold(
          body: EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Subject not found',
            subtitle: '$e',
            gradient: AppColors.ember,
          ),
        ),
        data: (_) => const AppScaffold(
          body: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Subject not found',
            subtitle: 'This subject does not exist or was removed.',
            gradient: AppColors.sunset,
          ),
        ),
      );
    }

    final department = resolvedDept;
    final papersAsync = ref.watch(papersProvider(department.id));
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: GlassAppBar(title: Text(department.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.brand,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        department.name.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        department.description ??
                            'Past papers and mock exams',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.library_books_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          papersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 60),
              child: LoadingState(label: 'Loading papers...'),
            ),
            error: (_, _) => const Padding(
              padding: EdgeInsets.only(top: 60),
              child: EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Could not load papers',
                subtitle: 'Check your connection and try again.',
                gradient: AppColors.ember,
              ),
            ),
            data: (papers) {
              if (papers.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: EmptyState(
                    icon: Icons.description_outlined,
                    title: 'No papers yet',
                    subtitle: 'Papers for this subject will show up here.',
                    gradient: AppColors.sunset,
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < papers.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _PaperCard(
                        paper: papers[i],
                        accent: AppColors.accentFor(i),
                        onTap: () => context.push('/paper/${papers[i].id}'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({
    required this.paper,
    required this.accent,
    required this.onTap,
  });

  final Paper paper;
  final Gradient accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(18),
      radius: 24,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientIcon(
            icon: Icons.description_rounded,
            size: 48,
            iconSize: 22,
            gradient: accent,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(paper.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MetaChip(
                      icon: Icons.calendar_today_rounded,
                      label: '${paper.year}',
                      color: accent.colors.first,
                    ),
                    MetaChip(
                      icon: Icons.timer_outlined,
                      label: '${paper.durationMinutes} min',
                      color: AppColors.accent,
                    ),
                    MetaChip(
                      icon: Icons.stars_rounded,
                      label: '${paper.totalMarks} marks',
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.arrow_forward_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
