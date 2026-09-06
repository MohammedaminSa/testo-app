import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/question.dart';
import '../providers/data_provider.dart';
import '../providers/exam_provider.dart';
import '../services/ai_service.dart';

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

class _QuestionReviewCard extends StatefulWidget {
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
  State<_QuestionReviewCard> createState() => _QuestionReviewCardState();
}

class _QuestionReviewCardState extends State<_QuestionReviewCard> {
  String? _explanation;
  bool _loadingExplanation = false;
  String? _explanationError;

  String? get _studentAnswerText {
    if (widget.selectedOptionId == null || widget.question.options == null) {
      return null;
    }
    final selected = widget.question.options!.where(
      (o) => o.id == widget.selectedOptionId,
    );
    return selected.isNotEmpty ? selected.first.text : null;
  }

  String? get _correctAnswerText {
    if (widget.question.options == null) return null;
    final correct = widget.question.options!.where((o) => o.isCorrect);
    return correct.isNotEmpty ? correct.first.text : null;
  }

  Future<void> _fetchExplanation() async {
    setState(() {
      _loadingExplanation = true;
      _explanationError = null;
    });

    try {
      final explanation = await AiService.instance.getExplanation(
        question: widget.question.text,
        correctAnswer: _correctAnswerText ?? widget.question.correctAnswer ?? '',
        studentAnswer: _studentAnswerText,
      );
      if (mounted) {
        setState(() {
          _explanation = explanation;
          _loadingExplanation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _explanationError = 'Failed to load explanation. Please try again.';
          _loadingExplanation = false;
        });
      }
    }
  }

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
                    color: widget.isCorrect ? Colors.green : colorScheme.error,
                  ),
                  child: Center(
                    child: Icon(
                      widget.isCorrect ? Icons.check : Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Q${widget.questionNumber}  (${widget.question.marks} ${widget.question.marks == 1 ? 'mark' : 'marks'})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.question.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (widget.question.options != null) ...[
              const SizedBox(height: 12),
              ...widget.question.options!.map((option) {
                final isSelected = option.id == widget.selectedOptionId;
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
            if (!widget.isCorrect && widget.selectedOptionId == null) ...[
              const SizedBox(height: 8),
              Text(
                'Not answered',
                style: TextStyle(
                  color: colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (!widget.isCorrect) ...[
              const SizedBox(height: 12),
              if (_explanation != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.primary.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 16, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'AI Explanation',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_explanation!),
                    ],
                  ),
                )
              else if (_loadingExplanation)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (_explanationError != null) ...[
                  Text(
                    _explanationError!,
                    style: TextStyle(color: colorScheme.error, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  onPressed: _fetchExplanation,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Explain this'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
