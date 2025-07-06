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

      // TODO: Validate that approverId is a parent/guardian
      // This would require access to user repository to check role

      // Approve the task
      await _taskRepository.approveTask(taskId);
      
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