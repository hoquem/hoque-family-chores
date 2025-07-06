import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/task.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/task_id.dart';

/// Use case for updating existing tasks
class UpdateTaskUseCase {
  final TaskRepository _taskRepository;

  UpdateTaskUseCase(this._taskRepository);

  /// Updates an existing task
  /// 
  /// [task] - The task to update with new values
  /// 
  /// Returns [Task] on success or [Failure] on error
  Future<Either<Failure, Task>> call({
    required Task task,
  }) async {
    try {
      // Validate task ID
      if (task.id == null) {
        return Left(ValidationFailure('Task ID is required for update'));
      }

      // Validate task data
      if (task.title.trim().isEmpty) {
        return Left(ValidationFailure('Task title cannot be empty'));
      }

      if (task.description.trim().isEmpty) {
        return Left(ValidationFailure('Task description cannot be empty'));
      }

      if (task.points.value <= 0) {
        return Left(ValidationFailure('Task points must be greater than 0'));
      }

      // Update the task
      await _taskRepository.updateTask(task);
      
      // Get the updated task to return
      final updatedTask = await _taskRepository.getTask(task.familyId, task.id!);
      if (updatedTask == null) {
        return Left(NotFoundFailure('Updated task not found'));
      }
      
      return Right(updatedTask);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to update task: $e'));
    }
  }
} 