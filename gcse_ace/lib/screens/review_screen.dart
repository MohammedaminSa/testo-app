import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/question.dart';
import '../providers/data_provider.dart';
import '../providers/exam_provider.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key, required this.paperId});

  final String paperId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examState = ref.watch(examProvider);

    if (!examState.isSubmitted || examState.paperId != paperId) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review')),
        body: const Center(child: Text('No exam results to review.')),
      );
    }

    final questionsAsync = ref.watch(questionsWithOptionsProvider(paperId));

    return questionsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (questions) {
        final score = examState.calculateScore();
        final totalMarks =
            questions.fold<int>(0, (sum, q) => sum + q.marks);
        final percentage =
            totalMarks > 0 ? (score / totalMarks * 100).round() : 0;
        final correctCount = _countCorrect(examState, questions);

        return _ReviewContent(
          questions: questions,
          examState: examState,
          score: score,
          totalMarks: totalMarks,
          percentage: percentage,
          correctCount: correctCount,
        );
      },
    );
  }

  int _countCorrect(ExamState examState, List<Question> questions) {
    int count = 0;
    for (final question in questions) {
      final selectedOptionId = examState.answers[question.id];
      if (selectedOptionId != null && question.options != null) {
        final selected = question.options!.where(
          (o) => o.id == selectedOptionId && o.isCorrect,
        );
        if (selected.isNotEmpty) count++;
      }
    }
    return count;
  }
}

class _ReviewContent extends StatelessWidget {
  const _ReviewContent({
    required this.questions,
    required this.examState,
    required this.score,
    required this.totalMarks,
    required this.percentage,
    required this.correctCount,
  });

  final List<Question> questions;
  final ExamState examState;
  final int score;
  final int totalMarks;
  final int percentage;
  final int correctCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Answers'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: colorScheme.primaryContainer,
            child: Column(
              children: [
                Text(
                  '$score / $totalMarks  ($percentage%)',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$correctCount of ${questions.length} correct',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                final selectedOptionId = examState.answers[question.id];
                final isCorrect = _isCorrect(question, selectedOptionId);

                return _QuestionReviewCard(
                  questionNumber: index + 1,
                  question: question,
                  selectedOptionId: selectedOptionId,
                  isCorrect: isCorrect,
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to Home'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCorrect(Question question, String? selectedOptionId) {
    if (selectedOptionId == null || question.options == null) return false;
    final selected = question.options!.where(
      (o) => o.id == selectedOptionId && o.isCorrect,
    );
    return selected.isNotEmpty;
  }
}

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({
    required this.questionNumber,
    required this.question,
    required this.selectedOptionId,
    required this.isCorrect,
  });

  final int questionNumber;
  final Question question;
  final String? selectedOptionId;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCorrect ? Colors.green : colorScheme.error,
                  ),
                  child: Center(
                    child: Icon(
                      isCorrect ? Icons.check : Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Q$questionNumber  (${question.marks} ${question.marks == 1 ? 'mark' : 'marks'})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (question.options != null) ...[
              const SizedBox(height: 12),
              ...question.options!.map((option) {
                final isSelected = option.id == selectedOptionId;
                final isCorrectOption = option.isCorrect;

                Color bgColor;
                Color? textColor;
                IconData? icon;

                if (isCorrectOption) {
                  bgColor = Colors.green.withAlpha(30);
                  textColor = Colors.green.shade800;
                  icon = Icons.check_circle;
                } else if (isSelected && !isCorrectOption) {
                  bgColor = colorScheme.error.withAlpha(30);
                  textColor = colorScheme.error;
                  icon = Icons.cancel;
                } else {
                  bgColor = colorScheme.surfaceContainerHighest;
                  textColor = null;
                  icon = null;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(
                            color: isCorrectOption
                                ? Colors.green
                                : colorScheme.error,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: textColor),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          '${option.letter}. ${option.text}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: isSelected || isCorrectOption
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCorrectOption
                                ? Colors.green
                                : colorScheme.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Your answer',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
            if (!isCorrect && selectedOptionId == null) ...[
              const SizedBox(height: 8),
              Text(
                'Not answered',
                style: TextStyle(
                  color: colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
