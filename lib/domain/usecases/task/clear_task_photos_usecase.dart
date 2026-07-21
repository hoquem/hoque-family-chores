import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/task_id.dart';
import '../../value_objects/family_id.dart';

/// Use case for removing a task's before/after photos.
///
/// Deletes the stored image blobs and clears the task's photo URLs, so the
/// photos are gone immediately (rather than only expiring under the 90-day
/// storage lifecycle rule). The task itself is untouched and keeps working.
class ClearTaskPhotosUseCase {
  final TaskRepository _taskRepository;

  ClearTaskPhotosUseCase(this._taskRepository);

  /// Removes the photos for [taskId] in [familyId].
  ///
  /// :returns: ``Unit`` on success or ``Failure`` on error.
  Future<Either<Failure, Unit>> call({
    required TaskId taskId,
    required FamilyId familyId,
  }) async {
    try {
      if (taskId.value.trim().isEmpty) {
        return Left(ValidationFailure('Task ID cannot be empty'));
      }
      await _taskRepository.clearPhotos(familyId, taskId);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to delete task photos: $e'));
    }
  }
}
