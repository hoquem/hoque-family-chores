// lib/services/task_service_interface.dart
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/enums.dart'; // For TaskStatus

abstract class TaskServiceInterface {
  Stream<List<Task>> streamMyTasks({required String familyId, required String userId});
  Future<void> createTask({required String familyId, required Task task});
  Future<void> updateTask({required String familyId, required Task task}); // Generic update
  Future<void> updateTaskStatus({required String familyId, required String taskId, required TaskStatus newStatus}); // <--- ENSURE THIS LINE EXISTS
  Future<void> assignTask({required String familyId, required String taskId, required String assigneeId});
  Future<void> deleteTask({required String familyId, required String taskId});
  Future<Task?> getTask({required String familyId, required String taskId}); // Added during DataService sync
  Stream<List<Task>> streamTasks({required String familyId}); // Added for DataService sync
  Stream<List<Task>> streamAvailableTasks({required String familyId}); // If needed for a specific provider
  Stream<List<Task>> streamTasksByAssignee({required String familyId, required String assigneeId}); // For myTasks
  Future<void> approveTask({required String familyId, required String taskId, required String approverId}); // Assuming you have these
  Future<void> rejectTask({required String familyId, required String taskId, required String rejecterId, String? comments}); // Assuming you have these
  Future<void> claimTask({required String familyId, required String taskId, required String userId}); // Assuming you have these
}