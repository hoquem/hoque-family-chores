import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/task.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/user_id.dart';

/// Use case for getting tasks with various filters
class GetTasksUseCase {
  final TaskRepository _taskRepository;

  GetTasksUseCase(this._taskRepository);

  /// Gets tasks for a family with optional filtering
  /// 
  /// [familyId] - ID of the family to get tasks for
  /// [status] - Optional status filter
  /// [assigneeId] - Optional assignee filter
  /// [createdById] - Optional creator filter
  /// 
  /// Returns [List<Task>] on success or [Failure] on error
  Future<Either<Failure, List<Task>>> call({
    required FamilyId familyId,
    TaskStatus? status,
    UserId? assigneeId,
    UserId? createdById,
  }) async {
    try {
      // Get all tasks for the family
      final allTasks = await _taskRepository.getTasksForFamily(familyId);
      
      // Apply filters
      var filteredTasks = allTasks;

      if (status != null) {
        filteredTasks = filteredTasks.where((task) => task.status == status).toList();
      }

      if (assigneeId != null) {
        filteredTasks = filteredTasks.where((task) => task.assignedToId == assigneeId).toList();
      }

      if (createdById != null) {
        filteredTasks = filteredTasks.where((task) => task.createdById == createdById).toList();
      }

      return Right(filteredTasks);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to get tasks: $e'));
    }
  }

  /// Gets tasks for a specific user
  /// 
  /// [userId] - ID of the user to get tasks for
  /// 
  /// Returns [List<Task>] on success or [Failure] on error
  Future<Either<Failure, List<Task>>> getTasksForUser({
    required UserId userId,
  }) async {
    try {
      final tasks = await _taskRepository.getTasksForUser(userId);
      return Right(tasks);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to get tasks for user: $e'));
    }
  }

  /// Gets available tasks for a family
  /// 
  /// [familyId] - ID of the family to get available tasks for
  /// 
  /// Returns [List<Task>] on success or [Failure] on error
  Future<Either<Failure, List<Task>>> getAvailableTasks({
    required FamilyId familyId,
  }) async {
    try {
      final allTasks = await _taskRepository.getTasksForFamily(familyId);
      final availableTasks = allTasks.where((task) => task.status == TaskStatus.available).toList();
      return Right(availableTasks);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to get available tasks: $e'));
    }
  }
} 