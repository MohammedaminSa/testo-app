import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gcse_ace/screens/auth/sign_in_screen.dart';
import 'package:gcse_ace/shell/app_shell.dart';

void main() {
  testWidgets('AppShell starts on the Home tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AppShell())),
    );

    expect(find.text('Welcome back!'), findsOneWidget);
  });

  testWidgets('AppShell bottom navigation switches tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AppShell())),
    );

    await tester.tap(find.byIcon(Icons.description_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Past papers coming soon'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Study materials coming soon'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('Signed in as:'), findsOneWidget);
  });

  testWidgets('SignInScreen shows the sign-in form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
