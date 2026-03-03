import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I enter task title {title}
Future<void> iEnterTaskTitle(WidgetTester tester, String title) async {
  final titleField = find.byKey(const Key('task_title_field'));
  expect(titleField, findsOneWidget);
  await tester.enterText(titleField, title);
  await tester.pump();
}
