import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/enums.dart';

abstract class TaskServiceInterface {
  Future<List<Task>> getTasksForFamily({required String familyId});
  Future<List<Task>> getTasksForUser({required String userId});
  Future<Task> createTask({required Task task});
  Future<void> updateTask({required Task task});
  Future<void> deleteTask({required String taskId});
  Future<void> assignTask({required String taskId, required String userId});
  Future<void> unassignTask({required String taskId});
  Future<void> completeTask({required String taskId});
  Future<void> uncompleteTask({required String taskId});
  Future<void> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
  });
  Future<Task?> getTask({required String familyId, required String taskId});
  Stream<List<Task>> streamTasks({required String familyId});
  Stream<List<Task>> streamAvailableTasks({required String familyId});
  Stream<List<Task>> streamTasksByAssignee({
    required String familyId,
    required String assigneeId,
  });
  Future<void> approveTask({required String taskId});
  Future<void> rejectTask({required String taskId, String? comments});
  Future<void> claimTask({required String taskId, required String userId});
}
