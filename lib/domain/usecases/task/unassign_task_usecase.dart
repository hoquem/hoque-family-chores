import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/task_id.dart';

/// Use case for unassigning tasks
class UnassignTaskUseCase {
  final TaskRepository _taskRepository;

  UnassignTaskUseCase(this._taskRepository);

  /// Unassigns a task (removes assignment)
  /// 
  /// [taskId] - ID of the task to unassign
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

      // Unassign the task
      await _taskRepository.unassignTask(taskId);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to unassign task: $e'));
    }
  }
} 