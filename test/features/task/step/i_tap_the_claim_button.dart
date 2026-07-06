import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I tap the claim button
/// Finds the "Claim" button on the task tile containing "Take out trash".
Future<void> iTapTheClaimButton(WidgetTester tester) async {
  // Find the Claim button that is a descendant of the Card containing
  // "Take out trash" to avoid ambiguity with other Claim buttons.
  final trashCard = find.ancestor(
    of: find.text('Take out trash'),
    matching: find.byType(Card),
  );
  expect(trashCard, findsOneWidget);

  final claimButton = find.descendant(
    of: trashCard,
    matching: find.text('Claim'),
  );
  expect(claimButton, findsOneWidget);
  await tester.tap(claimButton);
  await tester.pumpAndSettle();
}
