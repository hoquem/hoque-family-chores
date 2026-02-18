import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/task_completion.dart';
import '../../domain/repositories/task_completion_repository.dart';
import '../../domain/value_objects/task_id.dart';
import '../../domain/value_objects/user_id.dart';

/// Mock implementation of TaskCompletionRepository for testing
class MockTaskCompletionRepository implements TaskCompletionRepository {
  final Map<String, TaskCompletion> _completions = {};
  int _idCounter = 0;

  @override
  Future<Either<Failure, String>> uploadPhoto({
    required File photo,
    required TaskId taskId,
    required UserId userId,
  }) async {
    // Simulate upload delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return mock URL
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return Right('mock://quest_photos/${taskId.value}/$timestamp.jpg');
  }

  @override
  Future<Either<Failure, TaskCompletion>> createCompletion({
    required TaskId taskId,
    required UserId userId,
    required String photoUrl,
    AiRating? aiRating,
  }) async {
    final id = 'completion_${_idCounter++}';
    final completion = TaskCompletion(
      id: id,
      taskId: taskId,
      userId: userId,
      timestamp: DateTime.now(),
      photoUrl: photoUrl,
      status: TaskCompletionStatus.pendingApproval,
      aiRating: aiRating,
    );

    _completions[id] = completion;
    return Right(completion);
  }

  @override
  Future<Either<Failure, TaskCompletion>> getCompletion(
      String completionId) async {
    final completion = _completions[completionId];
    if (completion == null) {
      return Left(NotFoundFailure('Completion not found'));
    }
    return Right(completion);
  }

  @override
  Future<Either<Failure, List<TaskCompletion>>> getTaskCompletions(
      TaskId taskId) async {
    final completions = _completions.values
        .where((c) => c.taskId == taskId)
        .toList();
    return Right(completions);
  }

  @override
  Future<Either<Failure, List<TaskCompletion>>> getPendingCompletions() async {
    final pending = _completions.values
        .where((c) => c.status == TaskCompletionStatus.pendingApproval)
        .toList();
    return Right(pending);
  }

  @override
  Future<Either<Failure, TaskCompletion>> updateWithApproval({
    required String completionId,
    required ParentApproval approval,
  }) async {
    final completion = _completions[completionId];
    if (completion == null) {
      return Left(NotFoundFailure('Completion not found'));
    }

    final updated = completion.copyWith(
      parentApproval: approval,
      status: approval.approved
          ? TaskCompletionStatus.approved
          : TaskCompletionStatus.rejected,
    );

    _completions[completionId] = updated;
    return Right(updated);
  }

  /// Clear all completions (for testing)
  void clear() {
    _completions.clear();
    _idCounter = 0;
  }
}
