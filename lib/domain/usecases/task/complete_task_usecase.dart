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

      // Validate task can be completed
      if (task.status != TaskStatus.assigned) {
        return Left(BusinessFailure('Task must be assigned before it can be completed'));
      }

      if (task.assignedToId != userId) {
        return Left(PermissionFailure('Only the assigned user can complete this task'));
      }

      // Complete the task (this changes status to pendingApproval)
      await _taskRepository.completeTask(taskId);
      
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