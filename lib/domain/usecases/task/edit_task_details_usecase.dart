import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/task.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/task_id.dart';
import '../../value_objects/points.dart';

/// Use case for editing a task's user-editable detail fields.
///
/// Uses optimistic concurrency: [baseVersion] is the version the editor loaded.
/// A [ConflictException] (someone else edited first) maps to [ConflictFailure];
/// a [NotFoundException] (task deleted meanwhile) maps to [NotFoundFailure].
class EditTaskDetailsUseCase {
  final TaskRepository _taskRepository;

  EditTaskDetailsUseCase(this._taskRepository);

  /// Points awarded per difficulty — kept in sync with task creation.
  static int pointsFor(TaskDifficulty difficulty) => switch (difficulty) {
        TaskDifficulty.easy => 10,
        TaskDifficulty.medium => 25,
        TaskDifficulty.hard => 50,
        TaskDifficulty.challenging => 100,
      };

  Future<Either<Failure, Unit>> call({
    required FamilyId familyId,
    required TaskId taskId,
    required int baseVersion,
    required String title,
    required String description,
    required TaskDifficulty difficulty,
    required DateTime dueDate,
    required bool requiresPhotoProof,
  }) async {
    if (title.trim().isEmpty) {
      return Left(ValidationFailure('Task title cannot be empty'));
    }
    if (title.trim().length > 100) {
      return Left(ValidationFailure('Task title cannot exceed 100 characters'));
    }
    if (description.trim().length > 500) {
      return Left(
          ValidationFailure('Task description cannot exceed 500 characters'));
    }

    try {
      await _taskRepository.editTaskDetails(
        familyId: familyId,
        taskId: taskId,
        baseVersion: baseVersion,
        title: title.trim(),
        description: description.trim(),
        difficulty: difficulty,
        points: Points(pointsFor(difficulty)),
        dueDate: dueDate,
        requiresPhotoProof: requiresPhotoProof,
      );
      return const Right(unit);
    } on ConflictException catch (e) {
      return Left(ConflictFailure(e.message, code: e.code));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message, code: e.code));
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to edit task: $e'));
    }
  }
}
