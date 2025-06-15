import 'dart:async';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/enums.dart'; // For TaskStatus
import 'package:hoque_family_chores/services/interfaces/task_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/test_data/mock_data.dart'; // Import MockData
import 'package:collection/collection.dart';

class MockTaskService implements TaskServiceInterface {
  // Initialize _tasks from MockData, ensuring Task.fromJson is correctly called
  final List<Task> _tasks =
      MockData.tasks.map((data) => Task.fromJson(data)).toList();

  final StreamController<List<Task>> _taskStreamController =
      StreamController<List<Task>>.broadcast();

  final _logger = AppLogger();

  MockTaskService() {
    _taskStreamController.add(
      List.from(_tasks),
    ); // Initial emission of all tasks
    _logger.i("MockTaskService initialized with dummy tasks from MockData.");
  }

  @override
  Future<List<Task>> getTasksForFamily({required String familyId}) {
    return ServiceUtils.handleServiceCall(
      operation:
          () async =>
              _tasks.where((task) => task.familyId == familyId).toList(),
      operationName: 'getTasksForFamily',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<List<Task>> getTasksForUser({required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation:
          () async =>
              _tasks.where((task) => task.assignedTo == userId).toList(),
      operationName: 'getTasksForUser',
      context: {'userId': userId},
    );
  }

  @override
  Future<Task> createTask({required Task task}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        _logger.d("Mock: Creating task for family ${task.familyId}.");
        final newTask = task.copyWith(id: 'mock_task_${_tasks.length + 1}');
        _tasks.add(newTask);
        _taskStreamController.add(List.from(_tasks)); // Notify listeners
        return newTask;
      },
      operationName: 'createTask',
      context: {'familyId': task.familyId},
    );
  }

