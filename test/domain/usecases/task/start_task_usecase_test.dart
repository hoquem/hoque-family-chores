// Start is the moment the before photo is captured. Its guards are the reason
// a child can never end up mid-chore unable to finish: you cannot start
// without a photo, so you can never be started and photo-less.
import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/repositories/task_repository.dart';
import 'package:hoque_family_chores/domain/usecases/task/start_task_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

final _me = UserId('kid1');
final _someoneElse = UserId('kid2');
final _familyId = FamilyId('fam1');
final _taskId = TaskId('task1');

Task _task({
  required TaskStatus status,
  UserId? assignedToId,
  bool requiresPhotoProof = true,
}) =>
    Task(
      id: _taskId,
      title: 'Mop the kitchen floor',
      description: '',
      status: status,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 7, 20),
      assignedToId: assignedToId,
      createdAt: DateTime(2026, 7, 16),
      points: Points(10),
      tags: const [],
      familyId: _familyId,
      requiresPhotoProof: requiresPhotoProof,
    );

void main() {
  setUpAll(() {
    // mocktail needs a fallback for any non-primitive used with any().
    registerFallbackValue(FamilyId('fallback'));
    registerFallbackValue(TaskId('fallback'));
  });

  late _MockTaskRepository repo;
  late StartTaskUseCase useCase;

  setUp(() {
    repo = _MockTaskRepository();
    useCase = StartTaskUseCase(repo);
  });

  Future<Either<Failure, Task>> start() => useCase(
        taskId: _taskId,
        userId: _me,
        familyId: _familyId,
        beforePhotoUrl: 'https://example.com/before.jpg',
      );

  test('starts an assigned task, storing the before photo', () async {
    when(() => repo.getTask(_familyId, _taskId)).thenAnswer(
      (_) async => _task(status: TaskStatus.assigned, assignedToId: _me),
    );
    when(() => repo.startTask(any(), any(), any())).thenAnswer((_) async {});

    final result = await start();

    expect(result.isRight(), isTrue);
    verify(() => repo.startTask(
          _familyId,
          _taskId,
          'https://example.com/before.jpg',
        )).called(1);
  });

  test('only the assignee may start their own task', () async {
    when(() => repo.getTask(_familyId, _taskId)).thenAnswer(
      (_) async => _task(status: TaskStatus.assigned, assignedToId: _someoneElse),
    );

    final result = await start();

    expect(result.isLeft(), isTrue);
    result.fold((f) => expect(f, isA<PermissionFailure>()), (_) => fail('expected a failure'));
    verifyNever(() => repo.startTask(any(), any(), any()));
  });

  test('a task that is already in progress cannot be started again', () async {
    // Otherwise a second Start would overwrite the before photo with a picture
    // of a room that is already half-tidied.
    when(() => repo.getTask(_familyId, _taskId)).thenAnswer(
      (_) async => _task(status: TaskStatus.inProgress, assignedToId: _me),
    );

    final result = await start();

    expect(result.isLeft(), isTrue);
    verifyNever(() => repo.startTask(any(), any(), any()));
  });

  test('an unclaimed task cannot be started — claim it first', () async {
    when(() => repo.getTask(_familyId, _taskId)).thenAnswer(
      (_) async => _task(status: TaskStatus.available),
    );

    final result = await start();

    expect(result.isLeft(), isTrue);
    verifyNever(() => repo.startTask(any(), any(), any()));
  });

  test('a missing task is a NotFoundFailure, not a crash', () async {
    when(() => repo.getTask(_familyId, _taskId)).thenAnswer((_) async => null);

    final result = await start();

    expect(result.isLeft(), isTrue);
    result.fold((f) => expect(f, isA<NotFoundFailure>()), (_) => fail('expected a failure'));
  });
}
