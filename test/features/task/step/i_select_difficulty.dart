import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Difficulty label prefixes used in the AddTaskScreen dropdown.
const _difficultyLabels = {
  'easy': 'Small (S)',
  'medium': 'Medium (M)',
  'hard': 'Large (L)',
  'challenging': 'Extra Large (XL)',
};

/// Usage: I select difficulty {difficulty}
Future<void> iSelectDifficulty(WidgetTester tester, String difficulty) async {
  final dropdown = find.byKey(const Key('task_difficulty_dropdown'));
  expect(dropdown, findsOneWidget);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();

  // The dropdown items show full descriptions like
  // "Small (S) - Quick tasks, 5-15 minutes (10 ⭐)".
  // Match by the prefix label.
  final prefix = _difficultyLabels[difficulty] ?? difficulty;
  final option = find.textContaining(prefix).last;
  await tester.tap(option);
  await tester.pumpAndSettle();
}
