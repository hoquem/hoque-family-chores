import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../entities/recurring_rule.dart';
import '../../entities/task.dart';
import '../../repositories/task_repository.dart';
import '../../services/task_validation.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/points.dart';
import '../../value_objects/task_id.dart';
import '../../value_objects/user_id.dart';

/// Creates the first occurrence of a recurring chore together with its rule.
/// Shares the exact validation rules of [CreateTaskUseCase] so the engine
/// never sees a garbage template.
class CreateRecurringChoreUseCase {
  final TaskRepository _taskRepository;

  CreateRecurringChoreUseCase(this._taskRepository);

  Future<Either<Failure, Task>> call({
    required String title,
    String? description,
    required int points,
    required TaskDifficulty difficulty,
    required DateTime dueDate,
    required FamilyId familyId,
    required UserId createdById,
    UserId? assignedToId,
    List<String> tags = const [],
    bool requiresPhotoProof = false,
    required String rrule,
  }) async {
    final validationFailure = validateTaskInput(
      title: title,
      description: description,
      points: points,
      dueDate: dueDate,
      tags: tags,
    );
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    final firstTask = Task(
      id: TaskId('new'), // placeholder — repository assigns the real id
      title: title.trim(),
      description: description?.trim() ?? '',
      status: assignedToId != null ? TaskStatus.assigned : TaskStatus.available,
      difficulty: difficulty,
      dueDate: dueDate,
      assignedToId: assignedToId,
      createdById: createdById,
      createdAt: DateTime.now(),
      completedAt: null,
      points: Points(points),
      tags: tags,
      recurringPattern: null,
      lastCompletedAt: null,
      familyId: familyId,
      requiresPhotoProof: requiresPhotoProof,
      ruleId: null,
    );

    final rule = RecurringRule(
      id: 'new', // placeholder — repository assigns the real id
      familyId: familyId,
      rrule: rrule,
      title: title.trim(),
      description: description?.trim() ?? '',
      difficulty: difficulty,
      points: Points(points),
      tags: tags,
      requiresPhotoProof: requiresPhotoProof,
      assignedToId: assignedToId,
      createdBy: createdById,
      nextDueAt: dueDate,
      lastTaskId: null,
    );

    try {
      final created = await _taskRepository.createRecurringChore(
        firstTask: firstTask,
        rule: rule,
      );
      return Right(created);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to create recurring chore: $e'));
    }
  }
}
