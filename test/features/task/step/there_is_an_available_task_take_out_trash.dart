import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import '../test_helpers.dart';

/// Usage: there is an available task "Take out trash"
Future<void> thereIsAnAvailableTaskTakeOutTrash(WidgetTester tester) async {
  // The mock repo has "Take out trash" (task_3) as completed.
  // Update it to available using sync methods (avoids test-clock issues).
  final ctx = TaskTestContext.instance;
  ctx.mockTaskRepository.unassignTaskSync(TaskId('task_3'));
  ctx.mockTaskRepository.updateTaskStatusSync(TaskId('task_3'), TaskStatus.available);
  // Refresh the task list UI to reflect the change.
  await refreshTaskList(tester);
}
