import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/paper.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../providers/exam_provider.dart';
import '../services/data_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/score_ring.dart';

class ExamScreen extends ConsumerWidget {
  const ExamScreen({super.key, required this.paperId});

  final String paperId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = ref.watch(papersProvider(null));

    return papersAsync.when(
      loading: () =>
          const AppScaffold(body: LoadingState(label: 'Loading exam...')),
      error: (e, _) => const AppScaffold(
        body: EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load the exam',
          subtitle: 'Check your connection and try again.',
          gradient: AppColors.ember,
        ),
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
  bool _attemptSaved = false;

  Future<void> _saveAttempt(ExamState examState) async {
    if (_attemptSaved) return; // Already saved
    _attemptSaved = true;

    try {
      final userAsync = ref.read(authStateProvider);
      final user = userAsync.value;

      if (user == null) {
        _attemptSaved = false;
        return;
      }

      final score = examState.calculateScore();
      final totalMarks = examState.questions.fold<int>(
        0,
        (sum, q) => sum + q.marks,
      );

      await DataService.instance.saveAttempt(
        userId: user.id,
        paperId: widget.paper.id,
        score: score,
        totalMarks: totalMarks,
        answers: examState.answers,
      );

      // Refresh attempts list
      ref.invalidate(attemptsProvider);
    } catch (e) {
      // Allow retry on failure
      _attemptSaved = false;
      debugPrint('Failed to save attempt: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(
      questionsWithOptionsProvider(widget.paper.id),
    );

    return questionsAsync.when(
      loading: () =>
          const AppScaffold(body: LoadingState(label: 'Loading questions...')),
      error: (e, _) => AppScaffold(
        body: EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load questions',
          subtitle: '$e',
          gradient: AppColors.ember,
        ),
      ),
      data: (questions) {
        if (questions.isEmpty) {
          return const AppScaffold(
            body: EmptyState(
              icon: Icons.quiz_outlined,
              title: 'No questions yet',
              subtitle: 'This paper does not have any questions added yet.',
              gradient: AppColors.sunset,
            ),
          );
        }

        final examController = ref.read(examProvider.notifier);

        if (!_configured) {
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

        if (examState.questions.isEmpty || examState.paperId != widget.paper.id) {
          return const AppScaffold(
            body: LoadingState(label: 'Preparing exam...'),
          );
        }

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
    final theme = Theme.of(context);
    final question = examState.currentQuestion;
    final selectedOptionId = examState.answers[question.id];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showExitDialog(context, examController);
        }
      },
      child: AppScaffold(
        appBar: GlassAppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.paper.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                'Question ${examState.currentIndex + 1} of ${examState.totalQuestions}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            _TimerBadge(remainingSeconds: examState.remainingSeconds),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            _ProgressStrip(
              current: examState.currentIndex + 1,
              total: examState.totalQuestions,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  Row(
                    children: [
                      MetaChip(
                        icon: Icons.quiz_outlined,
                        label:
                            'Question ${examState.currentIndex + 1} of ${examState.totalQuestions}',
                      ),
                      const SizedBox(width: 8),
                      MetaChip(
                        icon: Icons.stars_rounded,
                        label:
                            '${question.marks} ${question.marks == 1 ? 'mark' : 'marks'}',
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    radius: 24,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.text,
                          style: theme.textTheme.titleLarge?.copyWith(
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (question.options != null) ...[
                          const SizedBox(height: 22),
                          Column(
                            children: [
                              for (final option in question.options!)
                                _OptionTile(
                                  letter: option.letter,
                                  text: option.text,
                                  selected: selectedOptionId == option.id,
                                  onTap: () {
                                    examController.selectAnswer(
                                      question.id,
                                      option.id,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _ExamDock(
              examState: examState,
              onPrevious: examController.previousQuestion,
              onNext: examController.nextQuestion,
              onJump: examController.goToQuestion,
              onSubmit: () => _showSubmitDialog(context, examController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen(
    BuildContext context,
    ExamState examState,
    ExamController examController,
  ) {
    // Save attempt to database
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveAttempt(examState);
    });

    final theme = Theme.of(context);
    final score = examState.calculateScore();
    final totalMarks = examState.questions.fold<int>(
      0,
      (sum, q) => sum + q.marks,
    );
    final percentage = totalMarks > 0 ? (score / totalMarks * 100) : 0.0;
    final pct = percentage.round();

    var correct = 0;
    var answered = 0;
    for (final question in examState.questions) {
      final selectedId = examState.answers[question.id];
      if (selectedId == null) continue;
      answered++;
      final options = question.options;
      if (options == null) continue;
      if (options.any((o) => o.id == selectedId && o.isCorrect)) correct++;
    }
    final skipped = examState.questions.length - answered;
    final wrong = answered - correct;

    final gradient = pct >= 70
        ? AppColors.mint
        : pct >= 50
        ? AppColors.sunset
        : AppColors.ember;

    final message = pct >= 80
        ? 'Outstanding. You have this topic nailed.'
        : pct >= 70
        ? 'Solid work. A little more revision and it is an A*.'
        : pct >= 50
        ? 'A decent base. Focus on the questions you missed.'
        : 'Keep going. Review every answer and try again.';

    return AppScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  ScoreRing(
                    value: percentage / 100,
                    gradient: gradient,
                    size: 200,
                    strokeWidth: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pct%',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2,
                          ),
                        ),
                        Text(
                          '$score / $totalMarks marks',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Exam complete',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      _ResultChip(
                        value: '$correct',
                        label: 'Correct',
                        gradient: AppColors.mint,
                      ),
                      const SizedBox(width: 12),
                      _ResultChip(
                        value: '$wrong',
                        label: 'Wrong',
                        gradient: AppColors.ember,
                      ),
                      const SizedBox(width: 12),
                      _ResultChip(
                        value: '$skipped',
                        label: 'Skipped',
                        gradient: AppColors.brandSoft,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  GradientButton(
                    onPressed: () =>
                        context.push('/review/${widget.paper.id}'),
                    icon: Icons.manage_search_rounded,
                    child: const Text('Review answers'),
                  ),
                  const SizedBox(height: 12),
                  GlassButton(
                    onPressed: () => context.go('/'),
                    icon: Icons.home_rounded,
                    child: const Text('Back to home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context, ExamController examController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit exam?'),
        content: const Text(
          'Your answers so far will not be graded. Are you sure you want to '
          'leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep going'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
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
        title: const Text('Submit exam?'),
        content: const Text('You can still review every answer afterwards.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not yet'),
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: isDark ? 0.24 : 0.1)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.white.withValues(alpha: 0.75)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE6EAF7)),
                width: selected ? 1.8 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.brand : null,
                    color: selected
                        ? null
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : const Color(0xFFEEF1FC)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: selected
                          ? Colors.white
                          : (isDark ? AppColors.darkInkSoft : AppColors.inkSoft),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: selected ? 1 : 0.6,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 22,
                    color: selected
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.darkInkFaint
                              : const Color(0xFFC3CAE4)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamDock extends StatelessWidget {
  const _ExamDock({
    required this.examState,
    required this.onPrevious,
    required this.onNext,
    required this.onJump,
    required this.onSubmit,
  });

  final ExamState examState;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final void Function(int) onJump;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: examState.totalQuestions,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isAnswered = examState.answers.containsKey(
                  examState.questions[index].id,
                );
                final isCurrent = index == examState.currentIndex;

                return GestureDetector(
                  onTap: () => onJump(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isCurrent ? AppColors.brand : null,
                      color: isCurrent
                          ? null
                          : isAnswered
                          ? AppColors.success.withValues(alpha: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: isCurrent
                          ? null
                          : Border.all(
                              color: isAnswered
                                  ? AppColors.success.withValues(alpha: 0.5)
                                  : Theme.of(context).colorScheme.outline,
                            ),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isCurrent
                            ? Colors.white
                            : isAnswered
                            ? AppColors.successDeep
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  height: 50,
                  onPressed: examState.isFirstQuestion ? null : onPrevious,
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  height: 50,
                  onPressed: examState.isLastQuestion ? onSubmit : onNext,
                  child: Text(examState.isLastQuestion ? 'Submit' : 'Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({
    required this.value,
    required this.label,
    required this.gradient,
  });

  final String value;
  final String label;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
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
    final text =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: isLow ? AppColors.ember : null,
        color: isLow ? null : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        boxShadow: isLow
            ? [
                BoxShadow(
                  color: AppColors.danger.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: isLow ? Colors.white : AppColors.primaryDeep,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.4,
              color: isLow ? Colors.white : AppColors.primaryDeep,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = total > 0 ? current / total : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) => LinearProgressIndicator(
            value: animated,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.6),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
