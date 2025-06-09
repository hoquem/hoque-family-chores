// lib/services/task_service.dart

import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/services/data_service_interface.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';

/// A specialized service or "repository" for handling only task-related logic.
/// It uses the main DataServiceInterface to communicate with the backend.
class TaskService implements TaskServiceInterface {
  final DataServiceInterface _dataService;

  TaskService(this._dataService);

  // Helper to convert maps from the data service into Task models
  List<Task> _mapToTaskList(List<Map<String, dynamic>> taskMaps) {
    return taskMaps.map((taskMap) => Task.fromMap(taskMap)).toList();
  }

  @override
  Stream<List<Task>> streamAllTasks({required String familyId}) {
    return _dataService.streamTasksByFamily(familyId: familyId).map(_mapToTaskList);
  }

  @override
  Stream<List<Task>> streamAvailableTasks({required String familyId}) {
    return _dataService
        .streamTasksByFamily(familyId: familyId, assigneeId: null) // Assuming assigneeId: null means available
        .map(_mapToTaskList);
  }

  @override
  Stream<List<Task>> streamCompletedTasks({required String familyId}) {
    return _dataService
        .streamTasksByFamily(familyId: familyId, status: TaskStatus.completed)
        .map(_mapToTaskList);
  }

  @override
  Stream<List<Task>> streamMyTasks({required String userId}) {
    // Assuming your data service stream can filter by assignee
    const String familyId = 'YOUR_FAMILY_ID'; // This needs to be fetched from user profile
    return _dataService
        .streamTasksByFamily(familyId: familyId, assigneeId: userId)
        .map(_mapToTaskList);
  }

  @override
  Future<void> assignTask({required String taskId, required String userId, required String userName}) async {
    // Use the generic updateTask method from the main data service
    return _dataService.updateTask(
      taskId: taskId,
      assigneeId: userId,
      status: TaskStatus.assigned,
      // You might want to add an 'assigneeName' field to updateTask if needed
    );
  }

  @override
  Future<List<Task>> getMyPendingTasks({required String userId}) async {
    final taskMaps = await _dataService.getTasksByAssignee(
      userId: userId, 
      status: TaskStatus.pending
    );
    return _mapToTaskList(taskMaps);
  }

  @override
  Future<List<Task>> getUnassignedTasks({required String familyId}) async {
    final taskMaps = await _dataService.getTasksByFamily(
      familyId: familyId,
      assigneeId: null, // A way to signify unassigned
      status: TaskStatus.pending,
    );
    return _mapToTaskList(taskMaps);
  }
}