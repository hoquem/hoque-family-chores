import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/task_completion.dart';
import '../value_objects/task_id.dart';
import '../value_objects/user_id.dart';

/// Repository interface for task completions
abstract class TaskCompletionRepository {
  /// Upload photo proof to storage
  Future<Either<Failure, String>> uploadPhoto({
    required File photo,
    required TaskId taskId,
    required UserId userId,
  });

  /// Create task completion record
  Future<Either<Failure, TaskCompletion>> createCompletion({
    required TaskId taskId,
    required UserId userId,
    required String photoUrl,
    AiRating? aiRating,
  });

  /// Get task completion by ID
  Future<Either<Failure, TaskCompletion>> getCompletion(String completionId);

  /// Get task completions for a task
  Future<Either<Failure, List<TaskCompletion>>> getTaskCompletions(
      TaskId taskId);

  /// Get pending completions for approval
  Future<Either<Failure, List<TaskCompletion>>> getPendingCompletions();

  /// Update completion with parent approval
  Future<Either<Failure, TaskCompletion>> updateWithApproval({
    required String completionId,
    required ParentApproval approval,
  });
}
