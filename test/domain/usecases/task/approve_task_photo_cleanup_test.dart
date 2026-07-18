// On approval the after-photo is no longer just deleted — it is PROMOTED to the
// family's Home background (the room they just cleaned), which keeps that file
// and retires the rest. A chore with no after-photo still just clears.
//
// The subtle requirement is the negative one, unchanged: cleanup must NEVER fail
// the approval. Tapping Approve is the core loop; a storage hiccup must not break
// it. A failure there leaks a blob — a cost leak, not a correctness bug.
//
// The star award commits inside the approveTask transaction (before cleanup), so
// "approveTask was called" means "the child was paid"; the award's atomicity is
// proved in firebase_task_repository_approve_test.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/repositories/task_repository.dart';
import 'package:hoque_family_chores/domain/usecases/task/approve_task_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

final _kid = UserId('kid1');
final _parent = UserId('parent1');
final _familyId = FamilyId('fam1');
final _taskId = TaskId('task1');

Task _task({required TaskStatus status, String? afterPhoto}) => Task(
      id: _taskId,
      title: 'Mop the kitchen floor',
      description: '',
      status: status,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 7, 20),
      assignedToId: _kid,
      createdAt: DateTime(2026, 7, 16),
      points: Points(10),
      tags: const [],
      familyId: _familyId,
      requiresPhotoProof: true,
      beforePhotoUrl: 'https://example.com/before.jpg',
      photoUrl: afterPhoto,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FamilyId('fallback'));
    registerFallbackValue(TaskId('fallback'));
  });

  late _MockTaskRepository tasks;
  late ApproveTaskUseCase useCase;

  setUp(() {
    tasks = _MockTaskRepository();
    useCase = ApproveTaskUseCase(tasks);
    when(() => tasks.approveTask(any(), any())).thenAnswer((_) async {});
    when(() => tasks.clearPhotos(any(), any())).thenAnswer((_) async {});
    when(() => tasks.promoteAfterPhotoToBackground(any(), any()))
        .thenAnswer((_) async {});
  });

  void seed({required TaskStatus status, String? afterPhoto}) {
    when(() => tasks.getTask(_familyId, _taskId)).thenAnswer(
        (_) async => _task(status: status, afterPhoto: afterPhoto));
  }

  Future<void> approve() => useCase(
        taskId: _taskId,
        approverId: _parent,
        familyId: _familyId,
      ).then((_) {});

  test('with an after-photo, approval promotes it to the family background',
      () async {
    seed(
        status: TaskStatus.pendingApproval,
        afterPhoto: 'https://example.com/after.jpg');

    await approve();

    verify(() => tasks.promoteAfterPhotoToBackground(_familyId, _taskId))
        .called(1);
    verifyNever(() => tasks.clearPhotos(any(), any()));
  });

  test('with no after-photo, approval just clears', () async {
    seed(status: TaskStatus.pendingApproval, afterPhoto: null);

    await approve();

    verify(() => tasks.clearPhotos(_familyId, _taskId)).called(1);
    verifyNever(() => tasks.promoteAfterPhotoToBackground(any(), any()));
  });

  test('a failed promotion does NOT fail the approval', () async {
    seed(
        status: TaskStatus.pendingApproval,
        afterPhoto: 'https://example.com/after.jpg');
    when(() => tasks.promoteAfterPhotoToBackground(any(), any()))
        .thenThrow(Exception('storage unreachable'));

    final result = await useCase(
      taskId: _taskId,
      approverId: _parent,
      familyId: _familyId,
    );

    expect(result.isRight(), isTrue,
        reason: 'the task IS approved; a storage hiccup must not break the loop');
  });

  test('a failed promotion still approves and awards', () async {
    seed(
        status: TaskStatus.pendingApproval,
        afterPhoto: 'https://example.com/after.jpg');
    when(() => tasks.promoteAfterPhotoToBackground(any(), any()))
        .thenThrow(Exception('storage unreachable'));

    await approve();

    verify(() => tasks.approveTask(_familyId, _taskId)).called(1);
  });

  test('cleanup runs after the approval, never before', () async {
    seed(
        status: TaskStatus.pendingApproval,
        afterPhoto: 'https://example.com/after.jpg');

    await approve();

    verifyInOrder([
      () => tasks.approveTask(_familyId, _taskId),
      () => tasks.promoteAfterPhotoToBackground(_familyId, _taskId),
    ]);
  });

  test('a task that cannot be approved keeps its photos', () async {
    seed(
        status: TaskStatus.inProgress,
        afterPhoto: 'https://example.com/after.jpg');

    final result = await useCase(
      taskId: _taskId,
      approverId: _parent,
      familyId: _familyId,
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => tasks.promoteAfterPhotoToBackground(any(), any()));
    verifyNever(() => tasks.clearPhotos(any(), any()));
  });
}
