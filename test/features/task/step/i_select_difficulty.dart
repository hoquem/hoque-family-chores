import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I select difficulty {difficulty}
Future<void> iSelectDifficulty(WidgetTester tester, String difficulty) async {
  final dropdown = find.byKey(const Key('task_difficulty_dropdown'));
  expect(dropdown, findsOneWidget);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();

  final option = find.text(difficulty).last;
  await tester.tap(option);
  await tester.pumpAndSettle();
}
