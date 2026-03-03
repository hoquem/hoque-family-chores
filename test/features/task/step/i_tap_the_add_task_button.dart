import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I tap the add task button
Future<void> iTapTheAddTaskButton(WidgetTester tester) async {
  final addButton = find.byIcon(Icons.add);
  expect(addButton, findsOneWidget);
  await tester.tap(addButton);
  await tester.pumpAndSettle();
}
