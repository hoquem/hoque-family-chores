import 'dart:async';
import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/task.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/family_id.dart';

/// Use case for streaming task updates
class StreamTasksUseCase {
  final TaskRepository _taskRepository;

  StreamTasksUseCase(this._taskRepository);

  /// Streams all tasks for a family
  /// 
  /// [familyId] - ID of the family to stream tasks for
  /// 
  /// Returns [Stream<List<Task>>] on success or [Failure] on error
  Stream<Either<Failure, List<Task>>> call({
    required FamilyId familyId,
  }) {
    try {
      // Validate family ID
      if (familyId.value.trim().isEmpty) {
        return Stream.value(Left(ValidationFailure('Family ID cannot be empty')));
      }

      // Stream the tasks
      return _taskRepository.streamTasks(familyId).map(
        (tasks) => Right<Failure, List<Task>>(tasks),
      ).handleError(
        (error) {
          if (error is DataException) {
            return Left<Failure, List<Task>>(ServerFailure(error.message, code: error.code));
          }
          return Left<Failure, List<Task>>(ServerFailure('Failed to stream tasks: $error'));
        },
      );
    } catch (e) {
      return Stream.value(Left(ServerFailure('Failed to stream tasks: $e')));
    }
  }
} 