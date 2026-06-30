import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:football_ai_app/main.dart';

void main() {
  testWidgets('Football AI app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FootballAiApp());

    expect(find.text('Football AI'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
