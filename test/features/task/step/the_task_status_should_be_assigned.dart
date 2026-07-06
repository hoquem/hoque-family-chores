import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';

/// Usage: the task status should be "assigned"
Future<void> theTaskStatusShouldBeAssigned(WidgetTester tester) async {
  // Find "Assigned" within the "Take out trash" card specifically.
  final trashCard = find.ancestor(
    of: find.text('Take out trash'),
    matching: find.byType(Card),
  );
  expect(
    find.descendant(of: trashCard, matching: find.text('Assigned')),
    findsOneWidget,
  );
}
