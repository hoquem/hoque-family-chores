// lib/services/task_service_interface.dart
import '../models/task.dart';

abstract class TaskServiceInterface {
  /// Fetches a list of pending tasks for a specific user.
  Future<List<Task>> getMyPendingTasks(String userId);
}