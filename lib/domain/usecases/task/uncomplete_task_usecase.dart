import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/task_id.dart';
import '../../value_objects/family_id.dart';

/// Use case for marking tasks as incomplete
class UncompleteTaskUseCase {
  final TaskRepository _taskRepository;

  UncompleteTaskUseCase(this._taskRepository);

  /// Marks a task as incomplete
  /// 
  /// [taskId] - ID of the task to mark as incomplete
  /// [familyId] - ID of the family the task belongs to
  ///
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required TaskId taskId,
    required FamilyId familyId,
  }) async {
    try {
      // Validate task ID
      if (taskId.value.trim().isEmpty) {
        return Left(ValidationFailure('Task ID cannot be empty'));
      }

      // Mark the task as incomplete
      await _taskRepository.uncompleteTask(familyId, taskId);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to mark task as incomplete: $e'));
    }
  }
} 