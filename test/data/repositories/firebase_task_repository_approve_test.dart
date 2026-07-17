// Approving a task awards its stars, and it does so exactly once.
//
// The use-case tests (self_approval_test.dart) prove who may approve. These
// prove the part that only lives in the repository: the status flip to
// completed and the star award to the assignee commit together, and the in-
// transaction status re-read refuses a second approval. Runs against
// fake_cloud_firestore because a mock can't show a transaction.
//
// Sequential, like the reward suite: they prove the guard exists (approve once,
// then watch the retry refuse and award nothing), not that Firestore's
// concurrent retry works.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/data/repositories/firebase_task_repository.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';

final _familyId = FamilyId('fam1');
final _taskId = TaskId('task1');
const _assigneeId = 'kid1';

Future<(FakeFirebaseFirestore, FirebaseTaskRepository)> _seed({
  required int balance,
  int points = 100,
  TaskStatus status = TaskStatus.pendingApproval,
  String? assigneeId = _assigneeId,
}) async {
  final db = FakeFirebaseFirestore();
  await db.collection('users').doc(_assigneeId).set({'points': balance});
  await db
      .collection('families')
      .doc(_familyId.value)
      .collection('tasks')
      .doc(_taskId.value)
      .set({
    'title': 'Tidy room',
    'status': status.name,
    'assignedToId': assigneeId,
    'points': points,
  });
  return (db, FirebaseTaskRepository(firestore: db));
}

Future<int> _points(FakeFirebaseFirestore db) async =>
    ((await db.collection('users').doc(_assigneeId).get()).data()!['points']
            as num)
        .toInt();

Future<String> _status(FakeFirebaseFirestore db) async =>
    (await db
            .collection('families')
            .doc(_familyId.value)
            .collection('tasks')
            .doc(_taskId.value)
            .get())
        .data()!['status'] as String;

void main() {
  test('approving awards the stars AND completes the task', () async {
    final (db, repo) = await _seed(balance: 50, points: 100);

    await repo.approveTask(_familyId, _taskId);

    expect(await _points(db), 150, reason: '50 + 100 awarded');
    expect(await _status(db), 'completed');
  });

  test('approving an already-completed task throws and awards nothing',
      () async {
    // The double-award exploit: approve, then approve again. The in-transaction
    // status re-read must refuse the second, or the child is paid twice.
    final (db, repo) =
        await _seed(balance: 150, points: 100, status: TaskStatus.completed);

    await expectLater(
      () => repo.approveTask(_familyId, _taskId),
      throwsA(isA<DataException>()),
    );

    expect(await _points(db), 150, reason: 'no second award');
  });

  test('approving twice in a row awards exactly once', () async {
    final (db, repo) = await _seed(balance: 0, points: 100);

    await repo.approveTask(_familyId, _taskId);
    await expectLater(
      () => repo.approveTask(_familyId, _taskId),
      throwsA(isA<DataException>()),
    );

    expect(await _points(db), 100, reason: 'awarded once, not twice');
  });

  test('a task with no assignee throws rather than awarding to no one',
      () async {
    final (db, repo) = await _seed(balance: 0, assigneeId: null);

    await expectLater(
      () => repo.approveTask(_familyId, _taskId),
      throwsA(isA<DataException>()),
    );
    expect(await _status(db), 'pendingApproval', reason: 'nothing changed');
  });

  test('a missing task throws', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirebaseTaskRepository(firestore: db);

    await expectLater(
      () => repo.approveTask(_familyId, TaskId('ghost')),
      throwsA(isA<DataException>()),
    );
  });
}
