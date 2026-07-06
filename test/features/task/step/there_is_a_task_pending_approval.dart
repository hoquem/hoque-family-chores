import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import '../test_helpers.dart';

/// Usage: there is a task pending approval
Future<void> thereIsATaskPendingApproval(WidgetTester tester) async {
  await injectTask(
    tester,
    Task(
      id: TaskId('task_pending'),
      title: 'Pending task',
      description: 'A task waiting for approval',
      status: TaskStatus.pendingApproval,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime.now().add(const Duration(days: 1)),
      assignedToId: UserId('user_2'),
      createdById: UserId('user_1'),
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      points: Points(10),
      tags: const [],
      familyId: FamilyId('family_1'),
    ),
  );
}
