import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the task status should be "pending_approval"
Future<void> theTaskStatusShouldBePendingApproval(WidgetTester tester) async {
  // Scope to the "Clean room" card to avoid false positives.
  final card = find.ancestor(
    of: find.text('Clean room'),
    matching: find.byType(Card),
  );
  expect(
    find.descendant(of: card, matching: find.text('Pending Approval')),
    findsOneWidget,
  );
}
