// lib/services/task_service_interface.dart
import 'package:hoque_family_chores/models/task.dart';

abstract class TaskServiceInterface {
  /// Returns a live-updating stream of all tasks.
  Stream<List<Task>> streamAllTasks();

  /// Fetches a list of pending tasks for a specific user.
  Future<List<Task>> getMyPendingTasks(String userId);

  /// Fetches a list of available, unassigned tasks.
  Future<List<Task>> getUnassignedTasks();

  /// Assigns a specific task to a user.
  Future<void> assignTask({required String taskId, required String userId});

  /// Creates a new task in the database.
  Future<void> createTask(Task task);

  /// Updates an existing task.
  Future<void> updateTask(Task task);

  /// Deletes a task by its ID.
  Future<void> deleteTask(String taskId);
}