import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class PaperManagementScreen extends ConsumerWidget {
  const PaperManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(departmentsProvider);
    final papersAsync = ref.watch(papersAllProvider);

    return AppScaffold(
      appBar: GlassAppBar(
        title: const Text('Papers'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GradientButton(
              onPressed: () => context.push('/admin/papers/add'),
              expanded: false,
              icon: Icons.add_rounded,
              child: const Text('Add'),
            ),
          ),
        ],
      ),
      body: departmentsAsync.when(
        loading: () => const LoadingState(label: 'Loading departments...'),
        error: (e, _) => Center(child: Text('Error loading departments: $e')),
        data: (departments) {
          return papersAsync.when(
            loading: () => const LoadingState(label: 'Loading papers...'),
            error: (e, _) => Center(child: Text('Error loading papers: $e')),
            data: (papers) {
              if (papers.isEmpty) {
                return const Center(
                  child: Text('No papers yet. Add one using the button above.'),
                );
              }
              final deptMap = {for (var d in departments) d.id: d.name};
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                itemCount: papers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final paper = papers[index];
                  final deptName = deptMap[paper.departmentId] ?? 'Unknown';
                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    radius: 16,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                paper.title,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$deptName • ${paper.year} • ${paper.durationMinutes} min • ${paper.totalMarks} marks',
                                style: TextStyle(color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                              onPressed: () => context.push('/admin/papers/${paper.id}/edit'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                              onPressed: () => _confirmDelete(context, ref, paper.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String paperId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Paper'),
        content: const Text('Are you sure you want to delete this paper? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(dataServiceProvider).deletePaper(paperId);
              if (context.mounted) {
                context.pop();
                ref.invalidate(papersAllProvider);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}