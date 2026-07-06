import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import '../test_helpers.dart';

/// Usage: I have a task "Clean room" assigned to me
Future<void> iHaveATaskCleanRoomAssignedToMe(WidgetTester tester) async {
  final ctx = TaskTestContext.instance;
  final user = ctx.currentUser!;

  // Inject a task assigned to the current user.
  await injectTask(
    tester,
    Task(
      id: TaskId('task_clean_room'),
      title: 'Clean room',
      description: 'Clean your bedroom',
      status: TaskStatus.assigned,
      difficulty: TaskDifficulty.medium,
      dueDate: DateTime.now().add(const Duration(days: 1)),
      assignedToId: user.id,
      createdById: UserId('user_1'),
      createdAt: DateTime.now(),
      points: Points(25),
      tags: const ['cleaning'],
      familyId: FamilyId('family_1'),
    ),
  );
}
