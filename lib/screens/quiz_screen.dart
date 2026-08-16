import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../providers/message_controller.dart';
import '../providers/progress_providers.dart';
import '../services/quiz_storage.dart';
import 'review_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final Quiz quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _loading = true;
  late List<Question> _paper;
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _answered = false;
  bool _finished = false;
  int _correctCount = 0;
  final List<QuestionAnswer> _answers = [];

  Timer? _timer;
  int? _timeLimitSeconds;
  int? _secondsLeft;

  Question get _question => _paper[_currentIndex];
  bool get _isLast => _currentIndex == _paper.length - 1;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    final saved = await QuizStorage.load(widget.quiz.id);
    if (saved != null && mounted) {
      final resume = await _promptResume();
      if (resume == true) {
        setState(() {
          _paper = saved.paper;
          _currentIndex = saved.currentIndex < saved.paper.length
              ? saved.currentIndex
              : saved.paper.length - 1;
          _answers.addAll(saved.answers);
          _correctCount = _answers.where((a) => a.isCorrect).length;
          _timeLimitSeconds = saved.timeLimitSeconds;
          _loading = false;
        });
        _startTimer();
        return;
      }
      await QuizStorage.clear(widget.quiz.id);
    }
    _buildPaper();
    setState(() => _loading = false);
    _startTimer();
  }

  void _buildPaper() {
    final shuffled = [...widget.quiz.questions]..shuffle();
    final size = widget.quiz.paperSize ?? shuffled.length;
    _paper = shuffled.take(size.clamp(1, shuffled.length)).toList();
    _timeLimitSeconds = widget.quiz.timeLimitSeconds;
  }

  Future<bool?> _promptResume() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unfinished quiz'),
        content: const Text(
          'You have an in-progress attempt. Continue where you left off?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Start over'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (index == _question.correctIndex) _correctCount++;
    });
    _recordAnswer();
    _stopTimer();
    _persist();
  }

  void _recordAnswer() {
    final q = _question;
    final selected = _selectedIndex;
    _answers.add(QuestionAnswer(
      questionId: q.id,
      questionText: q.text,
      topic: q.topic,
      selectedIndex: selected,
      correctIndex: q.correctIndex,
      selectedText: selected != null ? q.options[selected] : '',
      correctText: q.options[q.correctIndex],
      isCorrect: selected != null && selected == q.correctIndex,
      explanation: q.explanation,
    ));
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedIndex = null;
      _answered = false;
    });
    _persist();
    _startTimer();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _stopTimer();
    QuizStorage.clear(widget.quiz.id);
    final result = QuizResult(
      correctCount: _correctCount,
      totalQuestions: _paper.length,
      scorePercent: _paper.isEmpty ? 0 : _correctCount / _paper.length * 100,
      questionsOrder: _paper.map((q) => q.id).toList(),
      answers: List.unmodifiable(_answers),
    );
    _complete(result);
  }

  /// Saves the attempt to the cloud, then opens the review screen. A failed
  /// save never blocks the user — the message host surfaces the error.
  Future<void> _complete(QuizResult result) async {
    final attempt = QuizAttempt(
      quizId: widget.quiz.id,
      quizTitle: widget.quiz.title,
      totalQuestions: result.totalQuestions,
      correctAnswers: result.correctCount,
      scorePercent: result.scorePercent,
      questionsOrder: result.questionsOrder,
      answers: result.answers,
      completedAt: DateTime.now(),
    );
    try {
      await ref.read(progressRepositoryProvider).saveAttempt(attempt);
      ref.invalidate(attemptsProvider);
    } catch (_) {
      ref
          .read(messageControllerProvider.notifier)
          .show('Result could not be saved to the cloud yet.');
    }
    if (mounted) {
      context.pushReplacement(
        '/review',
        extra: ReviewArgs(quiz: widget.quiz, result: result),
      );
    }
  }

  // -- Timer (per-question countdown + auto-submit) --------------------------

  void _startTimer() {
    _stopTimer();
    if (_timeLimitSeconds == null || _answered) return;
    _secondsLeft = _timeLimitSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _answered) {
        _timer?.cancel();
        return;
      }
      setState(() {
        _secondsLeft = (_secondsLeft ?? _timeLimitSeconds!) - 1;
      });
      if (_secondsLeft! <= 0) {
        _stopTimer();
        _onTimeout();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTimeout() {
    if (_answered || _finished) return;
    setState(() {
      _selectedIndex = null;
      _answered = true;
    });
    _recordAnswer();
    _next();
  }

  Future<void> _persist() async {
    await QuizStorage.save(
      quizId: widget.quiz.id,
      paper: _paper,
      currentIndex: _currentIndex,
      answers: _answers,
      timeLimitSeconds: _timeLimitSeconds,
    );
  }

  // -- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final total = _paper.length;
    final progress = (_currentIndex + 1) / total;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} of $total'),
        actions: [
          if (_timeLimitSeconds != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_secondsLeft ?? _timeLimitSeconds}s',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (_secondsLeft ?? _timeLimitSeconds!) <= 5
                        ? AppTheme.error
                        : AppTheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: const Color(0xFFE2E8F0),
            color: AppTheme.primary,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    _question.text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(
                    _question.options.length,
                    (i) => _buildOption(i),
                  ),
                  if (_answered) ...[
                    const SizedBox(height: 16),
                    _buildExplanation(),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _answered ? _next : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text(_isLast ? 'Finish' : 'Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int index) {
    final isCorrect = index == _question.correctIndex;
    final isSelected = index == _selectedIndex;

    Color? borderColor;
    Color? fillColor;
    Color? textColor;

    if (_answered) {
      if (isCorrect) {
        borderColor = AppTheme.success;
        fillColor = AppTheme.success.withValues(alpha: 0.1);
        textColor = AppTheme.success;
      } else if (isSelected) {
        borderColor = AppTheme.error;
        fillColor = AppTheme.error.withValues(alpha: 0.1);
        textColor = AppTheme.error;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: fillColor ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _selectOption(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor ?? const Color(0xFFE2E8F0),
                width: borderColor != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _question.options[index],
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor ?? Colors.black87,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (_answered && isCorrect)
                  const Icon(Icons.check_circle, color: AppTheme.success)
                else if (_answered && isSelected)
                  const Icon(Icons.cancel, color: AppTheme.error),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExplanation() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppTheme.primary, size: 18),
              SizedBox(width: 6),
              Text(
                'Explanation',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_question.explanation, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}
