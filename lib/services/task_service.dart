// lib/services/task_service.dart
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/enums.dart'; // For TaskStatus
import 'package:hoque_family_chores/services/task_service_interface.dart';
import 'package:hoque_family_chores/services/data_service_interface.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // No longer needed if delegating to DataService

class TaskService implements TaskServiceInterface {
  final DataServiceInterface _dataService;

  TaskService(this._dataService);

  @override
  Stream<List<Task>> streamMyTasks({required String familyId, required String userId}) {
    logger.d("TaskService: Streaming tasks for family $familyId and user $userId via DataService.");
    return _dataService.streamTasksByAssignee(familyId: familyId, assigneeId: userId);
  }

  @override
  Future<void> createTask({required String familyId, required Task task}) async {
    logger.d("TaskService: Creating task for family $familyId via DataService.");
    return _dataService.createTask(familyId: familyId, task: task);
  }

  @override
  Future<void> updateTask({required String familyId, required Task task}) async {
    logger.d("TaskService: Updating task ${task.id} for family $familyId via DataService.");
    return _dataService.updateTask(familyId: familyId, task: task);
  }

  @override
  Future<void> updateTaskStatus({required String familyId, required String taskId, required TaskStatus newStatus}) async {
    logger.d("TaskService: Updating status for task $taskId to ${newStatus.name} for family $familyId via DataService.");
    return _dataService.updateTaskStatus(familyId: familyId, taskId: taskId, newStatus: newStatus);
  }

  @override
  Future<void> assignTask({required String familyId, required String taskId, required String assigneeId}) async {
    logger.d("TaskService: Assigning task $taskId to $assigneeId for family $familyId via DataService.");
    return _dataService.assignTask(familyId: familyId, taskId: taskId, assigneeId: assigneeId);
  }

  @override
  Future<void> deleteTask({required String familyId, required String taskId}) async {
    logger.d("TaskService: Deleting task $taskId for family $familyId via DataService.");
    return _dataService.deleteTask(familyId: familyId, taskId: taskId);
  }

  @override
  Future<Task?> getTask({required String familyId, required String taskId}) async {
    logger.d("TaskService: Getting task $taskId for family $familyId via DataService.");
    return _dataService.getTask(familyId: familyId, taskId: taskId);
  }

  @override
  Stream<List<Task>> streamTasks({required String familyId}) {
    logger.d("TaskService: Streaming all tasks for family $familyId via DataService.");
    return _dataService.streamTasks(familyId: familyId);
  }

  @override
  Stream<List<Task>> streamAvailableTasks({required String familyId}) {
    logger.d("TaskService: Streaming available tasks for family $familyId via DataService.");
    // This requires a specific query in DataService or local filtering.
    // Assuming DataService.streamTasks can be filtered or you add a specific method.
    return _dataService.streamTasks(familyId: familyId)
        .map((tasks) => tasks.where((task) => task.status == TaskStatus.available).toList());
  }

  @override
  Stream<List<Task>> streamTasksByAssignee({required String familyId, required String assigneeId}) {
    logger.d("TaskService: Streaming tasks by assignee $assigneeId for family $familyId via DataService.");
    return _dataService.streamTasksByAssignee(familyId: familyId, assigneeId: assigneeId);
  }

  @override
  Future<void> approveTask({required String familyId, required String taskId, required String approverId}) async {
    logger.d("TaskService: Approving task $taskId for family $familyId via DataService.");
    return _dataService.updateTaskStatus(familyId: familyId, taskId: taskId, newStatus: TaskStatus.completed);
  }

  @override
  Future<void> rejectTask({required String familyId, required String taskId, required String rejecterId, String? comments}) async {
    logger.d("TaskService: Rejecting task $taskId for family $familyId via DataService.");
    // This might require a custom update to add comments as well.
    // For now, setting status. If comments need to be stored in Task, updateTask is better.
    return _dataService.updateTaskStatus(familyId: familyId, taskId: taskId, newStatus: TaskStatus.needsRevision);
  }

  @override
  Future<void> claimTask({required String familyId, required String taskId, required String userId}) async {
    logger.d("TaskService: Claiming task $taskId by user $userId for family $familyId via DataService.");
    return _dataService.assignTask(familyId: familyId, taskId: taskId, assigneeId: userId);
  }
}