import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/services/task_ordering.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';

Task _task(String title, TaskStatus status,
        [DateTime? createdAt]) =>
    Task(
      id: TaskId(title),
      title: title,
      description: '',
      status: status,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 8, 1),
      createdAt: createdAt ?? DateTime(2026, 7, 1),
      points: Points(10),
      tags: const [],
      familyId: FamilyId('fam1'),
    );

void main() {
  test('groups: unclaimed, then claimed, then done (last)', () {
    final done = _task('aaa done', TaskStatus.completed);
    final claimed = _task('mmm claimed', TaskStatus.assigned);
    final free = _task('zzz free', TaskStatus.available);

    // Deliberately reversed alphabetically vs. the desired group order, so
    // grouping — not the title — is what puts them in order.
    final ordered = tasksForDisplay([done, claimed, free]);

    expect(ordered.map((t) => t.title),
        ['zzz free', 'mmm claimed', 'aaa done'],
        reason: 'unclaimed first, claimed next, completed last');
  });

  test('a completed task never sits at the top, even with a low title', () {
    // The reported bug: a completed lowercase-titled task floated to the top.
    final done = _task('apple', TaskStatus.completed);
    final free = _task('oranges', TaskStatus.available);

    final ordered = tasksForDisplay([done, free]);

    expect(ordered.map((t) => t.title), ['oranges', 'apple']);
  });

  test('within a group, titles sort alphabetically and case-insensitively', () {
    final input = [
      _task('Zebra', TaskStatus.available),
      _task('apple', TaskStatus.available),
      _task('Mango', TaskStatus.available),
    ];

    final ordered = tasksForDisplay(input).map((t) => t.title).toList();

    // Case-insensitive: a naive compareTo would put 'Zebra' before 'apple'.
    expect(ordered, ['apple', 'Mango', 'Zebra']);
  });

  test('newest-first only breaks a title tie', () {
    final older = _task('chores', TaskStatus.available, DateTime(2026, 7, 1));
    final newer = _task('chores', TaskStatus.available, DateTime(2026, 7, 18));

    final ordered = tasksForDisplay([older, newer]);

    expect(ordered.map((t) => t.createdAt),
        [DateTime(2026, 7, 18), DateTime(2026, 7, 1)]);
  });

  test('does not mutate the input list', () {
    final input = [
      _task('a', TaskStatus.assigned),
      _task('b', TaskStatus.available),
    ];
    final before = input.map((t) => t.title).toList();

    tasksForDisplay(input);

    expect(input.map((t) => t.title).toList(), before);
  });
}
