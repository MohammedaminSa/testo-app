import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testo/models/models.dart';
import 'package:testo/providers/progress_providers.dart';
import 'package:testo/providers/quiz_providers.dart';
import 'package:testo/screens/home_screen.dart';

import 'helpers/fakes.dart';

/// Test doubles for the quiz catalog states, so HomeScreen tests don't depend
/// on the cache/demo fallback logic in [QuizListNotifier].
class FixedQuizListNotifier extends QuizListNotifier {
  FixedQuizListNotifier(this._quizzes);

  final List<Quiz> _quizzes;

  @override
  Future<List<Quiz>> build() async => _quizzes;
}

class LoadingQuizListNotifier extends QuizListNotifier {
  @override
  Future<List<Quiz>> build() => Completer<List<Quiz>>().future;
}

class ErrorQuizListNotifier extends QuizListNotifier {
  @override
  Future<List<Quiz>> build() async => throw Exception('network down');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Map<String, dynamic> stats() => {
        'totalAttempts': 3,
        'avgScore': 70.0,
        'bestScore': 90.0,
        'totalCorrect': 9,
        'totalAnswered': 12,
        'quizzesTaken': 1,
        'weakTopics': <String>['Math'],
        'weakTopicCount': 1,
      };

  Widget buildTestApp({
    required List<Quiz> quizzes,
    required QuizListNotifier Function() quizNotifier,
    AsyncValue<Map<String, dynamic>>? statsValue,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/quiz',
          builder: (context, state) =>
              Scaffold(body: Text('Quiz: ${(state.extra as Quiz).title}')),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('History screen'))),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Profile screen'))),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        quizListProvider.overrideWith(quizNotifier),
        statsProvider.overrideWithValue(statsValue ?? AsyncData(stats())),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('HomeScreen', () {
    testWidgets('renders quiz cards and stats', (tester) async {
      await tester.pumpWidget(buildTestApp(
        quizzes: [sampleQuiz()],
        quizNotifier: () => FixedQuizListNotifier([sampleQuiz()]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Available Quizzes'), findsOneWidget);
      expect(find.text('Sample Quiz'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Math'), findsOneWidget);
    });

    testWidgets('shows a loading spinner while quizzes load', (tester) async {
      await tester.pumpWidget(buildTestApp(
        quizzes: const [],
        quizNotifier: () => LoadingQuizListNotifier(),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows an error state with a retry button', (tester) async {
      await tester.pumpWidget(buildTestApp(
        quizzes: const [],
        quizNotifier: () => ErrorQuizListNotifier(),
      ));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Could not load quizzes'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('opens a quiz when a card is tapped', (tester) async {
      await tester.pumpWidget(buildTestApp(
        quizzes: [sampleQuiz()],
        quizNotifier: () => FixedQuizListNotifier([sampleQuiz()]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sample Quiz'));
      await tester.pumpAndSettle();

      expect(find.text('Quiz: Sample Quiz'), findsOneWidget);
    });
  });
}