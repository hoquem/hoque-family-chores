import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I enter task description {description}
Future<void> iEnterTaskDescription(WidgetTester tester, String description) async {
  final descriptionField = find.byKey(const Key('task_description_field'));
  expect(descriptionField, findsOneWidget);
  await tester.enterText(descriptionField, description);
  await tester.pump();
}
