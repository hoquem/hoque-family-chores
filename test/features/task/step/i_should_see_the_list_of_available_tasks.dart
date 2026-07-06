import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I should see the list of available tasks
Future<void> iShouldSeeTheListOfAvailableTasks(WidgetTester tester) async {
  expect(find.byType(ListView), findsOneWidget);
}
