import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:testo/core/config.dart';
import 'package:testo/main.dart' as app;

/// End-to-end flow against a real (test) Supabase project: sign in, take a
/// quiz, and confirm the attempt shows up in history.
///
/// Not run by `flutter test` (it only runs `test/`). Execute on a device or
/// emulator with dart-defines pointing at a dedicated test project:
///
///   flutter test integration_test -d `device` \
///     --dart-define=SUPABASE_URL=https://your-test-project.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=`anon key` \
///     --dart-define=TEST_EMAIL=`test account email` \
///     --dart-define=TEST_PASSWORD=`test account password`
///
/// The test account must already exist (or email confirmation must be
/// disabled) in the test project.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const email = String.fromEnvironment('TEST_EMAIL');
  const password = String.fromEnvironment('TEST_PASSWORD');

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      email,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      password,
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  testWidgets('sign in, take a quiz, and see it in history', (tester) async {
    if (!AppConfig.isConfigured || email.isEmpty || password.isEmpty) {
      markTestSkipped(
        'Set SUPABASE_URL/SUPABASE_ANON_KEY/TEST_EMAIL/TEST_PASSWORD to run.',
      );
      return;
    }

    await app.main();
    await tester.pumpAndSettle();

    // Sign in lands on the home screen with the quiz catalog.
    await signIn(tester);
    expect(find.text('Available Quizzes'), findsOneWidget);

    // Open the first quiz.
    final firstCard = find.byType(Card).first;
    final quizTitle = tester
        .widget<Text>(
          find.descendant(
            of: firstCard,
            matching: find.byType(Text),
          ).first,
        )
        .data;
    await tester.tap(firstCard);
    await tester.pumpAndSettle();

    // Answer every question by picking the first option, then finish.
    while (true) {
      final option = find.byType(InkWell).first;
      if (option.evaluate().isEmpty) break;
      await tester.tap(option);
      await tester.pumpAndSettle();

      final finish = find.text('Finish');
      if (finish.evaluate().isNotEmpty) {
        await tester.tap(finish);
        break;
      }
      final next = find.text('Next');
      if (next.evaluate().isEmpty) break;
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    await tester.pumpAndSettle();

    // The review screen appears after finishing.
    expect(find.text('Review'), findsOneWidget);

    // Back to home, then open history.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();

    // The completed attempt shows up instead of the empty state.
    expect(find.textContaining('No attempts yet'), findsNothing);
    expect(quizTitle, isNotNull);
    expect(find.text(quizTitle!), findsOneWidget);
  });
}