import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/task_id.dart';
import '../../value_objects/family_id.dart';

/// Use case for unassigning tasks
class UnassignTaskUseCase {
  final TaskRepository _taskRepository;

  UnassignTaskUseCase(this._taskRepository);

  /// Unassigns a task (removes assignment)
  /// 
  /// [taskId] - ID of the task to unassign
  /// [familyId] - ID of the family the task belongs to
  ///
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required TaskId taskId,
    required FamilyId familyId,
  }) async {
    try {
      // Validate task ID
      if (taskId.value.trim().isEmpty) {
        return Left(ValidationFailure('Task ID cannot be empty'));
      }

      // Photos first, then unassign. A task returned to the pool must carry
      // nothing from its previous holder: if the before photo survived, the
      // next child would start against a stranger's mess and have their
      // "after" judged against a room they never saw.
      //
      // This deliberately fails the unassign if it fails, which is the
      // opposite of the approval path. There the task was already approved and
      // the photos were spent, so a failed delete only leaked storage. Here
      // the photo is still live evidence, so a task returned with it intact is
      // wrong — better to fail and let the child retry.
      //
      // Ordered photos-first for the same reason: unassign first and another
      // child could claim the task in the gap.
      await _taskRepository.clearPhotos(familyId, taskId);

      await _taskRepository.unassignTask(familyId, taskId);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to unassign task: $e'));
    }
  }
} 