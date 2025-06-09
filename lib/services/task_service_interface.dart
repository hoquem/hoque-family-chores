// lib/services/task_service_interface.dart
import 'package:hoque_family_chores/models/task.dart';

abstract class TaskServiceInterface {
  // ... existing stream methods ...
  Stream<List<Task>> streamAllTasks({required String familyId});
  Stream<List<Task>> streamMyTasks({required String userId});
  Stream<List<Task>> streamAvailableTasks({required String familyId});
  Stream<List<Task>> streamCompletedTasks({required String familyId});

  // ADDED: Methods required by your other providers
  Future<List<Task>> getUnassignedTasks({required String familyId});
  Future<void> assignTask({required String taskId, required String userId, required String userName});
  Future<List<Task>> getMyPendingTasks({required String userId});
}