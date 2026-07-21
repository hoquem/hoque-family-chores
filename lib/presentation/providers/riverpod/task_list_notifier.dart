import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'task_list_notifier.g.dart';

/// Result of an optimistic-concurrency task edit.
enum TaskEditOutcome { success, conflict, deleted, failure }

/// Manages the list of tasks for a family with real-time updates.
/// 
/// This notifier streams tasks from the repository providing automatic
/// updates when tasks change in the database.
/// 
/// Example:
/// ```dart
/// final tasksAsync = ref.watch(taskListStreamProvider(familyId));
/// ```
@riverpod
Stream<List<Task>> taskListStream(Ref ref, FamilyId familyId) {
  final logger = AppLogger();
  logger.d('TaskListStream: Streaming tasks for family $familyId');
  
  final repository = ref.watch(taskRepositoryProvider);
  return repository.streamTasks(familyId);
}

/// Legacy notifier - kept for backward compatibility with use case methods.
/// Use taskListStreamProvider for real-time updates instead.
@riverpod
class TaskListNotifier extends _$TaskListNotifier {
  final _logger = AppLogger();

  @override
  Future<List<Task>> build(FamilyId familyId) async {
    _logger.d('TaskListNotifier: Building for family $familyId');
    
    try {
      final getTasksUseCase = ref.watch(getTasksUseCaseProvider);
      final result = await getTasksUseCase.call(familyId: familyId);
      
      return result.fold(
        (failure) => throw Exception(failure.message),
        (tasks) {
          _logger.d('TaskListNotifier: Loaded ${tasks.length} tasks');
          return tasks;
        },
      );
    } catch (e) {
      _logger.e('TaskListNotifier: Error loading tasks', error: e);
      throw Exception('Failed to load tasks: $e');
    }
  }

  /// Creates a new task.
  Future<void> createTask(Task task) async {
    _logger.d('TaskListNotifier: Creating task ${task.id}');
    
    try {
      final createTaskUseCase = ref.read(createTaskUseCaseProvider);
      final result = await createTaskUseCase.call(
        title: task.title,
        description: task.description,
        difficulty: task.difficulty,
        dueDate: task.dueDate,
        points: task.points.value,
        tags: task.tags,
        familyId: task.familyId,
        createdById: task.createdById ?? UserId(''),
      );
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('TaskListNotifier: Task created successfully');
          ref.read(analyticsProvider).log(
                AnalyticsEventName.taskCreated,
                userId: task.createdById?.value ?? '',
                familyId: task.familyId.value,
                params: {'points': task.points.value},
              );
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('TaskListNotifier: Error creating task', error: e);
      throw Exception('Failed to create task: $e');
    }
  }


