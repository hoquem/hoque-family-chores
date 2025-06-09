// lib/services/mock_task_service.dart

import 'dart:async';
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';
import 'package:hoque_family_chores/test_data/mock_data.dart'; // Assuming mock tasks are here

class MockTaskService implements TaskServiceInterface {
  // Use data from your main MockData source and convert it to Task objects
  final List<Task> _tasks = MockData.tasks
      .map((taskMap) => Task.fromMap(taskMap))
      .toList();
      
  final _tasksStreamController = StreamController<List<Task>>.broadcast();

  MockTaskService() {
    // Immediately push the initial list to the stream
    _tasksStreamController.add(_tasks);
  }

  // All method signatures now correctly match the interface
  @override
  Future<void> assignTask({required String taskId, required String userId, required String userName}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final oldTask = _tasks[taskIndex];
      _tasks[taskIndex] = Task(
        id: oldTask.id,
        title: oldTask.title,
        description: oldTask.description,
        points: oldTask.points,
        status: TaskStatus.assigned, // Update status
        assigneeName: userName, // Update assignee
        dueDate: oldTask.dueDate,
      );
      _tasksStreamController.add(List.from(_tasks)); // Push update to stream
    }
  }

  @override
  Future<List<Task>> getMyPendingTasks({required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _tasks
        .where((t) => t.assigneeName != null && t.status == TaskStatus.pending)
        .toList();
  }

  @override
  Future<List<Task>> getUnassignedTasks({required String familyId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _tasks.where((t) => t.assigneeName == null).toList();
  }

  @override
  Stream<List<Task>> streamAllTasks({required String familyId}) {
    return _tasksStreamController.stream;
  }

  @override
  Stream<List<Task>> streamAvailableTasks({required String familyId}) {
    return _tasksStreamController.stream.map(
        (tasks) => tasks.where((t) => t.assigneeName == null).toList());
  }

  @override
  Stream<List<Task>> streamCompletedTasks({required String familyId}) {
    return _tasksStreamController.stream.map((tasks) =>
        tasks.where((t) => t.status == TaskStatus.completed || t.status == TaskStatus.verified).toList());
  }

  @override
  Stream<List<Task>> streamMyTasks({required String userId}) {
    // In a real mock, you'd filter by userId, but we use assigneeName here
    return _tasksStreamController.stream.map((tasks) =>
        tasks.where((t) => t.assigneeName != null && t.status != TaskStatus.completed).toList());
  }
}