import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/task.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/task_id.dart';
import '../../value_objects/user_id.dart';
import '../../value_objects/family_id.dart';

/// Use case for approving a completed task
class ApproveTaskUseCase {
  final TaskRepository _taskRepository;

  ApproveTaskUseCase(this._taskRepository);

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

      // You cannot judge your own chore.
      //
      // Anyone in the family may approve — a family is peers, not a hierarchy,
      // and a sibling signing off a sibling's work is the point. But the
      // approver must not be the person who did it: otherwise a child creates
      // "Tidy room, 100⭐", assigns it to themselves, taps Done, taps Approve,
      // and mints stars from nothing. Those stars buy real family time through
      // Rewards, so this is the rule holding the whole economy honest.
      //
      // This replaces a TODO that proposed a parent/guardian check. That was
      // both stricter than wanted and never implemented, so until now the only
      // thing stopping a self-approval was a hidden button — and the UI is not
      // a security boundary.
      if (task.assignedToId == approverId) {
        return Left(PermissionFailure(
          'You need someone else in the family to check this one off.',
        ));
      }

      // Approve and award atomically. The checks above give friendly errors
      // for the common cases; the repository transaction re-checks the status
      // as the authoritative guard and awards the stars in the same commit, so
      // an approval can never leave a child unpaid or pay them twice.
      await _taskRepository.approveTask(familyId, taskId);

      // The photos have now done their job: someone has looked at them and
      // judged. Keeping them past that point is pure storage cost, so
      // retention runs Start-to-Approve — hours — rather than forever.
      //
      // Deliberately after the approval and deliberately swallowed. Tapping
      // Approve is the core loop; a storage hiccup on kitchen wifi must not
      // break it, and the task IS approved by this point (the stars committed
      // inside the transaction above). The cost of a failure here is one
      // orphaned blob — a cost leak, not a correctness bug — much cheaper than
      // an approval that fails at the last step. This is the one place in this
      // flow where an error is tolerated, and it is tolerated on purpose.
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