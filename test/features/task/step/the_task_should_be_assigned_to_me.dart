import 'package:flutter_test/flutter_test.dart';

/// Usage: the task should be assigned to me
Future<void> theTaskShouldBeAssignedToMe(WidgetTester tester) async {
  // After claiming, the task tile shows "Assigned" status text.
  expect(find.text('Assigned'), findsWidgets);
}
