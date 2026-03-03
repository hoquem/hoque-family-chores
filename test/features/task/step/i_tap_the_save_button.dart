import 'package:flutter_test/flutter_test.dart';

/// Usage: I tap the save button
Future<void> iTapTheSaveButton(WidgetTester tester) async {
  final saveButton = find.text('Save');
  expect(saveButton, findsOneWidget);
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}
