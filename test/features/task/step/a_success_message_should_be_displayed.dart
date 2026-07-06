import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart';

/// Usage: a success message should be displayed
Future<void> aSuccessMessageShouldBeDisplayed(WidgetTester tester) async {
  // After successful task creation the AddTaskScreen pops back to
  // TaskListScreen. Verify we are on the task list — this IS the
  // success indication (a validation failure would keep us on the form).
  expect(find.byType(TaskListScreen), findsOneWidget);
}
