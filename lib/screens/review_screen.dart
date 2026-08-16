import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';

/// Shown right after a quiz finishes: the score, which topics need work,
/// and a question-by-question breakdown with explanations.
class ReviewScreen extends StatelessWidget {
  final Quiz quiz;
  final QuizResult result;

  const ReviewScreen({super.key, required this.quiz, required this.result});

  @override
  Widget build(BuildContext context) {
    final weakTopics = _buildWeakTopics();

    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildScoreCard(),
          if (weakTopics.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildWeakAreasCard(weakTopics),
          ],
          const SizedBox(height: 24),
          const Text(
            'Your answers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            result.answers.length,
            (i) => _buildAnswerCard(result.answers[i], i + 1),
          ),
        ],
      ),
    );
  }

  List<String> _buildWeakTopics() {
    final misses = <String, int>{};
    for (final a in result.answers) {
      if (!a.isCorrect && a.topic.isNotEmpty) {
        misses[a.topic] = (misses[a.topic] ?? 0) + 1;
      }
    }
    final entries = misses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }

  Widget _buildScoreCard() {
    final passed = result.scorePercent >= 50;
    final color = passed ? AppTheme.success : AppTheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${result.scorePercent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${result.correctCount} of ${result.totalQuestions} correct',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              passed ? 'Nice work, keep it up!' : 'Keep practicing!',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakAreasCard(List<String> topics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.report_problem_outlined,
                    color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  'Topics to review',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topics
                  .map((t) => Chip(
                        label: Text(t),
                        backgroundColor: Colors.orange.withValues(alpha: 0.12),
                        side: BorderSide(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerCard(QuestionAnswer answer, int number) {
    final color = answer.isCorrect ? AppTheme.success : AppTheme.error;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  answer.isCorrect ? Icons.check_circle : Icons.cancel,
                  color: color,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$number. ${answer.questionText}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _answerLine('Your answer', answer.selectedText, answer.isCorrect),
            if (!answer.isCorrect) ...[
              const SizedBox(height: 6),
              _answerLine('Correct answer', answer.correctText, true),
            ],
            if (answer.explanation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  answer.explanation,
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _answerLine(String label, String text, bool correct) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.black54),
        ),
        Expanded(
          child: Text(
            text.isEmpty ? 'No answer (time up)' : text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: correct ? AppTheme.success : AppTheme.error,
            ),
          ),
        ),
      ],
    );
  }
}