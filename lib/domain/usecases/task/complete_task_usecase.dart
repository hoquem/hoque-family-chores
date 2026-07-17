import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/task.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/task_id.dart';
import '../../value_objects/user_id.dart';
import '../../value_objects/family_id.dart';

/// Use case for completing a task
class CompleteTaskUseCase {
  final TaskRepository _taskRepository;

  CompleteTaskUseCase(this._taskRepository);

  /// Completes a task and submits it for approval
  /// 
  /// [taskId] - ID of the task to complete
  /// [userId] - ID of the user completing the task
  /// [familyId] - ID of the family the task belongs to
  /// 
  /// Returns [Task] on success or [Failure] on error
  Future<Either<Failure, Task>> call({
    required TaskId taskId,
    required UserId userId,
    required FamilyId familyId,
  }) async {
    try {
      // Get the task to validate it can be completed
      final task = await _taskRepository.getTask(familyId, taskId);
      if (task == null) {
        return Left(NotFoundFailure('Task not found'));
      }

      // Which statuses may be completed from depends on whether the task
      // demands photo proof.
      //
      // A photo-proof task must pass through `inProgress`, because that is
      // where the before photo is captured — the before only exists before the
      // work starts. Allowing `assigned` would let a caller complete a task
      // that was never started and therefore has no before photo, which is the
      // whole feature bypassed. The Start button already enforces this in the
      // UI; it is enforced again here because the UI is not a security
      // boundary.
      //
      // `needsRevision` stays open to both: rework replaces the after photo
      // while the before persists (the room was only messy once), so demanding
      // a re-Start would ask a child to photograph a mess that is long gone.
      final completableFrom = task.requiresPhotoProof
          ? const {TaskStatus.inProgress, TaskStatus.needsRevision}
          : const {TaskStatus.assigned, TaskStatus.needsRevision};

      if (!completableFrom.contains(task.status)) {
        return Left(BusinessFailure(
          task.requiresPhotoProof
              ? 'This task needs a photo. Tap Start to take the "before" shot '
                  'before finishing it.'
              : 'Task must be assigned before it can be completed',
        ));
      }

      if (task.assignedToId != userId) {
        return Left(PermissionFailure('Only the assigned user can complete this task'));
      }

      // Complete the task (this changes status to pendingApproval)
      await _taskRepository.completeTask(familyId, taskId);
      
      // Return the updated task
      final updatedTask = await _taskRepository.getTask(familyId, taskId);
      if (updatedTask == null) {
        return Left(ServerFailure('Failed to retrieve updated task'));
      }

      return Right(updatedTask);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to complete task: $e'));
    }
  }
} 