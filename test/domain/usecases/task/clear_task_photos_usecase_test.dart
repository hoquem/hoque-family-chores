// Deleting a chore's photos removes them but leaves the chore intact.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/usecases/task/clear_task_photos_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

import '../../../mocks/mock_task_repository.dart';

final _fam = FamilyId('fam1');

Task _taskWithPhotos() => Task(
      id: TaskId('t1'),
      title: 'Clean the bathroom',
      description: '',
      status: TaskStatus.pendingApproval,
      difficulty: TaskDifficulty.hard,
      dueDate: DateTime(2026, 7, 21),
      assignedToId: UserId('kid'),
      createdById: UserId('mum'),
      createdAt: DateTime(2026, 7, 20),
      completedAt: DateTime(2026, 7, 21),
      points: Points(50),
      tags: const [],
      familyId: _fam,
      beforePhotoUrl: 'https://example.com/before.jpg',
      photoUrl: 'https://example.com/after.jpg',
    );

void main() {
  test('clears the before/after photos, leaving the task in place', () async {
    final repo = MockTaskRepository();
    repo.addTaskSync(_taskWithPhotos());

    final result =
        await ClearTaskPhotosUseCase(repo)(taskId: TaskId('t1'), familyId: _fam);

    expect(result.isRight(), isTrue);
    final task = await repo.getTask(_fam, TaskId('t1'));
    expect(task, isNotNull, reason: 'the chore itself must survive');
    expect(task!.beforePhotoUrl, isNull);
    expect(task.photoUrl, isNull);
    expect(task.title, 'Clean the bathroom');
  });
}
