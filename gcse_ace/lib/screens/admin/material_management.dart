import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class MaterialManagementScreen extends ConsumerWidget {
  const MaterialManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(departmentsProvider);
    final materialsAsync = ref.watch(materialsAllProvider);

    return AppScaffold(
      appBar: GlassAppBar(
        title: const Text('Study Materials'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GradientButton(
              onPressed: () => context.push('/admin/materials/add'),
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
          return materialsAsync.when(
            loading: () => const LoadingState(label: 'Loading materials...'),
            error: (e, _) => Center(child: Text('Error loading materials: $e')),
            data: (materials) {
              if (materials.isEmpty) {
                return const Center(
                  child: Text('No materials yet. Add one using the button above.'),
                );
              }
              final deptMap = {for (var d in departments) d.id: d.name};
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                itemCount: materials.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final material = materials[index];
                  final deptName = deptMap[material.departmentId] ?? 'Unknown';
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
                                material.title,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$deptName • ${material.url ?? 'No URL'}',
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
                              onPressed: () => context.push('/admin/materials/${material.id}/edit'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                              onPressed: () => _confirmDelete(context, ref, material.id),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, String materialId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: const Text('Are you sure you want to delete this material? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(dataServiceProvider).deleteMaterial(materialId);
              if (context.mounted) {
                context.pop();
                ref.invalidate(materialsAllProvider);
                ref.invalidate(materialsProvider(null));
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