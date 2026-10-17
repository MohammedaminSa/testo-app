import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class QuestionManagementScreen extends ConsumerStatefulWidget {
  const QuestionManagementScreen({super.key});

  @override
  ConsumerState<QuestionManagementScreen> createState() => _QuestionManagementScreenState();
}

class _QuestionManagementScreenState extends ConsumerState<QuestionManagementScreen> {
  String? _selectedPaperId;

  @override
  Widget build(BuildContext context) {
    final papersAsync = ref.watch(papersAllProvider);

    return AppScaffold(
      appBar: GlassAppBar(
        title: const Text('Questions'),
        actions: [
          if (_selectedPaperId != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GradientButton(
                onPressed: () => context.push('/admin/questions/add/$_selectedPaperId'),
                expanded: false,
                icon: Icons.add_rounded,
                child: const Text('Add'),
              ),
            ),
        ],
      ),
      body: papersAsync.when(
        loading: () => const LoadingState(label: 'Loading papers...'),
        error: (e, _) => Center(child: Text('Error loading papers: $e')),
        data: (papers) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  radius: 16,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPaperId,
                    decoration: const InputDecoration(
                      labelText: 'Select Paper',
                      prefixIcon: Icon(Icons.description_rounded),
                      isDense: true,
                    ),
                    items: papers.map((paper) {
                      return DropdownMenuItem(
                        value: paper.id,
                        child: Text('${paper.title} (${paper.year})'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedPaperId = value),
                  ),
                ),
              ),
              if (_selectedPaperId != null)
                Expanded(
                  child: _buildQuestionsList(ref, _selectedPaperId!),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionsList(WidgetRef ref, String paperId) {
    final questionsAsync = ref.watch(questionsWithOptionsProvider(paperId));
    return questionsAsync.when(
      loading: () => const LoadingState(label: 'Loading questions...'),
      error: (e, _) => Center(child: Text('Error loading questions: $e')),
      data: (questions) {
        if (questions.isEmpty) {
          return const Center(
            child: Text('No questions yet for this paper. Add one using the button above.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          itemCount: questions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final q = questions[index];
            final correctOption = q.options?.where((o) => o.isCorrect).firstOrNull;
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
                          q.text,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Marks: ${q.marks} • Type: ${q.questionType}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (correctOption != null)
                          Text(
                            'Correct: ${correctOption.letter}) ${correctOption.text}',
                            style: const TextStyle(color: Colors.green),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                        onPressed: () => context.push('/admin/questions/${q.id}/edit'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(context, ref, q.id),
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
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String questionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(dataServiceProvider).deleteQuestion(questionId);
              if (context.mounted) {
                context.pop();
                ref.invalidate(questionsWithOptionsProvider);
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