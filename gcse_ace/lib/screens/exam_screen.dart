import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/paper.dart';
import '../providers/data_provider.dart';
import '../providers/exam_provider.dart';

class ExamScreen extends ConsumerWidget {
  const ExamScreen({super.key, required this.paperId});

  final String paperId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = ref.watch(papersProvider(null));

    return papersAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (papers) {
        final paper = papers.firstWhere(
          (p) => p.id == paperId,
          orElse: () => throw Exception('Paper not found'),
        );
        return _ExamContent(paper: paper);
      },
    );
  }
}

class _ExamContent extends ConsumerStatefulWidget {
  const _ExamContent({required this.paper});

  final Paper paper;

  @override
  ConsumerState<_ExamContent> createState() => _ExamContentState();
}

class _ExamContentState extends ConsumerState<_ExamContent> {
  bool _configured = false;

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsWithOptionsProvider(widget.paper.id));

    return questionsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (questions) {
        final examController = ref.read(examProvider.notifier);

        if (!_configured && questions.isNotEmpty) {
          _configured = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            examController.configure(
              paperId: widget.paper.id,
              questions: questions,
              durationMinutes: widget.paper.durationMinutes,
            );
          });
        }

        final examState = ref.watch(examProvider);

        if (examState.isSubmitted) {
          return _buildResultsScreen(context, examState, examController);
        }

        return _buildExamScreen(context, examState, examController);
      },
    );
  }

  Widget _buildExamScreen(
    BuildContext context,
    ExamState examState,
    ExamController examController,
  ) {
    final question = examState.currentQuestion;
    final selectedOptionId = examState.answers[question.id];
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showExitDialog(context, examController);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.paper.title),
          actions: [
            _TimerBadge(remainingSeconds: examState.remainingSeconds),
          ],
        ),
        body: Column(
          children: [
            _QuestionProgress(
              current: examState.currentIndex + 1,
              total: examState.totalQuestions,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Question ${examState.currentIndex + 1} of ${examState.totalQuestions}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '(${question.marks} ${question.marks == 1 ? 'mark' : 'marks'})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    question.text,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  if (question.options != null)
                    RadioGroup<String>(
                      onChanged: (value) {
                        if (value != null) {
                          examController.selectAnswer(question.id, value);
                        }
                      },
                      child: Column(
                        children: question.options!.map((option) {
                          final isSelected = selectedOptionId == option.id;
                          return Card(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : null,
                            child: RadioListTile<String>(
                              value: option.id,
                              title: Text('${option.letter}. ${option.text}'),
                              activeColor: colorScheme.primary,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            _buildNavigationBar(context, examState, examController),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar(
    BuildContext context,
    ExamState examState,
    ExamController examController,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!examState.isFirstQuestion)
            OutlinedButton(
              onPressed: examController.previousQuestion,
              child: const Text('Previous'),
            )
          else
            const SizedBox(width: 88),
          const Spacer(),
          _QuestionDots(
            total: examState.totalQuestions,
            current: examState.currentIndex,
            answers: examState.answers,
            questions: examState.questions,
            onTap: examController.goToQuestion,
          ),
          const Spacer(),
          if (examState.isLastQuestion)
            FilledButton(
              onPressed: () => _showSubmitDialog(context, examController),
              child: const Text('Submit'),
            )
          else
            FilledButton(
              onPressed: examController.nextQuestion,
              child: const Text('Next'),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen(
    BuildContext context,
    ExamState examState,
    ExamController examController,
  ) {
    final score = examState.calculateScore();
    final totalMarks = examState.questions.fold<int>(
      0,
      (sum, q) => sum + q.marks,
    );
    final percentage = totalMarks > 0 ? (score / totalMarks * 100).round() : 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                percentage >= 70 ? Icons.check_circle : Icons.info,
                size: 80,
                color: percentage >= 70 ? Colors.green : colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Exam Complete!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                '$score / $totalMarks',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context, ExamController examController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Exam?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              examController.submit();
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showSubmitDialog(BuildContext context, ExamController examController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Exam?'),
        content: const Text('Are you sure you want to submit your answers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              examController.submit();
              Navigator.of(context).pop();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.remainingSeconds});

  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final isLow = remainingSeconds < 300;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isLow
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isLow
                  ? Theme.of(context).colorScheme.onError
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionProgress extends StatelessWidget {
  const _QuestionProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '$current / $total',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: current / total,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionDots extends StatelessWidget {
  const _QuestionDots({
    required this.total,
    required this.current,
    required this.answers,
    required this.questions,
    required this.onTap,
  });

  final int total;
  final int current;
  final Map<String, String> answers;
  final List questions;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayCount = total > 10 ? 10 : total;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(displayCount, (index) {
        final isAnswered = answers.containsKey(questions[index].id);
        final isCurrent = index == current;

        return GestureDetector(
          onTap: () => onTap(index),
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent
                  ? colorScheme.primary
                  : isAnswered
                      ? colorScheme.primary.withAlpha(100)
                      : colorScheme.surfaceContainerHighest,
              border: isCurrent
                  ? null
                  : Border.all(color: colorScheme.outline),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrent
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight:
                      isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
