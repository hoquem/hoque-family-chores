// A recurring occurrence carries its spawning rule's id through Firestore, and
// a one-off task (no ruleId written, or the field absent) reads back as null.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/repositories/firebase_task_repository.dart';
import 'package:hoque_family_chores/data/services/photo_storage_service.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:mocktail/mocktail.dart';

// Mirror the photo-storage stub from the existing repository tests.
class _MockPhotoStorage extends Mock implements PhotoStorageService {}

Future<Task> writeAndRead(FirebaseTaskRepository repo, Task task) async {
  // createTask assigns an auto-generated id, so match on the one it returns.
  final created = await repo.createTask(task);
  final tasks = await repo.getTasksForFamily(task.familyId);
  return tasks.firstWhere((t) => t.id == created.id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('task with ruleId round-trips ruleId', () async {
    final db = FakeFirebaseFirestore();
    final repo =
        FirebaseTaskRepository(firestore: db, photoStorage: _MockPhotoStorage());
    final task = Task(
      id: TaskId('task-1'),
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
      ruleId: 'rule-1',
    );

    final read = await writeAndRead(repo, task);

    expect(read.ruleId, 'rule-1');
  });

  test('task without ruleId round-trips as null', () async {
    final db = FakeFirebaseFirestore();
    final repo =
        FirebaseTaskRepository(firestore: db, photoStorage: _MockPhotoStorage());
    final task = Task(
      id: TaskId('task-2'),
      title: 'Take out bins',
      description: '',
      status: TaskStatus.available,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 8, 15),
      assignedToId: null,
      createdById: UserId('parent-1'),
      createdAt: DateTime(2026, 8, 14),
      completedAt: null,
      points: Points(10),
      tags: const [],
      recurringPattern: null,
      lastCompletedAt: null,
      familyId: FamilyId('fam-1'),
      requiresPhotoProof: false,
    );

    final read = await writeAndRead(repo, task);

    expect(read.ruleId, isNull);
  });
}
