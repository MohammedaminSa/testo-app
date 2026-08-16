import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testo/main.dart';
import 'package:testo/models/models.dart';
import 'package:testo/providers/progress_providers.dart';
import 'package:testo/screens/quiz_screen.dart';
import 'package:testo/screens/review_screen.dart';

import 'helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeProgressRepository progress;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    progress = FakeProgressRepository();
  });

  Widget buildTestApp(Quiz quiz) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => QuizScreen(quiz: quiz),
        ),
        GoRoute(
          path: '/review',
          builder: (context, state) {
            final args = state.extra! as ReviewArgs;
            return ReviewScreen(quiz: args.quiz, result: args.result);
          },
        ),
      ],
    );
    return ProviderScope(
      overrides: [progressRepositoryProvider.overrideWithValue(progress)],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) =>
            MessageHost(child: child ?? const SizedBox.shrink()),
      ),
    );
  }

  group('QuizScreen (demo quiz, graded locally)', () {
    testWidgets('shows the explanation after answering', (tester) async {
      await tester.pumpWidget(buildTestApp(sampleQuiz()));
      await tester.pumpAndSettle();

      expect(find.text('What is 2 + 2?'), findsOneWidget);

      await tester.tap(find.text('4'));
      await tester.pump();

      expect(find.text('Explanation'), findsOneWidget);
      expect(find.text('Two plus two equals four.'), findsOneWidget);
    });

    testWidgets('finishing a correct quiz shows a 100% review', (tester) async {
      await tester.pumpWidget(buildTestApp(sampleQuiz()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsOneWidget);
      expect(progress.gradedSubmissions, isEmpty);
    });

    testWidgets('finishing with a wrong answer shows a 0% review',
        (tester) async {
      await tester.pumpWidget(buildTestApp(sampleQuiz()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
    });
  });

  group('QuizScreen (server quiz, graded via RPC)', () {
    testWidgets('submits answers and shows the graded review', (tester) async {
      progress.gradeResultBuilder = (answers) {
        return QuizResult(
          correctCount: answers.length,
          totalQuestions: answers.length,
          scorePercent: 100,
          questionsOrder: [for (final a in answers) a.questionId],
          answers: [
            for (final a in answers)
              QuestionAnswer(
                questionId: a.questionId,
                questionText: 'Is the server the grader?',
                topic: 'Backend',
                selectedIndex: a.selectedIndex,
                correctIndex: 1,
                selectedText: a.selectedIndex == 1 ? 'Yes' : 'No',
                correctText: 'Yes',
                isCorrect: a.selectedIndex == 1,
                explanation: 'The server grades submissions.',
              ),
          ],
        );
      };

      await tester.pumpWidget(buildTestApp(serverQuiz()));
      await tester.pumpAndSettle();

      expect(find.text('Is the server the grader?'), findsOneWidget);

      // No answer is revealed until grading completes.
      await tester.tap(find.text('Yes'));
      await tester.pump();
      expect(find.text('Explanation'), findsNothing);

      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsOneWidget);
      expect(progress.gradedSubmissions, hasLength(1));
      expect(progress.gradedSubmissions.single.single.selectedIndex, 1);
      expect(progress.gradedSubmissions.single.single.questionId, 'qs1');
    });

    testWidgets('shows an error snackbar and lets the user retry when grading '
        'fails', (tester) async {
      progress.gradeError = Exception('offline');

      await tester.pumpWidget(buildTestApp(serverQuiz()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes'));
      await tester.pump();
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      expect(find.text('Review'), findsNothing);
      expect(
        find.textContaining('Could not submit your answers'),
        findsOneWidget,
      );
      expect(progress.gradedSubmissions, hasLength(1));
    });
  });
}