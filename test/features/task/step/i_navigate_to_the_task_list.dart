import 'package:flutter_test/flutter_test.dart';

/// Usage: I navigate to the task list
Future<void> iNavigateToTheTaskList(WidgetTester tester) async {
  // We pump TaskListScreen directly, so we are already on the task list.
  await tester.pumpAndSettle();
}
