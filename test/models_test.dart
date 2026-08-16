import 'package:flutter_test/flutter_test.dart';
import 'package:testo/models/models.dart';

void main() {
  group('Question', () {
    test('fromMap parses options in position order and finds correctIndex', () {
      final question = Question.fromMap({
        'id': 'q1',
        'text': 'Pick the right one',
        'explanation': 'Because.',
        'topic': 'Algorithms',
        'options': [
          {'position': 2, 'text': 'Wrong', 'is_correct': false},
          {'position': 1, 'text': 'Right', 'is_correct': true},
        ],
      });

      expect(question.options, ['Right', 'Wrong']);
      expect(question.correctIndex, 0);
      expect(question.topic, 'Algorithms');
    });

    test('toMap round-trips through fromMap', () {
      const original = Question(
        id: 'q1',
        text: 'Question',
        options: ['A', 'B', 'C'],
        correctIndex: 1,
        explanation: 'Exp',
        topic: 'OOP',
      );

      final restored = Question.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.text, original.text);
      expect(restored.options, original.options);
      expect(restored.correctIndex, original.correctIndex);
      expect(restored.explanation, original.explanation);
      expect(restored.topic, original.topic);
    });
  });

  group('QuestionAnswer', () {
    test('toMap / fromMap round-trip, including a skipped answer', () {
      const answer = QuestionAnswer(
        questionId: 'q1',
        questionText: 'Q',
        topic: 'Algorithms',
        selectedIndex: null,
        correctIndex: 2,
        selectedText: '',
        correctText: 'C',
        isCorrect: false,
        explanation: 'Exp',
      );

      final restored = QuestionAnswer.fromMap(answer.toMap());

      expect(restored.selectedIndex, isNull);
      expect(restored.isCorrect, isFalse);
      expect(restored.correctText, 'C');
      expect(restored.topic, 'Algorithms');
    });
  });

  group('QuizAttempt', () {
    test('toMap / fromMap round-trip with paper and answers', () {
      final attempt = QuizAttempt(
        quizId: 'flutter_basics',
        quizTitle: 'Flutter Basics',
        totalQuestions: 2,
        correctAnswers: 1,
        scorePercent: 50,
        questionsOrder: const ['q2', 'q1'],
        answers: const [
          QuestionAnswer(
            questionId: 'q2',
            questionText: 'Q2',
            topic: 'Widgets',
            selectedIndex: 0,
            correctIndex: 0,
            selectedText: 'A',
            correctText: 'A',
            isCorrect: true,
            explanation: 'Exp',
          ),
          QuestionAnswer(
            questionId: 'q1',
            questionText: 'Q1',
            topic: 'State',
            selectedIndex: 1,
            correctIndex: 2,
            selectedText: 'B',
            correctText: 'C',
            isCorrect: false,
            explanation: '',
          ),
        ],
        completedAt: DateTime.utc(2026, 1, 1),
      );

      final restored = QuizAttempt.fromMap(attempt.toMap());

      expect(restored.quizId, attempt.quizId);
      expect(restored.questionsOrder, ['q2', 'q1']);
      expect(restored.answers.length, 2);
      expect(restored.answers[0].isCorrect, isTrue);
      expect(restored.answers[1].isCorrect, isFalse);
      expect(restored.answers[1].selectedIndex, 1);
    });
  });

  group('Quiz', () {
    test('fromMap reads metadata and paper size', () {
      final quiz = Quiz.fromMap({
        'id': 'quiz',
        'title': 'T',
        'description': 'D',
        'category': 'Mobile',
        'difficulty': 'Beginner',
        'tags': ['Flutter', 'Dart'],
        'time_limit_seconds': 20,
        'paper_size': 5,
        'questions': [],
      });

      expect(quiz.category, 'Mobile');
      expect(quiz.difficulty, 'Beginner');
      expect(quiz.tags, ['Flutter', 'Dart']);
      expect(quiz.timeLimitSeconds, 20);
      expect(quiz.paperSize, 5);
    });

    test('toMap round-trips through fromMap (cache format)', () {
      const quiz = Quiz(
        id: 'q',
        title: 'T',
        description: 'D',
        category: 'Mobile',
        difficulty: 'Beginner',
        tags: ['Flutter'],
        timeLimitSeconds: 20,
        paperSize: 3,
        questions: [
          Question(
            id: 'q1',
            text: 'Question?',
            options: ['A', 'B'],
            correctIndex: 1,
            explanation: 'Exp',
            topic: 'OOP',
          ),
        ],
      );

      final restored = Quiz.fromMap(quiz.toMap());

      expect(restored.id, quiz.id);
      expect(restored.category, quiz.category);
      expect(restored.difficulty, quiz.difficulty);
      expect(restored.tags, quiz.tags);
      expect(restored.timeLimitSeconds, 20);
      expect(restored.paperSize, 3);
      expect(restored.questions.length, 1);
      expect(restored.questions.first.correctIndex, 1);
      expect(restored.questions.first.topic, 'OOP');
    });
  });
}
