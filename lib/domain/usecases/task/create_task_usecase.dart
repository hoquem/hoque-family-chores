import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/task.dart';
import '../../repositories/task_repository.dart';
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
  }) async {
    try {
      // Validate input parameters
      final validationResult = _validateTaskInput(
        title: title,
        description: description,
        points: points,
        dueDate: dueDate,
        tags: tags,
      );

      if (validationResult.isLeft()) {
        return Left(validationResult.fold((failure) => failure, (_) => throw Exception('Unexpected')));
      }

      // Create task entity
      final task = Task(
        id: TaskId(''), // Will be set by repository
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

  /// Validates task input parameters
  Either<Failure, void> _validateTaskInput({
    required String title,
    String? description,
    required int points,
    required DateTime dueDate,
    required List<String> tags,
  }) {
    // Validate title
    if (title.trim().isEmpty) {
      return Left(ValidationFailure('Task title cannot be empty'));
    }
    if (title.trim().length > 100) {
      return Left(ValidationFailure('Task title cannot exceed 100 characters'));
    }

    // Validate description
    if (description != null && description.trim().length > 500) {
      return Left(ValidationFailure('Task description cannot exceed 500 characters'));
    }

    // Validate points
    if (points < 1 || points > 1000) {
      return Left(ValidationFailure('Task points must be between 1 and 1000'));
    }

    // Validate due date
    if (dueDate.isBefore(DateTime.now())) {
      return Left(ValidationFailure('Due date cannot be in the past'));
    }

    // Validate tags
    if (tags.length > 10) {
      return Left(ValidationFailure('Cannot have more than 10 tags'));
    }
    for (final tag in tags) {
      if (tag.trim().isEmpty) {
        return Left(ValidationFailure('Tag cannot be empty'));
      }
      if (tag.trim().length > 20) {
        return Left(ValidationFailure('Tag cannot exceed 20 characters'));
      }
    }

    return const Right(null);
  }
} 