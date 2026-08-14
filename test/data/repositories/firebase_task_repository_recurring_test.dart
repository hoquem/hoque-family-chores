// createRecurringChore atomically writes the first occurrence of a recurring
// chore alongside its rule; deleteRecurringRule stops the series and must be
// idempotent. These run against fake_cloud_firestore because the batch write
// (and its two refs pointing at each other) is the whole point.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/repositories/firebase_task_repository.dart';
import 'package:hoque_family_chores/data/services/photo_storage_service.dart';
import 'package:hoque_family_chores/domain/entities/recurring_rule.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockPhotoStorage extends Mock implements PhotoStorageService {}

Task baseTask() => Task(
      id: TaskId('new'),
      title: 'Clean the bathroom',
      description: '',
      status: TaskStatus.available,
      difficulty: TaskDifficulty.medium,
      dueDate: DateTime(2026, 8, 15),
      assignedToId: null,
      createdById: UserId('parent-1'),
      createdAt: DateTime(2026, 8, 14),
      completedAt: null,
      points: Points(25),
      tags: const [],
      recurringPattern: null,
      lastCompletedAt: null,
      familyId: FamilyId('fam-1'),
      requiresPhotoProof: false,
    );

RecurringRule baseRule() => RecurringRule(
      id: 'new',
      familyId: FamilyId('fam-1'),
      rrule: 'FREQ=WEEKLY;BYDAY=SA',
      title: 'Clean the bathroom',
      description: '',
      difficulty: TaskDifficulty.medium,
      points: Points(25),
      tags: const [],
      requiresPhotoProof: false,
      createdBy: UserId('parent-1'),
      nextDueAt: DateTime(2026, 8, 15),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('createRecurringChore writes task and rule atomically', () async {
    final db = FakeFirebaseFirestore();
    final repo =
        FirebaseTaskRepository(firestore: db, photoStorage: _MockPhotoStorage());

    final created =
        await repo.createRecurringChore(firstTask: baseTask(), rule: baseRule());

    expect(created.ruleId, isNotNull);
    expect(created.id, isNot(TaskId('new')));

    final taskSnap = await db
        .collection('families')
        .doc('fam-1')
        .collection('tasks')
        .doc(created.id.value)
        .get();
    expect(taskSnap.exists, isTrue);
    expect(taskSnap.data()!['ruleId'], created.ruleId);

    final ruleSnap = await db
        .collection('families')
        .doc('fam-1')
        .collection('taskRules')
        .doc(created.ruleId)
        .get();
    expect(ruleSnap.exists, isTrue);
    final rule = ruleSnap.data()!;
    expect(rule['trigger'], {'type': 'schedule', 'rrule': 'FREQ=WEEKLY;BYDAY=SA'});
    expect(rule['enabled'], isTrue);
    expect(rule['lastTaskId'], created.id.value);
    expect((rule['nextDueAt'] as Timestamp).toDate(), DateTime(2026, 8, 15));
    expect((rule['template'] as Map)['title'], 'Clean the bathroom');
    expect(rule['createdBy'], 'parent-1');
    expect(rule.containsKey('assignment'), isFalse); // unassigned → field omitted
  });

  test('createRecurringChore with a fixed child writes assignment and assigned status',
      () async {
    final db = FakeFirebaseFirestore();
    final repo =
        FirebaseTaskRepository(firestore: db, photoStorage: _MockPhotoStorage());
    final task = baseTask().copyWith(assignedToId: UserId('kid-1'));
    final rule = baseRule().copyWith(assignedToId: UserId('kid-1'));

    final created =
        await repo.createRecurringChore(firstTask: task, rule: rule);

    final ruleSnap = await db
        .collection('families')
        .doc('fam-1')
        .collection('taskRules')
        .doc(created.ruleId)
        .get();
    expect(ruleSnap.data()!['assignment'], {'userId': 'kid-1'});
    final taskSnap = await db
        .collection('families')
        .doc('fam-1')
        .collection('tasks')
        .doc(created.id.value)
        .get();
    expect(taskSnap.data()!['status'], 'assigned');
    expect(taskSnap.data()!['assignedToId'], 'kid-1');
  });

  test('deleteRecurringRule deletes the rule and is idempotent', () async {
    final db = FakeFirebaseFirestore();
    final repo =
        FirebaseTaskRepository(firestore: db, photoStorage: _MockPhotoStorage());

    await repo.createRecurringChore(firstTask: baseTask(), rule: baseRule());
    final rules =
        await db.collection('families').doc('fam-1').collection('taskRules').get();
    final ruleId = rules.docs.single.id;

    await repo.deleteRecurringRule(FamilyId('fam-1'), ruleId);
    expect(
      (await db
              .collection('families')
              .doc('fam-1')
              .collection('taskRules')
              .get())
          .docs,
      isEmpty,
    );

    // Deleting again is a no-op, not an error.
    await repo.deleteRecurringRule(FamilyId('fam-1'), ruleId);
  });
}
