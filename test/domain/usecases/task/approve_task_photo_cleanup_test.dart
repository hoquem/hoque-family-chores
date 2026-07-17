// Photos exist to be judged. Once a parent has approved, they are pure cost —
// so approval deletes them, and retention runs Start-to-Approve (hours) rather
// than forever.
//
// The subtle requirement is the negative one: cleanup must NEVER fail the
// approval. A parent tapping Approve is the core loop; a storage hiccup on a
// kitchen wifi must not break it. A failed delete orphans a blob, which is a
// cost leak, not a correctness bug — the cheaper of the two.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/repositories/task_repository.dart';
import 'package:hoque_family_chores/domain/repositories/user_repository.dart';
import 'package:hoque_family_chores/domain/usecases/task/approve_task_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

final _kid = UserId('kid1');
final _parent = UserId('parent1');
final _familyId = FamilyId('fam1');
final _taskId = TaskId('task1');

Task _task({required TaskStatus status}) => Task(
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
      photoUrl: 'https://example.com/after.jpg',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FamilyId('fallback'));
    registerFallbackValue(TaskId('fallback'));
    registerFallbackValue(UserId('fallback'));
    registerFallbackValue(Points(0));
  });

  late _MockTaskRepository tasks;
  late _MockUserRepository users;
  late ApproveTaskUseCase useCase;

  setUp(() {
    tasks = _MockTaskRepository();
    users = _MockUserRepository();
    useCase = ApproveTaskUseCase(tasks, users);

    when(() => tasks.getTask(_familyId, _taskId))
        .thenAnswer((_) async => _task(status: TaskStatus.pendingApproval));
    when(() => tasks.approveTask(any(), any())).thenAnswer((_) async {});
    when(() => tasks.clearPhotos(any(), any())).thenAnswer((_) async {});
    when(() => users.addPoints(any(), any())).thenAnswer((_) async {});
  });

  Future<void> approve() => useCase(
        taskId: _taskId,
        approverId: _parent,
        familyId: _familyId,
      ).then((_) {});

  test('approving deletes the photos', () async {
    await approve();
    verify(() => tasks.clearPhotos(_familyId, _taskId)).called(1);
  });

  test('a failed cleanup does NOT fail the approval', () async {
    when(() => tasks.clearPhotos(any(), any()))
        .thenThrow(Exception('storage unreachable'));

    final result = await useCase(
      taskId: _taskId,
      approverId: _parent,
      familyId: _familyId,
    );

    expect(result.isRight(), isTrue,
        reason: 'the parent tapped Approve and the task IS approved; a storage '
            'hiccup must not break the core loop. The orphaned blob is a cost '
            'leak, not a correctness bug.');
  });

  test('a failed cleanup still awards the points', () async {
    when(() => tasks.clearPhotos(any(), any()))
        .thenThrow(Exception('storage unreachable'));

    await approve();

    verify(() => users.addPoints(_kid, any())).called(1);
  });

  test('cleanup runs after the approval, never before', () async {
    // Order matters: if the photos went first and the approval then failed,
    // the parent would be left judging a task whose evidence had vanished.
    await approve();
    verifyInOrder([
      () => tasks.approveTask(_familyId, _taskId),
      () => tasks.clearPhotos(_familyId, _taskId),
    ]);
  });

  test('a task that cannot be approved keeps its photos', () async {
    when(() => tasks.getTask(_familyId, _taskId))
        .thenAnswer((_) async => _task(status: TaskStatus.inProgress));

    final result = await useCase(
      taskId: _taskId,
      approverId: _parent,
      familyId: _familyId,
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => tasks.clearPhotos(any(), any()));
  });
}
