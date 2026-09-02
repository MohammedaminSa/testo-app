import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/department.dart';
import '../providers/data_provider.dart';

class DepartmentPapersScreen extends ConsumerWidget {
  const DepartmentPapersScreen({super.key, required this.department});

  final Department department;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = ref.watch(papersProvider(department.id));

    return Scaffold(
      appBar: AppBar(title: Text(department.name)),
      body: papersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (papers) {
          if (papers.isEmpty) {
            return const Center(child: Text('No papers yet'));
          }
          return ListView.builder(
            itemCount: papers.length,
            itemBuilder: (context, index) {
              final paper = papers[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.description)),
                  title: Text(paper.title),
                  subtitle: Text(
                    '${paper.year} • ${paper.durationMinutes} min • ${paper.totalMarks} marks',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/paper/${paper.id}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
