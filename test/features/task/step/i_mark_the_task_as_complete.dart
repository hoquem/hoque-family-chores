import 'package:flutter_test/flutter_test.dart';

/// Usage: I mark the task as complete
Future<void> iMarkTheTaskAsComplete(WidgetTester tester) async {
  final completeButton = find.text('Complete');
  expect(completeButton, findsOneWidget);
  await tester.tap(completeButton);
  await tester.pumpAndSettle();
}
