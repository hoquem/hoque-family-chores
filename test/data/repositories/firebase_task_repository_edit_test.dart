// editTaskDetails is the optimistic-concurrency edit path. Its guard only
// lives in the repository transaction (a mock can't show one), so these run
// against fake_cloud_firestore: seed a version, then prove a stale base is
// refused, a deleted task is refused, and a successful edit touches only the
// detail fields (never a concurrent claim's status/assignee) and bumps version.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/data/repositories/firebase_task_repository.dart';
import 'package:hoque_family_chores/data/services/photo_storage_service.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockPhotoStorage extends Mock implements PhotoStorageService {}

FirebaseTaskRepository _repo(FakeFirebaseFirestore db) =>
    FirebaseTaskRepository(firestore: db, photoStorage: _MockPhotoStorage());

final _familyId = FamilyId('fam1');
final _taskId = TaskId('task1');

Future<FakeFirebaseFirestore> _seedTask({
  int? version,
  String status = 'assigned',
  String? assignedToId = 'kid1',
}) async {
  final db = FakeFirebaseFirestore();
  await db
      .collection('families')
      .doc(_familyId.value)
      .collection('tasks')
      .doc(_taskId.value)
      .set({
    'title': 'Old title',
    'description': 'Old description',
    'status': status,
    'difficulty': 'easy',
    'points': 10,
    'assignedToId': assignedToId,
    'requiresPhotoProof': false,
    if (version != null) 'version': version,
  });
  return db;
}

Future<Map<String, dynamic>> _doc(FakeFirebaseFirestore db) async =>
    (await db
            .collection('families')
            .doc(_familyId.value)
            .collection('tasks')
            .doc(_taskId.value)
            .get())
        .data()!;

Future<void> _edit(FirebaseTaskRepository repo, {required int baseVersion}) =>
    repo.editTaskDetails(
      familyId: _familyId,
      taskId: _taskId,
      baseVersion: baseVersion,
      title: 'New title',
      description: 'New description',
      difficulty: TaskDifficulty.hard,
      points: Points(50),
      dueDate: DateTime(2026, 8, 1),
      requiresPhotoProof: true,
    );

void main() {
  group('editTaskDetails optimistic concurrency', () {
    test('matching base version applies detail edits and bumps version',
        () async {
      final db = await _seedTask(version: 3);
      await _edit(_repo(db), baseVersion: 3);

      final data = await _doc(db);
      expect(data['title'], 'New title');
      expect(data['description'], 'New description');
      expect(data['difficulty'], 'hard');
      expect(data['points'], 50);
      expect(data['requiresPhotoProof'], true);
      expect(data['version'], 4);
    });

    test('a concurrent claim (status/assignee) is never clobbered', () async {
      // Task is assigned to a kid; the parent edits only the title.
      final db = await _seedTask(version: 0, status: 'assigned', assignedToId: 'kid1');
      await _edit(_repo(db), baseVersion: 0);

      final data = await _doc(db);
      expect(data['title'], 'New title'); // edit landed
      expect(data['status'], 'assigned'); // claim preserved
      expect(data['assignedToId'], 'kid1'); // assignee preserved
    });

    test('stale base version is refused with ConflictException', () async {
      // Someone else already advanced the task to version 2.
      final db = await _seedTask(version: 2);
      expect(
        () => _edit(_repo(db), baseVersion: 1),
        throwsA(isA<ConflictException>()),
      );
      // The task is left untouched.
      final data = await _doc(db);
      expect(data['title'], 'Old title');
      expect(data['version'], 2);
    });

    test('a legacy task with no version reads as 0 and edits once', () async {
      final db = await _seedTask(version: null);
      await _edit(_repo(db), baseVersion: 0);
      expect((await _doc(db))['version'], 1);
    });

    test('editing a deleted task throws NotFoundException', () async {
      final db = FakeFirebaseFirestore(); // task never created
      expect(
        () => _edit(_repo(db), baseVersion: 0),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
