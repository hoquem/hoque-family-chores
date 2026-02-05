import 'dart:async';
import '../entities/task.dart';
import '../value_objects/family_id.dart';
import '../value_objects/user_id.dart';
import '../value_objects/task_id.dart';

/// Abstract interface for task data operations
abstract class TaskRepository {
  /// Get all tasks for a family
  Future<List<Task>> getTasksForFamily(FamilyId familyId);

  /// Get tasks for a specific user
  Future<List<Task>> getTasksForUser(UserId userId);

  /// Create a new task
  Future<Task> createTask(Task task);

  /// Update an existing task
  Future<void> updateTask(Task task);

  /// Delete a task
  Future<void> deleteTask(TaskId taskId);

  /// Assign a task to a user
  Future<void> assignTask(TaskId taskId, UserId userId);

  /// Unassign a task
  Future<void> unassignTask(TaskId taskId);

  /// Complete a task
  Future<void> completeTask(TaskId taskId);

  /// Uncomplete a task
  Future<void> uncompleteTask(TaskId taskId);

  /// Update task status
  Future<void> updateTaskStatus(TaskId taskId, TaskStatus status);

  /// Get a specific task
  Future<Task?> getTask(FamilyId familyId, TaskId taskId);

  /// Stream all tasks for a family
  Stream<List<Task>> streamTasks(FamilyId familyId);

  /// Stream available tasks for a family
  Stream<List<Task>> streamAvailableTasks(FamilyId familyId);

  /// Stream tasks assigned to a specific user
  Stream<List<Task>> streamTasksByAssignee(FamilyId familyId, UserId assigneeId);

  /// Approve a task
  Future<void> approveTask(TaskId taskId);

  /// Reject a task
  Future<void> rejectTask(TaskId taskId, {String? comments});

  /// Claim a task
  Future<void> claimTask(TaskId taskId, UserId userId);
} 