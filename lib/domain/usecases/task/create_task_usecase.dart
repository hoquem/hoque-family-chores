import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/task.dart';
import '../../repositories/task_repository.dart';
import '../../services/task_validation.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/user_id.dart';
import '../../value_objects/task_id.dart';
import '../../value_objects/points.dart';

/// Use case for creating a new task
class CreateTaskUseCase {
  final TaskRepository _taskRepository;

  CreateTaskUseCase(this._taskRepository);

  /// Creates a new task with business logic validation
  /// 
  /// [title] - Task title (required, 1-100 characters)
  /// [description] - Task description (optional, max 500 characters)
  /// [points] - Points for completing the task (1-1000)
  /// [difficulty] - Task difficulty level
  /// [dueDate] - When the task should be completed
  /// [familyId] - ID of the family this task belongs to
  /// [createdById] - ID of the user creating the task
  /// [assignedToId] - ID of the user assigned to the task (optional)
  /// [tags] - List of tags for categorization
  /// [requiresPhotoProof] - Whether the child must attach before/after photos
  ///   (defaults to false, so existing callers are unaffected)
  ///
  /// Returns [Task] on success or [Failure] on error
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
  }) async {
    try {
      // Validate input parameters
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

      // Create task entity
      final task = Task(
        id: TaskId('new'), // Placeholder — replaced by repository
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
      );

      // Save task to repository
      final createdTask = await _taskRepository.createTask(task);
      return Right(createdTask);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to create task: $e'));
    }
  }
} 