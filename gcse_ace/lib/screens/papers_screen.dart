import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/data_provider.dart';

class PapersScreen extends ConsumerWidget {
  const PapersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Departments')),
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
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.book)),
                  title: Text(dept.name),
                  subtitle: Text(dept.description ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
