import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/task_id.dart';
import '../../value_objects/family_id.dart';

/// Use case for restoring soft-deleted tasks
class RestoreTaskUseCase {
  final TaskRepository _taskRepository;

  RestoreTaskUseCase(this._taskRepository);

  /// Restores a soft-deleted task by ID
  /// 
  /// [taskId] - ID of the task to restore
  /// [familyId] - ID of the family the task belongs to
  ///
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required TaskId taskId,
    required FamilyId familyId,
  }) async {
    try {
      if (taskId.value.trim().isEmpty) {
        return Left(ValidationFailure('Task ID cannot be empty'));
      }

      await _taskRepository.restoreTask(familyId, taskId);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to restore task: $e'));
    }
  }
}