  @override
  Future<void> updateTask({required Task task}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        _logger.d(
          "Mock: Updating task ${task.id} for family ${task.familyId}.",
        );
        final index = _tasks.indexWhere(
          (t) => t.id == task.id && t.familyId == task.familyId,
        );
        if (index != -1) {
          _tasks[index] = task; // Replace with updated task object
          _taskStreamController.add(List.from(_tasks)); // Notify listeners
        } else {
          _logger.w(
            "MockTaskService: Task with ID ${task.id} not found for update.",
          );
        }
      },
      operationName: 'updateTask',
      context: {'familyId': task.familyId, 'taskId': task.id},
    );
  }

  @override
  Future<void> deleteTask({required String taskId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        _logger.d("Mock: Deleting task $taskId.");
        final initialLength = _tasks.length;
        _tasks.removeWhere((task) => task.id == taskId);
        if (_tasks.length != initialLength) {
          _taskStreamController.add(List.from(_tasks)); // Notify listeners
        } else {
          _logger.w(
            "MockTaskService: Task with ID $taskId not found for deletion.",
          );
        }
      },
      operationName: 'deleteTask',
      context: {'taskId': taskId},
    );
  }

  @override
  Future<void> assignTask({required String taskId, required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        _logger.d("Mock: Assigning task $taskId to $userId.");
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(
            assignedTo: userId,
            status: TaskStatus.assigned,
          );
          _taskStreamController.add(List.from(_tasks)); // Notify listeners
        } else {
          _logger.w(
            "MockTaskService: Task with ID $taskId not found for assignment.",
          );
        }
      },
      operationName: 'assignTask',
      context: {'taskId': taskId, 'userId': userId},
    );
  }

  @override
  Future<void> unassignTask({required String taskId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        _logger.d("Mock: Unassigning task $taskId.");
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(
            assignedTo: null,
            status: TaskStatus.available,
          );
          _taskStreamController.add(List.from(_tasks)); // Notify listeners
        } else {
          _logger.w(
            "MockTaskService: Task with ID $taskId not found for unassignment.",
          );
        }
      },
      operationName: 'unassignTask',
      context: {'taskId': taskId},
    );
  }

  @override
  Future<void> completeTask({required String taskId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        _logger.d("Mock: Completing task $taskId.");
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(
            status: TaskStatus.pendingApproval,
          );
          _taskStreamController.add(List.from(_tasks)); // Notify listeners
        } else {
          _logger.w(
            "MockTaskService: Task with ID $taskId not found for completion.",
          );
        }
      },
      operationName: 'completeTask',
      context: {'taskId': taskId},
    );
  }

  @override
  Future<void> uncompleteTask({required String taskId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        _logger.d("Mock: Uncompleting task $taskId.");
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(status: TaskStatus.assigned);
          _taskStreamController.add(List.from(_tasks)); // Notify listeners
        } else {
          _logger.w(
            "MockTaskService: Task with ID $taskId not found for uncompletion.",
          );
        }
      },
      operationName: 'uncompleteTask',
      context: {'taskId': taskId},
    );
  }

  @override
  Future<void> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        _logger.d("Mock: Updating status for task $taskId to ${status.name}.");
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(status: status);
          _taskStreamController.add(List.from(_tasks)); // Notify listeners
        } else {
          _logger.w(
            "MockTaskService: Task with ID $taskId not found for status update.",
          );
        }
      },
      operationName: 'updateTaskStatus',
      context: {'taskId': taskId, 'status': status.name},
    );
  }

  @override
  Future<Task?> getTask({required String familyId, required String taskId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        _logger.d("Mock: Getting task $taskId for family $familyId.");
        await Future.delayed(
          const Duration(milliseconds: 50),
        ); // Simulate delay
        return _tasks.firstWhereOrNull(
          (task) => task.id == taskId && task.familyId == familyId,
        );
      },
      operationName: 'getTask',
      context: {'familyId': familyId, 'taskId': taskId},
    );
  }

  @override
  Stream<List<Task>> streamTasks({required String familyId}) {
    return ServiceUtils.handleServiceStream(
      stream: () {
        _logger.d("Mock: Streaming all tasks for family ID: $familyId.");
        return _taskStreamController.stream.map(
          (tasks) => tasks.where((task) => task.familyId == familyId).toList(),
        );
      },
      streamName: 'streamTasks',
      context: {'familyId': familyId},
    );
  }

  @override
  Stream<List<Task>> streamAvailableTasks({required String familyId}) {
    return ServiceUtils.handleServiceStream(
      stream: () {
        _logger.d("Mock: Streaming available tasks for family ID: $familyId.");
        return _taskStreamController.stream.map(
          (tasks) =>
              tasks
                  .where(
                    (task) =>
                        task.familyId == familyId &&
                        task.status == TaskStatus.available,
                  )
                  .toList(),
        );
      },
      streamName: 'streamAvailableTasks',
      context: {'familyId': familyId},
    );
  }

  @override
  Stream<List<Task>> streamTasksByAssignee({
    required String familyId,
    required String assigneeId,
  }) {
    return ServiceUtils.handleServiceStream(
      stream: () {
        _logger.d(
          "Mock: Streaming tasks for family ID: $familyId and assignee ID: $assigneeId.",
        );
        return _taskStreamController.stream.map(
          (tasks) =>
              tasks
                  .where(
                    (task) =>
                        task.familyId == familyId &&
                        task.assignedTo == assigneeId,
                  )
                  .toList(),
        );
      },
      streamName: 'streamTasksByAssignee',
      context: {'familyId': familyId, 'assigneeId': assigneeId},
    );
  }

  @override
  Future<void> approveTask({required String taskId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        _logger.d("Mock: Approving task $taskId.");
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(
            status: TaskStatus.completed,
            completedAt: DateTime.now(),
          );
          _taskStreamController.add(List.from(_tasks)); // Notify listeners
        } else {
          _logger.w(
            "MockTaskService: Task with ID $taskId not found for approval.",
          );
        }
      },
      operationName: 'approveTask',
      context: {'taskId': taskId},
    );
  }

  @override
  Future<void> rejectTask({required String taskId, String? comments}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        _logger.d("Mock: Rejecting task $taskId with comments: $comments");
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(
            status: TaskStatus.assigned,
            completedAt: null,
          );
          _taskStreamController.add(List.from(_tasks)); // Notify listeners
        } else {
          _logger.w(
            "MockTaskService: Task with ID $taskId not found for rejection.",
          );
        }
      },
      operationName: 'rejectTask',
      context: {'taskId': taskId, 'comments': comments},
    );
  }

  @override
  Future<void> claimTask({required String taskId, required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        _logger.d("Mock: Claiming task $taskId by user $userId.");
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(
            assignedTo: userId,
            status: TaskStatus.assigned,
          );
          _taskStreamController.add(List.from(_tasks)); // Notify listeners
        } else {
          _logger.w(
            "MockTaskService: Task with ID $taskId not found for claiming.",
          );
        }
      },
      operationName: 'claimTask',
      context: {'taskId': taskId, 'userId': userId},
    );
  }

  void dispose() {
    _taskStreamController.close();
  }
}
