import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/task.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/task_id.dart';
import '../../value_objects/user_id.dart';
import '../../value_objects/family_id.dart';

/// Use case for claiming an available task
class ClaimTaskUseCase {
  final TaskRepository _taskRepository;

  ClaimTaskUseCase(this._taskRepository);

  /// Claims an available task for a user
  /// 
  /// [taskId] - ID of the task to claim
  /// [userId] - ID of the user claiming the task
  /// [familyId] - ID of the family the task belongs to
  /// 
  /// Returns [Task] on success or [Failure] on error
  Future<Either<Failure, Task>> call({
    required TaskId taskId,
    required UserId userId,
    required FamilyId familyId,
  }) async {
    try {
      // Get the task to validate it can be claimed
      final task = await _taskRepository.getTask(familyId, taskId);
      if (task == null) {
        return Left(NotFoundFailure('Task not found'));
      }

      // Validate task can be claimed
      if (task.status != TaskStatus.available) {
        return Left(BusinessFailure('Task is not available for claiming'));
      }

      // Claim the task
      await _taskRepository.claimTask(taskId, userId);
      
      // Return the updated task
      final updatedTask = await _taskRepository.getTask(familyId, taskId);
      if (updatedTask == null) {
        return Left(ServerFailure('Failed to retrieve updated task'));
      }

      return Right(updatedTask);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to claim task: $e'));
    }
  }
} 