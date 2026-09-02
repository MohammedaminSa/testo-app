import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/data_provider.dart';

class PaperDetailScreen extends ConsumerWidget {
  const PaperDetailScreen({super.key, required this.paperId});

  final String paperId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = ref.watch(papersProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Paper Details')),
      body: papersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (papers) {
          final paper = papers.where((p) => p.id == paperId).firstOrNull;
          if (paper == null) {
            return const Center(child: Text('Paper not found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                paper.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _InfoRow(icon: Icons.calendar_today, label: '${paper.year}'),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.timer,
                label: '${paper.durationMinutes} minutes',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.star,
                label: '${paper.totalMarks} marks',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    context.push('/exam/$paperId');
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Exam'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
