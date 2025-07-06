import 'dart:async';
import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/task.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/user_id.dart';

/// Use case for streaming tasks by assignee
class StreamTasksByAssigneeUseCase {
  final TaskRepository _taskRepository;

  StreamTasksByAssigneeUseCase(this._taskRepository);

  /// Streams tasks assigned to a specific user in a family
  /// 
  /// [familyId] - ID of the family
  /// [assigneeId] - ID of the user to get tasks for
  /// 
  /// Returns [Stream<List<Task>>] on success or [Failure] on error
  Stream<Either<Failure, List<Task>>> call({
    required FamilyId familyId,
    required UserId assigneeId,
  }) {
    try {
      // Validate family ID
      if (familyId.value.trim().isEmpty) {
        return Stream.value(Left(ValidationFailure('Family ID cannot be empty')));
      }

      // Validate assignee ID
      if (assigneeId.value.trim().isEmpty) {
        return Stream.value(Left(ValidationFailure('Assignee ID cannot be empty')));
      }

      // Stream the tasks by assignee
      return _taskRepository.streamTasksByAssignee(familyId, assigneeId).map(
        (tasks) => Right<Failure, List<Task>>(tasks),
      ).handleError(
        (error) {
          if (error is DataException) {
            return Left<Failure, List<Task>>(ServerFailure(error.message, code: error.code));
          }
          return Left<Failure, List<Task>>(ServerFailure('Failed to stream tasks by assignee: $error'));
        },
      );
    } catch (e) {
      return Stream.value(Left(ServerFailure('Failed to stream tasks by assignee: $e')));
    }
  }
} 