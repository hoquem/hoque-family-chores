import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The short label each difficulty is offered under in the effort selector.
const _difficultyLabels = {
  'easy': 'S',
  'medium': 'M',
  'hard': 'L',
  'challenging': 'XL',
};

/// Usage: I select difficulty {difficulty}
///
/// Effort size is a four-way segmented control, not a dropdown: one tap on the
/// chip, no menu to open. It was a dropdown whose labels truncated on every
/// phone; see ``test/presentation/add_task_effort_fits_test.dart``.
Future<void> iSelectDifficulty(WidgetTester tester, String difficulty) async {
  final field = find.byKey(const Key('task_difficulty_dropdown'));
  expect(field, findsOneWidget, reason: 'effort size selector should be shown');

  final label = _difficultyLabels[difficulty] ?? difficulty;
  final chip = find.descendant(of: field, matching: find.text(label));
  expect(chip, findsOneWidget, reason: 'no "$label" effort chip found');

  await tester.tap(chip);
  await tester.pumpAndSettle();
}
