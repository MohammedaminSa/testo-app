import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _answered = false;
  int _correctCount = 0;

  Question get _question => widget.quiz.questions[_currentIndex];
  bool get _isLast => _currentIndex == widget.quiz.questions.length - 1;

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (index == _question.correctIndex) _correctCount++;
    });
  }

  void _next() {
    if (_isLast) {
      Navigator.of(context).pop(_correctCount);
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedIndex = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.quiz.questions.length;
    final progress = (_currentIndex + 1) / total;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} of $total'),
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
