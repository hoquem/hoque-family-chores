import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/task_id.dart';

/// Use case for rejecting completed tasks
class RejectTaskUseCase {
  final TaskRepository _taskRepository;

  RejectTaskUseCase(this._taskRepository);

  /// Rejects a completed task
  /// 
  /// [taskId] - ID of the task to reject
  /// [comments] - Optional comments explaining the rejection
  /// 
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required TaskId taskId,
    String? comments,
  }) async {
    try {
      // Validate task ID
      if (taskId.value.trim().isEmpty) {
        return Left(ValidationFailure('Task ID cannot be empty'));
      }

      // Reject the task
      await _taskRepository.rejectTask(taskId, comments: comments);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to reject task: $e'));
    }
  }
} 