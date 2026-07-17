import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/task.dart';
import '../../repositories/task_repository.dart';
import '../../repositories/user_repository.dart';
import '../../value_objects/task_id.dart';
import '../../value_objects/user_id.dart';
import '../../value_objects/family_id.dart';

/// Use case for approving a completed task
class ApproveTaskUseCase {
  final TaskRepository _taskRepository;
  final UserRepository _userRepository;

  ApproveTaskUseCase(this._taskRepository, this._userRepository);

  /// Approves a completed task and awards points
  /// 
  /// [taskId] - ID of the task to approve
  /// [approverId] - ID of the user approving the task (must be parent/guardian)
  /// [familyId] - ID of the family the task belongs to
  /// 
  /// Returns [Task] on success or [Failure] on error
  Future<Either<Failure, Task>> call({
    required TaskId taskId,
    required UserId approverId,
    required FamilyId familyId,
  }) async {
    try {
      // Get the task to validate it can be approved
      final task = await _taskRepository.getTask(familyId, taskId);
      if (task == null) {
        return Left(NotFoundFailure('Task not found'));
      }

      // Validate task can be approved
      if (task.status != TaskStatus.pendingApproval) {
        return Left(BusinessFailure('Task must be pending approval'));
      }

      // Validate that task has an assignee to award stars to
      if (task.assignedToId == null) {
        return Left(BusinessFailure('Task has no assignee'));
      }

      // TODO: Validate that approverId is a parent/guardian
      // This would require checking user role in UserRepository

      // Approve the task first: once the status leaves pendingApproval a
      // retried approval fails validation, so points can't be awarded twice.
      await _taskRepository.approveTask(familyId, taskId);

      // Award stars to the user who completed the task
      await _userRepository.addPoints(task.assignedToId!, task.points);

      // The photos have now done their job: a parent has looked at them and
      // judged. Keeping them past that point is pure storage cost, so
      // retention runs Start-to-Approve — hours — rather than forever.
      //
      // Deliberately after the approval and deliberately swallowed. A parent
      // tapping Approve is the core loop; a storage hiccup on kitchen wifi
      // must not break it, and the task IS approved by this point. The cost of
      // a failure here is one orphaned blob, which is a cost leak rather than
      // a correctness bug — much cheaper than an approval that fails at the
      // last step. This is the one place in this flow where an error is
      // tolerated, and it is tolerated on purpose.
      try {
        await _taskRepository.clearPhotos(familyId, taskId);
      } catch (_) {
        // Intentionally ignored — see above. The blob outlives the task.
      }
      
      // TODO: Update user streak (requires additional repository method)
      // TODO: Send push notification to child (requires NotificationRepository)
      
      // Return the updated task
      final updatedTask = await _taskRepository.getTask(familyId, taskId);
      if (updatedTask == null) {
        return Left(ServerFailure('Failed to retrieve updated task'));
      }

      return Right(updatedTask);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to approve task: $e'));
    }
  }
} 