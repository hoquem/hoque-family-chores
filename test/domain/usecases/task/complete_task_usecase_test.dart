// The domain half of the before-photo bypass.
//
// Task 7 removed "Done" from the assigned arm for photo-proof tasks. That is
// the UI, and the UI is not a security boundary: a bug elsewhere, a stale
// widget, or a future caller must not be able to complete a photo-proof task
// that was never started and therefore has no before photo.
//
// The guard is widened AND narrowed here. It gains `inProgress` (or every
// photo-proof task becomes uncompletable — the single most likely way to ship
// this broken) and it loses `assigned`, but only for photo-proof tasks.
import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/repositories/task_repository.dart';
import 'package:hoque_family_chores/domain/usecases/task/complete_task_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

final _me = UserId('kid1');
final _familyId = FamilyId('fam1');
final _taskId = TaskId('task1');

Task _task({
  required TaskStatus status,
  required bool requiresPhotoProof,
}) =>
    Task(
      id: _taskId,
      title: 'Mop the kitchen floor',
      description: '',
      status: status,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 7, 20),
      assignedToId: _me,
      createdAt: DateTime(2026, 7, 16),
      points: Points(10),
      tags: const [],
      familyId: _familyId,
      requiresPhotoProof: requiresPhotoProof,
      beforePhotoUrl:
          status == TaskStatus.inProgress ? 'https://example.com/b.jpg' : null,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FamilyId('fallback'));
    registerFallbackValue(TaskId('fallback'));
  });

  late _MockTaskRepository repo;
  late CompleteTaskUseCase useCase;

  setUp(() {
    repo = _MockTaskRepository();
    useCase = CompleteTaskUseCase(repo);
    when(() => repo.completeTask(any(), any())).thenAnswer((_) async {});
  });

  /// Stubs the repository to return a task in [status] and completes it.
  Future<Either<Failure, Task>> complete({
    required TaskStatus status,
    required bool proof,
  }) {
    when(() => repo.getTask(_familyId, _taskId)).thenAnswer(
      (_) async => _task(status: status, requiresPhotoProof: proof),
    );
    return useCase(taskId: _taskId, userId: _me, familyId: _familyId);
  }

  group('a photo-proof task', () {
    test('can be completed once started', () async {
      final result = await complete(status: TaskStatus.inProgress, proof: true);
      expect(result.isRight(), isTrue,
          reason: 'if inProgress were not allowed, every photo-proof task '
              'would be permanently uncompletable');
      verify(() => repo.completeTask(_familyId, _taskId)).called(1);
    });

    test('CANNOT be completed straight from assigned — the bypass', () async {
      final result = await complete(status: TaskStatus.assigned, proof: true);

      expect(result.isLeft(), isTrue,
          reason: 'completing from assigned skips Start, so no before photo '
              'was ever taken and the feature is decorative');
      verifyNever(() => repo.completeTask(any(), any()));
    });

    test('can be resubmitted after a rejection', () async {
      // Rework overwrites the after photo while the before persists — the room
      // was only messy once. Forcing a re-Start would demand a photo of a mess
      // that no longer exists.
      final result =
          await complete(status: TaskStatus.needsRevision, proof: true);
      expect(result.isRight(), isTrue);
    });
  });

  group('an ordinary task is untouched', () {
    test('still completes straight from assigned', () async {
      final result = await complete(status: TaskStatus.assigned, proof: false);
      expect(result.isRight(), isTrue,
          reason: 'the flag defaults off; existing behaviour must not change');
    });

    test('still completes after a rejection', () async {
      final result =
          await complete(status: TaskStatus.needsRevision, proof: false);
      expect(result.isRight(), isTrue);
    });

    test('cannot be completed before it is claimed', () async {
      final result = await complete(status: TaskStatus.available, proof: false);
      expect(result.isLeft(), isTrue);
    });
  });
}
