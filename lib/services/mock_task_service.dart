import 'dart:async';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'package:hoque_family_chores/test_data/mock_data.dart'; // Import MockData

class MockTaskService implements TaskServiceInterface {
  // Initialize _tasks from MockData, ensuring Task.fromFirestore is correctly called
  final List<Task> _tasks =
      MockData.tasks
          .map((data) => Task.fromFirestore(data, data['id'] as String))
          .toList();

  final StreamController<List<Task>> _taskStreamController =
      StreamController<List<Task>>.broadcast();

  MockTaskService() {
    _taskStreamController.add(
      List.from(_tasks),
    ); // Initial emission of all tasks
    logger.i("MockTaskService initialized with dummy tasks from MockData.");
  }

  @override
  Stream<List<Task>> streamMyTasks({
    required String familyId,
    required String userId,
  }) {
    logger.d("Mock: Streaming tasks for family $familyId and user $userId.");
    return _taskStreamController.stream
        .map(
          (allTasks) =>
              allTasks
                  .where(
                    (task) =>
                        task.assigneeId == userId && task.familyId == familyId,
                  )
                  .toList(),
        )
        .handleError((e, s) {
          logger.e(
            "MockTaskService: Error streaming tasks: $e",
            error: e,
            stackTrace: s,
          );
        });
  }

  @override
  Future<void> createTask({
    required String familyId,
    required Task task,
  }) async {
    logger.d("Mock: Creating task for family $familyId.");
    final newTask = task.copyWith(id: 'mock_task_${_tasks.length + 1}');
    _tasks.add(newTask);
    _taskStreamController.add(List.from(_tasks)); // Notify listeners
  }

  @override
  Future<void> updateTask({
    required String familyId,
    required Task task,
  }) async {
    logger.d("Mock: Updating task ${task.id} for family $familyId.");
    final index = _tasks.indexWhere(
      (t) => t.id == task.id && t.familyId == familyId,
    );
    if (index != -1) {
      _tasks[index] = task; // Replace with updated task object
      _taskStreamController.add(List.from(_tasks)); // Notify listeners
    } else {
      logger.w(
        "MockTaskService: Task with ID ${task.id} not found for update.",
      );
    }
  }

