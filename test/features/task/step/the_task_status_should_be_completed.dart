import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the task status should be "completed"
Future<void> theTaskStatusShouldBeCompleted(WidgetTester tester) async {
  // Find "Completed" within the "Pending task" card specifically,
  // to avoid false positives from other completed tasks in the list.
  final pendingCard = find.ancestor(
    of: find.text('Pending task'),
    matching: find.byType(Card),
  );
  expect(
    find.descendant(of: pendingCard, matching: find.text('Completed')),
    findsOneWidget,
  );
}
