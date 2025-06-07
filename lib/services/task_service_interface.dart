// lib/services/task_service_interface.dart
import 'package:hoque_family_chores/models/task.dart';

abstract class TaskServiceInterface {
  // Keep this for a general 'all tasks' view
  Stream<List<Task>> streamAllTasks();

  // New method for the "My Tasks" filter
  Stream<List<Task>> streamMyTasks(String userId);

  // New method for the "Available" filter
  Stream<List<Task>> streamAvailableTasks();

  // New method for the "Completed" filter
  Stream<List<Task>> streamCompletedTasks();

  // ... (the other methods like assignTask, createTask, etc. remain)
  Future<void> assignTask({required String taskId, required String userId});
  Future<void> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String taskId);

  // These older Future-based methods can be phased out or kept for non-streaming needs
  Future<List<Task>> getMyPendingTasks(String userId);
  Future<List<Task>> getUnassignedTasks();
}
