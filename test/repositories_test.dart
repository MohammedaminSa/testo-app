import 'package:flutter_test/flutter_test.dart';
import 'package:testo/models/models.dart';
import 'package:testo/repositories/progress_repository.dart';

void main() {
  group('ProgressRepository.computeStats', () {
    test('returns zeroed stats for an empty history', () {
      final stats = ProgressRepository.computeStats(const []);

      expect(stats['totalAttempts'], 0);
      expect(stats['avgScore'], 0.0);
      expect(stats['bestScore'], 0.0);
      expect(stats['weakTopics'], isEmpty);
    });

    test('computes averages, best, and weak topics', () {
      final attempts = [
        QuizAttempt(
          quizId: 'a',
          quizTitle: 'A',
          totalQuestions: 2,
          correctAnswers: 2,
          scorePercent: 100,
          answers: const [
            QuestionAnswer(
              questionId: 'q1',
              questionText: 'Q1',
              topic: 'Algorithms',
              selectedIndex: 0,
              correctIndex: 0,
              selectedText: 'A',
              correctText: 'A',
              isCorrect: true,
              explanation: '',
            ),
          ],
          completedAt: DateTime(2026, 1, 1),
        ),
        QuizAttempt(
          quizId: 'b',
          quizTitle: 'B',
          totalQuestions: 4,
          correctAnswers: 2,
          scorePercent: 50,
          answers: const [
            QuestionAnswer(
              questionId: 'q2',
              questionText: 'Q2',
              topic: 'Algorithms',
              selectedIndex: 0,
              correctIndex: 1,
              selectedText: 'A',
              correctText: 'B',
              isCorrect: false,
              explanation: '',
            ),
            QuestionAnswer(
              questionId: 'q3',
              questionText: 'Q3',
              topic: 'Data Structures',
              selectedIndex: 0,
              correctIndex: 1,
              selectedText: 'A',
              correctText: 'B',
              isCorrect: false,
              explanation: '',
            ),
          ],
          completedAt: DateTime(2026, 1, 2),
        ),
      ];

      final stats = ProgressRepository.computeStats(attempts);

      expect(stats['totalAttempts'], 2);
      expect(stats['totalCorrect'], 4);
      expect(stats['totalAnswered'], 6);
      expect(stats['bestScore'], 100.0);
      expect(stats['avgScore'], 75.0);
      expect(stats['quizzesTaken'], 2);
      // Both weak topics appear; Algorithms is first (ties keep insertion).
      final weak = stats['weakTopics'] as List;
      expect(weak.toSet(), {'Algorithms', 'Data Structures'});
    });
  });
}