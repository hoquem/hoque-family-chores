import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'task_list_notifier.g.dart';

/// Manages the list of tasks for a family with filtering capabilities.
/// 
/// This notifier fetches tasks from the repository and provides
/// methods for creating, updating, and deleting tasks.
/// 
/// Example:
/// ```dart
/// final tasksAsync = ref.watch(taskListNotifierProvider(familyId));
/// final notifier = ref.read(taskListNotifierProvider(familyId).notifier);
/// await notifier.createTask(newTask);
/// ```
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
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('TaskListNotifier: Error creating task', error: e);
      throw Exception('Failed to create task: $e');
    }
  }

  /// Updates an existing task.
  Future<void> updateTask(Task task) async {
    _logger.d('TaskListNotifier: Updating task ${task.id}');
    
    try {
      final updateTaskUseCase = ref.read(updateTaskUseCaseProvider);
      final result = await updateTaskUseCase.call(task: task);
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('TaskListNotifier: Task updated successfully');
          ref.invalidateSelf();
        },
      );
    } catch (e) {
      _logger.e('TaskListNotifier: Error updating task', error: e);
      throw Exception('Failed to update task: $e');
    }
  }

  /// Deletes a task.
  Future<void> deleteTask(String taskId) async {
    _logger.d('TaskListNotifier: Deleting task $taskId');
    
    try {
      final deleteTaskUseCase = ref.read(deleteTaskUseCaseProvider);
      final result = await deleteTaskUseCase.call(taskId: TaskId(taskId));
      
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
      final result = await unassignTaskUseCase.call(taskId: TaskId(taskId));
      
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
      final result = await uncompleteTaskUseCase.call(taskId: TaskId(taskId));
      
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
      final result = await rejectTaskUseCase.call(taskId: TaskId(taskId));
      
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

/// Computed provider that returns filtered tasks based on the current filter.
@riverpod
List<Task> filteredTasks(Ref ref, FamilyId familyId) {
  final tasksAsync = ref.watch(taskListNotifierProvider(familyId));
  final filter = ref.watch(taskFilterNotifierProvider);
  
  return tasksAsync.when(
    data: (tasks) => _filterTasks(tasks, filter),
    loading: () => [],
    error: (_, __) => [],
  );
}

/// Filters tasks based on the specified filter type.
List<Task> _filterTasks(List<Task> tasks, TaskFilterType filter) {
  switch (filter) {
    case TaskFilterType.all:
      return tasks;
    case TaskFilterType.myTasks:
      // This would need the current user ID to filter properly
      return tasks;
    case TaskFilterType.available:
      return tasks.where((task) => task.status == TaskStatus.available).toList();
    case TaskFilterType.completed:
      return tasks.where((task) => task.status == TaskStatus.completed).toList();
  }
} 