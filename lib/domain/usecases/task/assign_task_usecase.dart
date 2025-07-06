import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/task_id.dart';
import '../../value_objects/user_id.dart';

/// Use case for assigning tasks to users
class AssignTaskUseCase {
  final TaskRepository _taskRepository;

  AssignTaskUseCase(this._taskRepository);

  /// Assigns a task to a user
  /// 
  /// [taskId] - ID of the task to assign
  /// [userId] - ID of the user to assign the task to
  /// 
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required TaskId taskId,
    required UserId userId,
  }) async {
    try {
      // Validate task ID
      if (taskId.value.trim().isEmpty) {
        return Left(ValidationFailure('Task ID cannot be empty'));
      }

      // Validate user ID
      if (userId.value.trim().isEmpty) {
        return Left(ValidationFailure('User ID cannot be empty'));
      }

      // Assign the task
      await _taskRepository.assignTask(taskId, userId);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to assign task: $e'));
    }
  }
} 