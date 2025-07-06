import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/task_id.dart';

/// Use case for deleting tasks
class DeleteTaskUseCase {
  final TaskRepository _taskRepository;

  DeleteTaskUseCase(this._taskRepository);

  /// Deletes a task by ID
  /// 
  /// [taskId] - ID of the task to delete
  /// 
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required TaskId taskId,
  }) async {
    try {
      // Validate task ID
      if (taskId.value.trim().isEmpty) {
        return Left(ValidationFailure('Task ID cannot be empty'));
      }

      // Delete the task
      await _taskRepository.deleteTask(taskId);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to delete task: $e'));
    }
  }
} 