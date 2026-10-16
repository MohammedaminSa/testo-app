import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/question.dart';
import '../providers/data_provider.dart';
import '../providers/exam_provider.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/score_ring.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key, required this.paperId});

  final String paperId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examState = ref.watch(examProvider);

    if (!examState.isSubmitted || examState.paperId != paperId) {
      return const AppScaffold(
        appBar: GlassAppBar(title: Text('Review')),
        body: EmptyState(
          icon: Icons.manage_search_rounded,
          title: 'No results to review',
          subtitle: 'Finish an exam first and your answers will appear here.',
          gradient: AppColors.sunset,
        ),
      );
    }

    final questionsAsync = ref.watch(questionsWithOptionsProvider(paperId));

    return questionsAsync.when(
      loading: () =>
          const AppScaffold(body: LoadingState(label: 'Loading review...')),
      error: (e, _) => AppScaffold(
        body: EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load the review',
          subtitle: '$e',
          gradient: AppColors.ember,
        ),
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
    final theme = Theme.of(context);
    final gradient = percentage >= 70
        ? AppColors.mint
        : percentage >= 50
        ? AppColors.sunset
        : AppColors.ember;

    return AppScaffold(
      appBar: GlassAppBar(
        automaticallyImplyLeading: false,
        title: Text('Review answers', style: theme.textTheme.titleMedium),
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.last.withValues(alpha: 0.4),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                ScoreRing(
                  value: percentage / 100,
                  gradient: const LinearGradient(
                    colors: [Colors.white, Colors.white70],
                  ),
                  trackColor: Colors.white.withValues(alpha: 0.3),
                  size: 84,
                  strokeWidth: 8,
                  child: Text(
                    '$percentage%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$score / $totalMarks marks',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$correctCount of ${questions.length} correct',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: GradientButton(
                onPressed: () => context.go('/'),
                icon: Icons.home_rounded,
                child: const Text('Back to home'),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = widget.isCorrect ? AppColors.success : AppColors.danger;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: widget.isCorrect ? AppColors.mint : AppColors.ember,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.isCorrect ? Icons.check_rounded : Icons.close_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Question ${widget.questionNumber}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.25 : 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.isCorrect
                      ? 'Correct'
                      : widget.selectedOptionId == null
                      ? 'Skipped'
                      : 'Incorrect',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: widget.isCorrect
                        ? AppColors.successDeep
                        : AppColors.dangerDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.question.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          Text(
            '${widget.question.marks} ${widget.question.marks == 1 ? 'mark' : 'marks'}',
            style: theme.textTheme.bodySmall,
          ),
          if (widget.question.options != null) ...[
            const SizedBox(height: 16),
            ...widget.question.options!.map((option) {
              final isSelected = option.id == widget.selectedOptionId;
              final isCorrectOption = option.isCorrect;

              Color bg;
              Color border;
              Color? textColor;
              IconData? icon;

              if (isCorrectOption) {
                bg = AppColors.success.withValues(alpha: isDark ? 0.22 : 0.12);
                border = AppColors.success;
                textColor = isDark ? const Color(0xFF6EE7B7) : AppColors.successDeep;
                icon = Icons.check_circle_rounded;
              } else if (isSelected && !isCorrectOption) {
                bg = AppColors.danger.withValues(alpha: isDark ? 0.22 : 0.1);
                border = AppColors.danger;
                textColor = isDark ? const Color(0xFFFCA5A5) : AppColors.dangerDeep;
                icon = Icons.cancel_rounded;
              } else {
                bg = isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF3F5FD);
                border = isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : const Color(0xFFE6EAF7);
                textColor = null;
                icon = null;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected && !isCorrectOption
                        ? AppColors.danger
                        : border,
                    width: isSelected && !isCorrectOption ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: textColor),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        '${option.letter}. ${option.text}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: isSelected || isCorrectOption
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isCorrectOption
                              ? AppColors.success
                              : AppColors.danger,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Your answer',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
          if (!widget.isCorrect && widget.selectedOptionId == null) ...[
            const SizedBox(height: 4),
            Text(
              'You did not answer this question.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.dangerDeep,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (!widget.isCorrect) ...[
            const SizedBox(height: 12),
            _AiPanel(
              explanation: _explanation,
              loading: _loadingExplanation,
              error: _explanationError,
              onFetch: _fetchExplanation,
            ),
          ],
        ],
      ),
    );
  }
}

class _AiPanel extends StatelessWidget {
  const _AiPanel({
    required this.explanation,
    required this.loading,
    required this.error,
    required this.onFetch,
  });

  final String? explanation;
  final bool loading;
  final String? error;
  final VoidCallback onFetch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (explanation != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.aurora.withOpacity(0.16)
              : AppColors.aurora.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI explanation',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isDark ? const Color(0xFFA5B4FC) : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              explanation!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.55,
              ),
            ),
          ],
        ),
      );
    }

    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error != null) ...[
          Text(
            error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.dangerDeep,
            ),
          ),
          const SizedBox(height: 8),
        ],
        GradientButton(
          height: 46,
          expanded: false,
          onPressed: onFetch,
          icon: Icons.auto_awesome_rounded,
          child: const Text('Explain this with AI'),
        ),
      ],
    );
  }
}