  @override
  Future<void> updateTaskStatus({
    required String familyId,
    required String taskId,
    required TaskStatus newStatus,
  }) async {
    logger.d(
      "Mock: Updating status for task $taskId to ${newStatus.name} for family $familyId.",
    );
    final index = _tasks.indexWhere(
      (t) => t.id == taskId && t.familyId == familyId,
    );
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(status: newStatus);
      _taskStreamController.add(List.from(_tasks)); // Notify listeners
    } else {
      logger.w(
        "MockTaskService: Task with ID $taskId not found for status update.",
      );
    }
  }

  @override
  Future<void> assignTask({
    required String familyId,
    required String taskId,
    required String assigneeId,
  }) async {
    logger.d(
      "Mock: Assigning task $taskId to $assigneeId for family $familyId.",
    );
    final index = _tasks.indexWhere(
      (t) => t.id == taskId && t.familyId == familyId,
    );
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        assignedTo: FamilyMember(
          id: assigneeId,
          userId: assigneeId,
          familyId: familyId,
          name: 'Unknown User',
          role: FamilyRole.child,
          points: 0,
          joinedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        status: TaskStatus.assigned,
      );
      _taskStreamController.add(List.from(_tasks)); // Notify listeners
    } else {
      logger.w(
        "MockTaskService: Task with ID $taskId not found for assignment.",
      );
    }
  }

  @override
  Future<void> deleteTask({
    required String familyId,
    required String taskId,
  }) async {
    logger.d("Mock: Deleting task $taskId for family $familyId.");
    final initialLength = _tasks.length;
    _tasks.removeWhere(
      (task) => task.id == taskId && task.familyId == familyId,
    );
    if (_tasks.length != initialLength) {
      _taskStreamController.add(List.from(_tasks)); // Notify listeners
    } else {
      logger.w("MockTaskService: Task with ID $taskId not found for deletion.");
    }
  }

  @override
  Future<Task?> getTask({
    required String familyId,
    required String taskId,
  }) async {
    logger.d("Mock: Getting task $taskId for family $familyId.");
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate delay
    return _tasks.firstWhereOrNull(
      (task) => task.id == taskId && task.familyId == familyId,
    );
  }

  @override
  Stream<List<Task>> streamTasks({required String familyId}) {
    logger.d("Mock: Streaming all tasks for family ID: $familyId.");
    return _taskStreamController.stream
        .map(
          (allTasks) =>
              allTasks.where((task) => task.familyId == familyId).toList(),
        )
        .handleError((e, s) {
          logger.e(
            "MockTaskService: Error streaming all tasks: $e",
            error: e,
            stackTrace: s,
          );
        });
  }

  @override
  Stream<List<Task>> streamAvailableTasks({required String familyId}) {
    logger.d("Mock: Streaming available tasks for family ID: $familyId.");
    return _taskStreamController.stream
        .map(
          (allTasks) =>
              allTasks
                  .where(
                    (task) =>
                        task.familyId == familyId &&
                        task.status == TaskStatus.available,
                  )
                  .toList(),
        )
        .handleError((e, s) {
          logger.e(
            "MockTaskService: Error streaming available tasks: $e",
            error: e,
            stackTrace: s,
          );
        });
  }

  @override
  Stream<List<Task>> streamTasksByAssignee({
    required String familyId,
    required String assigneeId,
  }) {
    logger.d(
      "Mock: Streaming tasks by assignee $assigneeId for family $familyId.",
    );
    return _taskStreamController.stream
        .map(
          (allTasks) =>
              allTasks
                  .where(
                    (task) =>
                        task.familyId == familyId &&
                        task.assigneeId == assigneeId,
                  )
                  .toList(),
        )
        .handleError((e, s) {
          logger.e(
            "MockTaskService: Error streaming tasks by assignee: $e",
            error: e,
            stackTrace: s,
          );
        });
  }

  @override
  Future<void> approveTask({
    required String familyId,
    required String taskId,
    required String approverId,
  }) async {
    logger.d(
      "Mock: Approving task $taskId for family $familyId by $approverId.",
    );
    final index = _tasks.indexWhere(
      (t) => t.id == taskId && t.familyId == familyId,
    );
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(status: TaskStatus.completed);
      _taskStreamController.add(List.from(_tasks)); // Notify listeners
    } else {
      logger.w("MockTaskService: Task with ID $taskId not found for approval.");
    }
  }

  @override
  Future<void> rejectTask({
    required String familyId,
    required String taskId,
    required String rejecterId,
    String? comments,
  }) async {
    logger.d(
      "Mock: Rejecting task $taskId for family $familyId by $rejecterId.",
    );
    final index = _tasks.indexWhere(
      (t) => t.id == taskId && t.familyId == familyId,
    );
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(status: TaskStatus.needsRevision);
      _taskStreamController.add(List.from(_tasks)); // Notify listeners
    } else {
      logger.w(
        "MockTaskService: Task with ID $taskId not found for rejection.",
      );
    }
  }

  @override
  Future<void> claimTask({
    required String familyId,
    required String taskId,
    required String userId,
  }) async {
    logger.d(
      "Mock: Claiming task $taskId by user $userId for family $familyId.",
    );
    final index = _tasks.indexWhere(
      (t) => t.id == taskId && t.familyId == familyId,
    );
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        assignedTo: FamilyMember(
          id: userId,
          userId: userId,
          familyId: familyId,
          name: 'Unknown User',
          role: FamilyRole.child,
          points: 0,
          joinedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        status: TaskStatus.assigned,
      );
      _taskStreamController.add(List.from(_tasks)); // Notify listeners
    } else {
      logger.w("MockTaskService: Task with ID $taskId not found for claiming.");
    }
  }

  @override
  Future<List<Task>> getTasks({
    required String familyId,
    required String userId,
    required TaskFilterType filter,
  }) async {
    logger.d(
      "MockTaskService: Getting tasks for family $familyId and user $userId with filter $filter.",
    );
    final tasks = _tasks.where((task) => task.familyId == familyId).toList();
    switch (filter) {
      case TaskFilterType.all:
        return tasks;
      case TaskFilterType.myTasks:
        return tasks.where((task) => task.assigneeId == userId).toList();
      case TaskFilterType.available:
        return tasks
            .where((task) => task.status == TaskStatus.available)
            .toList();
      case TaskFilterType.completed:
        return tasks
            .where((task) => task.status == TaskStatus.completed)
            .toList();
    }
  }

  void dispose() {
    _taskStreamController.close();
    logger.i("MockTaskService disposed.");
  }
}

// Add a helper extension for List to mimic firstWhereOrNull if not available
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
