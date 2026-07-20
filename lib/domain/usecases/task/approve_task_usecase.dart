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
      // Get the task — only to decide what happens to its photos below. All the
      // approval rules (status is pendingApproval, there is an assignee, and the
      // approver is allowed) now live in the Cloud Function: a non-parent cannot
      // approve their own work, but a parent/guardian may (the edit-screen
      // override). The Function is the authoritative guard and awards the stars.
      final task = await _taskRepository.getTask(familyId, taskId);

      // Approve and award (server-side, atomic). The repository call reaches the
      // Cloud Function, which re-reads the status inside its transaction so an
      // approval can never leave a child unpaid or pay them twice.
      await _taskRepository.approveTask(familyId, taskId);

      // The after-photo has done its job as proof; now it earns a second life
      // as the family's Home-screen background — the room they just cleaned.
      // Promoting it keeps that one file and retires the previous background
      // plus this task's before-photo. A chore with no after-photo just clears,
      // as before.
      //
      // Deliberately after the approval and deliberately swallowed. Tapping
      // Approve is the core loop; a storage hiccup on kitchen wifi must not
      // break it, and the task IS approved by this point (the stars committed
      // inside the transaction above). The cost of a failure here is a leaked
      // blob — a cost leak, not a correctness bug — much cheaper than an
      // approval that fails at the last step. This is the one place in this flow
      // where an error is tolerated, and it is tolerated on purpose.
      try {
        if (task?.photoUrl != null) {
          await _taskRepository.promoteAfterPhotoToBackground(familyId, taskId);
        } else {
          await _taskRepository.clearPhotos(familyId, taskId);
        }
      } catch (_) {
        // Intentionally ignored — see above.
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