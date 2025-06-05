// lib/services/task_service_interface.dart
import '../models/task.dart';

abstract class TaskServiceInterface {
  /// Fetches a list of pending tasks for a specific user.
  Future<List<Task>> getMyPendingTasks(String userId);

  /// Fetches a list of available, unassigned tasks.
  Future<List<Task>> getUnassignedTasks();

  /// Assigns a specific task to a user.
  Future<void> assignTask({required String taskId, required String userId});
}