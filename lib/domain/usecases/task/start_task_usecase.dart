import 'package:dartz/dartz.dart' hide Task;

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../entities/task.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/task_id.dart';
import '../../value_objects/user_id.dart';

/// Use case for starting a task, capturing the "before" photo.
class StartTaskUseCase {
  final TaskRepository _taskRepository;

  StartTaskUseCase(this._taskRepository);

  /// Moves a task from assigned to in-progress and records its before photo.
  ///
  /// The before photo only exists before the work begins, so it is captured
  /// here rather than at completion. Making it a precondition of starting is
  /// what removes the dead end: a child cannot end up mid-chore and unable to
  /// finish, because they could not have started without it.
  ///
  /// [taskId] - ID of the task to start
  /// [userId] - ID of the user starting the task; must be the assignee
  /// [familyId] - ID of the family the task belongs to
  /// [beforePhotoUrl] - download URL of the already-uploaded before photo
  ///
  /// Returns the updated [Task] on success or a [Failure] on error.
  Future<Either<Failure, Task>> call({
    required TaskId taskId,
    required UserId userId,
    required FamilyId familyId,
    required String beforePhotoUrl,
  }) async {
    try {
      final task = await _taskRepository.getTask(familyId, taskId);
      if (task == null) {
        return Left(NotFoundFailure('Task not found'));
      }

      // Only from assigned. Starting an in-progress task again would overwrite
      // the before photo with a room that is already half-tidied; starting an
      // available one would skip claiming it.
      if (task.status != TaskStatus.assigned) {
        return Left(
          BusinessFailure('Only an assigned task can be started'),
        );
      }

      if (task.assignedToId != userId) {
        return Left(
          PermissionFailure('Only the assigned user can start this task'),
        );
      }

      await _taskRepository.startTask(familyId, taskId, beforePhotoUrl);

      final updatedTask = await _taskRepository.getTask(familyId, taskId);
      if (updatedTask == null) {
        return Left(ServerFailure('Failed to retrieve updated task'));
      }

      return Right(updatedTask);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to start task: $e'));
    }
  }
}
