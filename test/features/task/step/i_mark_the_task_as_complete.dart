import 'package:flutter_test/flutter_test.dart';

/// Usage: I mark the task as complete
Future<void> iMarkTheTaskAsComplete(WidgetTester tester) async {
  // The TaskListTile button label is "Done" (not "Mark as Done").
  final completeButton = find.text('Done');
  expect(completeButton, findsOneWidget);
  await tester.tap(completeButton);
  await tester.pumpAndSettle();
}
