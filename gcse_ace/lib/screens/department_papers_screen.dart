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

class DepartmentPapersScreen extends ConsumerStatefulWidget {
  const DepartmentPapersScreen({
    super.key,
    required this.departmentId,
    this.department,
  });

  final String departmentId;
  final Department? department;

  @override
  ConsumerState<DepartmentPapersScreen> createState() => _DepartmentPapersScreenState();
}

class _DepartmentPapersScreenState extends ConsumerState<DepartmentPapersScreen> {
  String _filterType = 'all'; // 'all', 'mock', 'exit_exam'

  @override
  Widget build(BuildContext context) {
    final deptsAsync = ref.watch(departmentsProvider);
    final resolvedDept = widget.department ??
        deptsAsync.value?.where((d) => d.id == widget.departmentId).firstOrNull;

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
                            'Past papers, mock exams and exit exams',
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
          const SizedBox(height: 20),
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

              final mockCount = papers.where((p) => p.isMockExam).length;
              final exitCount = papers.where((p) => p.isExitExam).length;

              final filteredPapers = papers.where((p) {
                if (_filterType == 'mock') return p.isMockExam;
                if (_filterType == 'exit_exam') return p.isExitExam;
                return true;
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterPill(
                          label: 'All (${papers.length})',
                          selected: _filterType == 'all',
                          onTap: () => setState(() => _filterType = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: 'Mock Exams ($mockCount)',
                          selected: _filterType == 'mock',
                          onTap: () => setState(() => _filterType = 'mock'),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: 'Exit Exams ($exitCount)',
                          selected: _filterType == 'exit_exam',
                          onTap: () => setState(() => _filterType = 'exit_exam'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredPapers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: EmptyState(
                        icon: Icons.filter_alt_off_rounded,
                        title: 'No exams found',
                        subtitle: 'No papers found in this category.',
                        gradient: AppColors.sunset,
                      ),
                    )
                  else
                    for (var i = 0; i < filteredPapers.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _PaperCard(
                          paper: filteredPapers[i],
                          accent: AppColors.accentFor(i),
                          onTap: () => context.push('/paper/${filteredPapers[i].id}'),
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

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E6F5)),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: paper.isExitExam
                            ? Colors.amber.withValues(alpha: 0.2)
                            : AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            paper.isExitExam
                                ? Icons.workspace_premium_rounded
                                : Icons.quiz_outlined,
                            size: 11,
                            color: paper.isExitExam ? Colors.amber[800] : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            paper.examTypeDisplay.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: paper.isExitExam ? Colors.amber[800] : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (paper.courseName != null && paper.courseName!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          paper.courseName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
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
