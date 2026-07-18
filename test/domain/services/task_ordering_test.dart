import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/services/task_ordering.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';

Task _task(String id, TaskStatus status, DateTime createdAt) => Task(
      id: TaskId(id),
      title: id,
      description: '',
      status: status,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 8, 1),
      createdAt: createdAt,
      points: Points(10),
      tags: const [],
      familyId: FamilyId('fam1'),
    );

void main() {
  test('unclaimed (available) tasks come before claimed ones', () {
    final claimed = _task('claimed', TaskStatus.assigned, DateTime(2026, 7, 18));
    final free = _task('free', TaskStatus.available, DateTime(2026, 7, 1));

    final ordered = tasksForDisplay([claimed, free]);

    expect(ordered.map((t) => t.title), ['free', 'claimed'],
        reason: 'the free chore is on top even though it is older');
  });

  test('within a group, newest first', () {
    final older = _task('older', TaskStatus.available, DateTime(2026, 7, 1));
    final newer = _task('newer', TaskStatus.available, DateTime(2026, 7, 18));

    final ordered = tasksForDisplay([older, newer]);

    expect(ordered.map((t) => t.title), ['newer', 'older']);
  });

  test('available-first then newest-first across a mixed list', () {
    final input = [
      _task('assigned-new', TaskStatus.assigned, DateTime(2026, 7, 18)),
      _task('free-old', TaskStatus.available, DateTime(2026, 7, 2)),
      _task('done-mid', TaskStatus.completed, DateTime(2026, 7, 10)),
      _task('free-new', TaskStatus.available, DateTime(2026, 7, 15)),
    ];

    final ordered = tasksForDisplay(input).map((t) => t.title).toList();

    expect(ordered, ['free-new', 'free-old', 'assigned-new', 'done-mid']);
  });

  test('does not mutate the input list', () {
    final input = [
      _task('a', TaskStatus.assigned, DateTime(2026, 7, 1)),
      _task('b', TaskStatus.available, DateTime(2026, 7, 2)),
    ];
    final before = input.map((t) => t.title).toList();

    tasksForDisplay(input);

    expect(input.map((t) => t.title).toList(), before);
  });
}
