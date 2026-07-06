import 'package:flutter_test/flutter_test.dart';

/// Usage: I tap the save button
Future<void> iTapTheSaveButton(WidgetTester tester) async {
  // The AddTaskScreen uses "Create Quest" as the submit button label.
  final saveButton = find.text('Create Quest');
  expect(saveButton, findsOneWidget);
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}
