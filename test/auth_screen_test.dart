import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:testo/main.dart';
import 'package:testo/providers/auth_providers.dart';
import 'package:testo/screens/auth_screen.dart';

import 'helpers/fakes.dart';

void main() {
  Widget buildTestApp(FakeAuthRepository auth) {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: MaterialApp(
        builder: (context, child) =>
            MessageHost(child: child ?? const SizedBox.shrink()),
        home: const AuthScreen(),
      ),
    );
  }

  group('AuthScreen', () {
    testWidgets('shows validation errors for an empty form', (tester) async {
      final auth = FakeAuthRepository();
      await tester.pumpWidget(buildTestApp(auth));

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      expect(auth.signInCalls, 0);
    });

    testWidgets('signs in with valid credentials', (tester) async {
      final auth = FakeAuthRepository();
      await tester.pumpWidget(buildTestApp(auth));

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(auth.signInCalls, 1);
      expect(auth.lastSignInEmail, 'a@b.com');
    });

    testWidgets('shows an error snackbar when sign in fails', (tester) async {
      final auth = FakeAuthRepository()
        ..signInError = const AuthException('Invalid login credentials');
      await tester.pumpWidget(buildTestApp(auth));

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid login credentials'), findsOneWidget);
    });
  });
}