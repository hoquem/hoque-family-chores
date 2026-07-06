import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I tap the increment button
Future<void> iTapTheIncrementButton(WidgetTester tester) async {
  final button = find.byIcon(Icons.add);
  expect(button, findsOneWidget);
  await tester.tap(button);
  await tester.pump();
}
