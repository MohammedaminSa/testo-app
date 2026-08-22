import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gcse_ace/main.dart';

void main() {
  testWidgets('App starts on the Home tab', (WidgetTester tester) async {
    await tester.pumpWidget(const GcseAceApp());

    expect(find.text('Welcome back!'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const GcseAceApp());

    await tester.tap(find.byIcon(Icons.description_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Past papers coming soon'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Study materials coming soon'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('Profile coming soon'), findsOneWidget);
  });
}
