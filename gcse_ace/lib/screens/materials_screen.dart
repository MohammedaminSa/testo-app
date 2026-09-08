import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/material.dart';
import '../providers/data_provider.dart';

class MaterialsScreen extends ConsumerWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Study Materials')),
      body: departmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (departments) {
          if (departments.isEmpty) {
            return const Center(child: Text('No departments yet'));
          }
          return ListView.builder(
            itemCount: departments.length,
            itemBuilder: (context, index) {
              final dept = departments[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  leading: const CircleAvatar(child: Icon(Icons.menu_book)),
                  title: Text(dept.name),
                  subtitle: Text(dept.description ?? ''),
                  children: [
                    _MaterialsList(departmentId: dept.id),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MaterialsList extends ConsumerWidget {
  final String departmentId;

  const _MaterialsList({required this.departmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsProvider(departmentId));

    return materialsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error: $e'),
      ),
      data: (materials) {
        if (materials.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No materials available'),
          );
        }
        return Column(
          children: materials.map((m) => _MaterialTile(material: m)).toList(),
        );
      },
    );
  }
}

class _MaterialTile extends StatelessWidget {
  final StudyMaterial material;

  const _MaterialTile({required this.material});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(material.title),
      subtitle: Text(
        material.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showMaterialDetail(context, material);
      },
    );
  }

  void _showMaterialDetail(BuildContext context, StudyMaterial material) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                material.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16.0),
                child: Text(material.content),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
