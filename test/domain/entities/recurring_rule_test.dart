import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/recurring_rule.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

void main() {
  RecurringRule buildRule() => RecurringRule(
        id: 'rule-1',
        familyId: FamilyId('fam-1'),
        rrule: 'FREQ=WEEKLY;BYDAY=SA',
        title: 'Clean the bathroom',
        description: '',
        difficulty: TaskDifficulty.medium,
        points: Points(25),
        tags: [],
        requiresPhotoProof: false,
        createdBy: UserId('parent-1'),
        nextDueAt: DateTime(2026, 8, 15),
      );

  test('props cover all fields for equality', () {
    expect(buildRule(), equals(buildRule()));
    expect(buildRule().copyWith(rrule: 'FREQ=DAILY'),
        isNot(equals(buildRule())));
    expect(buildRule().copyWith(title: 'Different'),
        isNot(equals(buildRule())));
    expect(buildRule().copyWith(lastTaskId: 'task-9'),
        isNot(equals(buildRule())));
    expect(buildRule().copyWith(assignedToId: UserId('kid-1')),
        isNot(equals(buildRule())));
  });

  test('copyWith only changes the named field', () {
    final r = buildRule().copyWith(assignedToId: UserId('kid-1'));
    expect(r.assignedToId, UserId('kid-1'));
    expect(r.id, 'rule-1');
    expect(r.nextDueAt, DateTime(2026, 8, 15));
  });
}