  /// Deletes a task.
  Future<void> deleteTask(String taskId) async {
    _logger.d('TaskListNotifier: Deleting task $taskId');

    try {
      final deleteTaskUseCase = ref.read(deleteTaskUseCaseProvider);
      final result = await deleteTaskUseCase.call(
        taskId: TaskId(taskId),
        familyId: familyId,
      );

      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('TaskListNotifier: Task deleted successfully');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('TaskListNotifier: Error deleting task', error: e);
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Removes a task's before/after photos (blobs + URLs); the task stays.
  Future<void> clearPhotos(String taskId) async {
    _logger.d('TaskListNotifier: Clearing photos for task $taskId');
    try {
      final result = await ref.read(clearTaskPhotosUseCaseProvider).call(
            taskId: TaskId(taskId),
            familyId: familyId,
          );
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('TaskListNotifier: Task photos cleared');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('TaskListNotifier: Error clearing task photos', error: e);
      throw Exception('Failed to clear task photos: $e');
    }
  }

  /// Edits a task's detail fields with optimistic concurrency. Returns a
  /// [TaskEditOutcome] so the UI can tell a version conflict or a deleted task
  /// apart from a generic failure.
  Future<TaskEditOutcome> editTaskDetails({
    required String taskId,
    required int baseVersion,
    required String title,
    required String description,
    required TaskDifficulty difficulty,
    required DateTime dueDate,
    required bool requiresPhotoProof,
  }) async {
    final useCase = ref.read(editTaskDetailsUseCaseProvider);
    final result = await useCase.call(
      familyId: familyId,
      taskId: TaskId(taskId),
      baseVersion: baseVersion,
      title: title,
      description: description,
      difficulty: difficulty,
      dueDate: dueDate,
      requiresPhotoProof: requiresPhotoProof,
    );
    return result.fold(
      (failure) {
        _logger.w('TaskListNotifier: edit failed: ${failure.message}');
        if (failure is ConflictFailure) return TaskEditOutcome.conflict;
        if (failure is NotFoundFailure) return TaskEditOutcome.deleted;
        return TaskEditOutcome.failure;
      },
      (_) {
        _logger.d('TaskListNotifier: task edited successfully');
        ref.invalidateSelf();
        return TaskEditOutcome.success;
      },
    );
  }

  /// Claims a task for the current user.
  Future<void> claimTask(String taskId, UserId userId, FamilyId familyId) async {
    _logger.d('TaskListNotifier: Claiming task $taskId for user $userId');
    
    try {
      final claimTaskUseCase = ref.read(claimTaskUseCaseProvider);
      final result = await claimTaskUseCase.call(
        taskId: TaskId(taskId), 
        userId: userId,
        familyId: familyId,
      );
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('TaskListNotifier: Task claimed successfully');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('TaskListNotifier: Error claiming task', error: e);
      throw Exception('Failed to claim task: $e');
    }
  }

  /// Completes a task.
  Future<void> completeTask(String taskId, UserId userId, FamilyId familyId) async {
    _logger.d('TaskListNotifier: Completing task $taskId');
    
    try {
      final completeTaskUseCase = ref.read(completeTaskUseCaseProvider);
      final result = await completeTaskUseCase.call(
        taskId: TaskId(taskId),
        userId: userId,
        familyId: familyId,
      );
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('TaskListNotifier: Task completed successfully');
          ref.read(analyticsProvider).log(
                AnalyticsEventName.taskCompleted,
                userId: userId.value,
                familyId: familyId.value,
              );
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('TaskListNotifier: Error completing task', error: e);
      throw Exception('Failed to complete task: $e');
    }
  }

  /// Approves a task.
  Future<void> approveTask(String taskId, UserId approverId, FamilyId familyId) async {
    _logger.d('TaskListNotifier: Approving task $taskId');
    
    try {
      final approveTaskUseCase = ref.read(approveTaskUseCaseProvider);
      final result = await approveTaskUseCase.call(
        taskId: TaskId(taskId),
        approverId: approverId,
        familyId: familyId,
      );
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('TaskListNotifier: Task approved successfully');
          ref.read(analyticsProvider).log(
                AnalyticsEventName.taskApproved,
                userId: approverId.value,
                familyId: familyId.value,
              );
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('TaskListNotifier: Error approving task', error: e);
      throw Exception('Failed to approve task: $e');
    }
  }

  /// Assigns a task to a user.
  Future<void> assignTask(String taskId, UserId userId) async {
    _logger.d('TaskListNotifier: Assigning task $taskId to user $userId');
    
    try {
      final assignTaskUseCase = ref.read(assignTaskUseCaseProvider);
      final result = await assignTaskUseCase.call(
        taskId: TaskId(taskId),
        userId: userId,
        familyId: familyId,
      );
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('TaskListNotifier: Task assigned successfully');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('TaskListNotifier: Error assigning task', error: e);
      throw Exception('Failed to assign task: $e');
    }
  }

  /// Unassigns a task.
  Future<void> unassignTask(String taskId) async {
    _logger.d('TaskListNotifier: Unassigning task $taskId');
    
    try {
      final unassignTaskUseCase = ref.read(unassignTaskUseCaseProvider);
      final result = await unassignTaskUseCase.call(
        taskId: TaskId(taskId),
        familyId: familyId,
      );
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('TaskListNotifier: Task unassigned successfully');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('TaskListNotifier: Error unassigning task', error: e);
      throw Exception('Failed to unassign task: $e');
    }
  }

  /// Uncompletes a task.
  Future<void> uncompleteTask(String taskId) async {
    _logger.d('TaskListNotifier: Uncompleting task $taskId');
    
    try {
      final uncompleteTaskUseCase = ref.read(uncompleteTaskUseCaseProvider);
      final result = await uncompleteTaskUseCase.call(
        taskId: TaskId(taskId),
        familyId: familyId,
      );
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('TaskListNotifier: Task uncompleted successfully');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('TaskListNotifier: Error uncompleting task', error: e);
      throw Exception('Failed to uncomplete task: $e');
    }
  }

  /// Rejects a task.
  Future<void> rejectTask(String taskId) async {
    _logger.d('TaskListNotifier: Rejecting task $taskId');
    
    try {
      final rejectTaskUseCase = ref.read(rejectTaskUseCaseProvider);
      final result = await rejectTaskUseCase.call(
        taskId: TaskId(taskId),
        familyId: familyId,
      );
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('TaskListNotifier: Task rejected successfully');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('TaskListNotifier: Error rejecting task', error: e);
      throw Exception('Failed to reject task: $e');
    }
  }

  /// Refreshes the task list.
  Future<void> refresh() async {
    _logger.d('TaskListNotifier: Refreshing task list');
    ref.invalidateSelf();
  }

}


/// Provider for task filtering state.
@riverpod
class TaskFilterNotifier extends _$TaskFilterNotifier {
  @override
  TaskFilterType build() => TaskFilterType.all;
  
  void setFilter(TaskFilterType filter) {
    state = filter;
  }
}

