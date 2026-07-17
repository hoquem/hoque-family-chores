// The test that proves the feature, rather than proving a task.
//
// Every other test here checks one seam. This walks the whole life of a
// photo-proof task and asserts both photos actually exist at the moment the
// parent judges it. It is the test that would have caught the after-photo
// never being stored at all -- each per-task test was green, and the gap fell
// between them.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/usecases/task/approve_task_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/task/complete_task_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/task/start_task_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

import '../../mocks/mock_task_repository.dart';

const _before = 'https://example.com/before.jpg';
const _after = 'https://example.com/after.jpg';

void main() {
  late MockTaskRepository tasks;
  late FamilyId familyId;
  late UserId kid;
  late TaskId taskId;

  setUp(() async {
    tasks = MockTaskRepository();
    familyId = FamilyId('family_1');
    kid = UserId('user_2');

    final created = await tasks.createTask(
      Task(
        id: TaskId('seed'),
        title: 'Mop the kitchen floor',
        description: 'The whole floor',
        status: TaskStatus.assigned,
        difficulty: TaskDifficulty.easy,
        dueDate: DateTime(2026, 7, 20),
        assignedToId: kid,
        createdAt: DateTime(2026, 7, 16),
        points: Points(10),
        tags: const [],
        familyId: familyId,
        requiresPhotoProof: true,
      ),
    );
    taskId = created.id;
  });

  Future<Task> reload() async => (await tasks.getTask(familyId, taskId))!;

  test('a photo-proof task carries both photos into the approval queue',
      () async {
    // Start: the before photo is captured and the task becomes in-progress.
    final started = await StartTaskUseCase(tasks)(
      taskId: taskId,
      userId: kid,
      familyId: familyId,
      beforePhotoUrl: _before,
    );
    expect(started.isRight(), isTrue);
    expect((await reload()).status, TaskStatus.inProgress);
    expect((await reload()).beforePhotoUrl, _before);

    // Complete: the after photo is stored, then the task is submitted.
    await tasks.setAfterPhoto(familyId, taskId, _after);
    final completed = await CompleteTaskUseCase(tasks)(
      taskId: taskId,
      userId: kid,
      familyId: familyId,
    );
    expect(completed.isRight(), isTrue);

    // The moment that matters: a parent opens the approval queue.
    final forApproval = await reload();
    expect(forApproval.status, TaskStatus.pendingApproval);
    expect(forApproval.beforePhotoUrl, _before,
        reason: 'the parent must see what the room looked like');
    expect(forApproval.photoUrl, _after,
        reason: 'and what it looks like now — without this the whole feature '
            'is a before photo and nothing to compare it to');
  });

  test('approving clears both photos', () async {
    await StartTaskUseCase(tasks)(
      taskId: taskId,
      userId: kid,
      familyId: familyId,
      beforePhotoUrl: _before,
    );
    await tasks.setAfterPhoto(familyId, taskId, _after);
    await CompleteTaskUseCase(tasks)(
      taskId: taskId,
      userId: kid,
      familyId: familyId,
    );

    final approved = await ApproveTaskUseCase(tasks)(
      taskId: taskId,
      approverId: UserId('user_1'),
      familyId: familyId,
    );
    expect(approved.isRight(), isTrue);

    // Retention runs Start-to-Approve. Once judged, the photos are cost.
    final after = await reload();
    expect(after.beforePhotoUrl, isNull);
    expect(after.photoUrl, isNull);
  });

  test('handing the task back drops the before photo with it', () async {
    await StartTaskUseCase(tasks)(
      taskId: taskId,
      userId: kid,
      familyId: familyId,
      beforePhotoUrl: _before,
    );

    await tasks.clearPhotos(familyId, taskId);
    await tasks.unassignTask(familyId, taskId);

    final returned = await reload();
    expect(returned.status, TaskStatus.available);
    expect(returned.beforePhotoUrl, isNull,
        reason: 'the next child must not inherit a stranger\'s mess');
  });
}
