import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';

class PapersScreen extends ConsumerStatefulWidget {
  const PapersScreen({super.key});

  @override
  ConsumerState<PapersScreen> createState() => _PapersScreenState();
}

class _PapersScreenState extends ConsumerState<PapersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentsProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: const GlassAppBar(title: Text('Papers')),
      body: departmentsAsync.when(
        loading: () => const LoadingState(label: 'Loading subjects...'),
        error: (e, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Something went wrong',
          subtitle: 'We could not load your subjects. Pull to retry.',
          gradient: AppColors.ember,
        ),
        data: (departments) {
          final query = _query.trim().toLowerCase();
          final filtered = query.isEmpty
              ? departments
              : departments
                    .where(
                      (d) =>
                          d.name.toLowerCase().contains(query) ||
                          (d.description ?? '').toLowerCase().contains(query),
                    )
                    .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text(
                'Pick a subject to browse its past papers and mock exams.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search subjects',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() => _query = ''),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              if (departments.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: EmptyState(
                    icon: Icons.school_rounded,
                    title: 'No subjects yet',
                    subtitle: 'Subjects appear here once they are added.',
                  ),
                )
              else if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    subtitle: 'Try a different subject name.',
                    gradient: AppColors.sunset,
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final dept = filtered[index];
                    return GlassCard(
                      padding: const EdgeInsets.all(16),
                      radius: 24,
                      onTap: () => context.push('/department/${dept.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GradientIcon(
                            icon: Icons.menu_book_rounded,
                            size: 48,
                            iconSize: 23,
                            gradient: AppColors.accentFor(index),
                          ),
                          const Spacer(),
                          Text(
                            dept.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dept.description ?? 'Past papers',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
