import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';

Task _makeTask({
  TaskStatus status = TaskStatus.available,
  UserId? assignedToId,
  UserId? createdById,
  DateTime? dueDate,
}) {
  return Task(
    id: TaskId('t1'),
    title: 'Test Task',
    description: 'desc',
    status: status,
    difficulty: TaskDifficulty.easy,
    dueDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
    assignedToId: assignedToId,
    createdById: createdById,
    createdAt: DateTime(2024, 1, 1),
    points: Points(10),
    tags: const ['tag1'],
    familyId: FamilyId('f1'),
  );
}

void main() {
  group('Task', () {
    test('status helpers', () {
      expect(_makeTask(status: TaskStatus.available).isAvailable, true);
      expect(_makeTask(status: TaskStatus.assigned).isAssigned, true);
      expect(_makeTask(status: TaskStatus.completed).isCompleted, true);
      expect(_makeTask(status: TaskStatus.pendingApproval).isPendingApproval, true);
      expect(_makeTask(status: TaskStatus.needsRevision).needsRevision, true);
    });

    test('isOverdue returns true for past due uncompleted task', () {
      final task = _makeTask(
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(task.isOverdue, true);
    });

    test('isOverdue returns false for completed task', () {
      final task = _makeTask(
        status: TaskStatus.completed,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(task.isOverdue, false);
    });

    test('isOverdue returns false for future due date', () {
      expect(_makeTask().isOverdue, false);
    });

    test('isDueToday', () {
      final now = DateTime.now();
      final task = _makeTask(dueDate: DateTime(now.year, now.month, now.day, 15));
      expect(task.isDueToday, true);
    });

    test('isDueTomorrow', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final task = _makeTask(dueDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10));
      expect(task.isDueTomorrow, true);
    });

    test('isAssignedTo', () {
      final task = _makeTask(assignedToId: UserId('u1'));
      expect(task.isAssignedTo(UserId('u1')), true);
      expect(task.isAssignedTo(UserId('u2')), false);
    });

    test('isCreatedBy', () {
      final task = _makeTask(createdById: UserId('u1'));
      expect(task.isCreatedBy(UserId('u1')), true);
      expect(task.isCreatedBy(UserId('u2')), false);
    });

    test('copyWith creates modified copy', () {
      final task = _makeTask();
      final copy = task.copyWith(title: 'New Title', status: TaskStatus.completed);
      expect(copy.title, 'New Title');
      expect(copy.status, TaskStatus.completed);
      expect(copy.id, task.id); // unchanged
    });

    test('equality with same fixed date', () {
      final date = DateTime(2025, 6, 1);
      final a = _makeTask(dueDate: date);
      final b = _makeTask(dueDate: date);
      expect(a, equals(b));
    });
  });

  group('TaskDifficulty', () {
    test('displayName', () {
      expect(TaskDifficulty.easy.displayName, 'Easy');
      expect(TaskDifficulty.medium.displayName, 'Medium');
      expect(TaskDifficulty.hard.displayName, 'Hard');
      expect(TaskDifficulty.challenging.displayName, 'Challenging');
    });

    test('pointsMultiplier', () {
      expect(TaskDifficulty.easy.pointsMultiplier, 1.0);
      expect(TaskDifficulty.medium.pointsMultiplier, 1.5);
      expect(TaskDifficulty.hard.pointsMultiplier, 2.0);
      expect(TaskDifficulty.challenging.pointsMultiplier, 3.0);
    });
  });
}
