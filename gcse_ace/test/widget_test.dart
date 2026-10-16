import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gcse_ace/screens/auth/sign_in_screen.dart';
import 'package:gcse_ace/screens/materials_screen.dart';
import 'package:gcse_ace/screens/papers_screen.dart';
import 'package:gcse_ace/screens/profile_screen.dart';
import 'package:gcse_ace/shell/app_shell.dart';

Future<void> pumpShell(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: AppShell())),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('AppShell starts on the Home tab', (WidgetTester tester) async {
    await pumpShell(tester);

    expect(find.text('Subjects'), findsOneWidget);
    expect(find.text('Revise smarter,\nnot longer.'), findsOneWidget);
    expect(find.text('Start practising'), findsOneWidget);
  });

  testWidgets('AppShell bottom navigation switches tabs', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.byIcon(Icons.description_outlined));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PapersScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MaterialsScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('SignInScreen shows the sign-in form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });
}
