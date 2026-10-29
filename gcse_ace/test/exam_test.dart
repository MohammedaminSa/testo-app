import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gcse_ace/models/option.dart';
import 'package:gcse_ace/models/question.dart';
import 'package:gcse_ace/providers/exam_provider.dart';

void main() {
  group('ExamState score calculation', () {
    const q1 = Question(
      id: 'q1',
      paperId: 'p1',
      orderNumber: 1,
      text: 'Question 1',
      marks: 2,
      questionType: 'multiple_choice',
      options: [
        Option(id: 'opt1_a', questionId: 'q1', letter: 'A', text: 'Ans A', isCorrect: true),
        Option(id: 'opt1_b', questionId: 'q1', letter: 'B', text: 'Ans B', isCorrect: false),
      ],
    );

    const q2 = Question(
      id: 'q2',
      paperId: 'p1',
      orderNumber: 2,
      text: 'Question 2',
      marks: 3,
      questionType: 'multiple_choice',
      options: [
        Option(id: 'opt2_a', questionId: 'q2', letter: 'A', text: 'Ans A', isCorrect: false),
        Option(id: 'opt2_b', questionId: 'q2', letter: 'B', text: 'Ans B', isCorrect: true),
      ],
    );

    const q3 = Question(
      id: 'q3',
      paperId: 'p1',
      orderNumber: 3,
      text: 'What is the formula for Ohm\'s law?',
      marks: 4,
      questionType: 'written',
      correctAnswer: 'V = I * R',
    );

    test('calculates correct score when answers are correct', () {
      final state = ExamState(
        paperId: 'p1',
        questions: const [q1, q2, q3],
        answers: const {'q1': 'opt1_a', 'q2': 'opt2_b', 'q3': 'V = I * R'},
        remainingSeconds: 3600,
      );

      expect(state.calculateScore(), 9);
      expect(state.answeredCount, 3);
      expect(state.totalQuestions, 3);
    });

    test('calculates 0 when no answers or all wrong', () {
      final state = ExamState(
        paperId: 'p1',
        questions: const [q1, q2, q3],
        answers: const {'q1': 'opt1_b', 'q2': 'opt2_a', 'q3': 'wrong answer'},
        remainingSeconds: 3600,
      );

      expect(state.calculateScore(), 0);
    });

    test('calculates partial score including written question match', () {
      final state = ExamState(
        paperId: 'p1',
        questions: const [q1, q2, q3],
        answers: const {'q1': 'opt1_a', 'q3': 'v = i * r'},
        remainingSeconds: 3600,
      );

      expect(state.calculateScore(), 6);
    });
  });

  group('ExamController provider', () {
    const sampleQuestions = [
      Question(
        id: 'q1',
        paperId: 'p1',
        orderNumber: 1,
        text: 'Q1',
        marks: 1,
        questionType: 'multiple_choice',
        options: [
          Option(id: 'opt1', questionId: 'q1', letter: 'A', text: 'A', isCorrect: true),
        ],
      ),
      Question(
        id: 'q2',
        paperId: 'p1',
        orderNumber: 2,
        text: 'Q2',
        marks: 1,
        questionType: 'multiple_choice',
        options: [
          Option(id: 'opt2', questionId: 'q2', letter: 'A', text: 'A', isCorrect: true),
        ],
      ),
    ];

    test('configures exam, navigates questions, selects answer, and submits', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(examProvider.notifier);
      expect(container.read(examProvider).questions, isEmpty);

      controller.configure(
        paperId: 'p1',
        questions: sampleQuestions,
        durationMinutes: 60,
      );

      var state = container.read(examProvider);
      expect(state.paperId, 'p1');
      expect(state.questions.length, 2);
      expect(state.remainingSeconds, 3600);
      expect(state.currentIndex, 0);
      expect(state.isFirstQuestion, isTrue);

      controller.selectAnswer('q1', 'opt1');
      state = container.read(examProvider);
      expect(state.answers['q1'], 'opt1');

      controller.nextQuestion();
      state = container.read(examProvider);
      expect(state.currentIndex, 1);
      expect(state.isLastQuestion, isTrue);

      controller.submit();
      state = container.read(examProvider);
      expect(state.isSubmitted, isTrue);

      // Cannot change answer after submission
      controller.selectAnswer('q2', 'opt2');
      expect(container.read(examProvider).answers.containsKey('q2'), isFalse);
    });
  });
}
