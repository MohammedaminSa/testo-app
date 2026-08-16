import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testo/models/models.dart';
import 'package:testo/providers/progress_providers.dart';
import 'package:testo/screens/quiz_screen.dart';

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
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Review screen'))),
        ),
      ],
    );
    return ProviderScope(
      overrides: [progressRepositoryProvider.overrideWithValue(progress)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('QuizScreen', () {
    testWidgets('answers, advances, and finishes into the review screen',
        (tester) async {
      final quiz = sampleQuiz();
      await tester.pumpWidget(buildTestApp(quiz));
      await tester.pumpAndSettle();

      expect(find.text('What is 2 + 2?'), findsOneWidget);

      await tester.tap(find.text('4'));
      await tester.pump();

      expect(find.text('Explanation'), findsOneWidget);
      expect(find.text('Two plus two equals four.'), findsOneWidget);

      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      expect(find.text('Review screen'), findsOneWidget);
      expect(progress.savedAttempts.length, 1);
      expect(progress.savedAttempts.single.scorePercent, 100);
      expect(progress.savedAttempts.single.correctAnswers, 1);
    });

    testWidgets('saves a failed attempt with a 0% score', (tester) async {
      final quiz = sampleQuiz();
      await tester.pumpWidget(buildTestApp(quiz));
      await tester.pumpAndSettle();

      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      expect(progress.savedAttempts.single.scorePercent, 0);
      expect(progress.savedAttempts.single.correctAnswers, 0);
    });
  });
}