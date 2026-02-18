import 'dart:async';
import 'package:hoque_family_chores/domain/repositories/task_repository.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';

/// Mock implementation of TaskRepository for testing
class MockTaskRepository implements TaskRepository {
  final List<Task> _tasks = [];
  final StreamController<List<Task>> _taskStreamController = StreamController<List<Task>>.broadcast();

  MockTaskRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Create some mock tasks
    final mockTasks = [
      Task(
        id: TaskId('task_1'),
        title: 'Clean the kitchen',
        description: 'Wash dishes and clean countertops',
        status: TaskStatus.available,
        difficulty: TaskDifficulty.easy,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        assignedToId: null,
        createdById: UserId('user_1'),
        createdAt: DateTime.now(),
        completedAt: null,
        points: Points(10),
        tags: ['kitchen', 'cleaning'],
        recurringPattern: null,
        lastCompletedAt: null,
        familyId: FamilyId('family_1'),
      ),
      Task(
        id: TaskId('task_2'),
        title: 'Do laundry',
        description: 'Wash and fold clothes',
        status: TaskStatus.assigned,
        difficulty: TaskDifficulty.medium,
        dueDate: DateTime.now().add(const Duration(days: 2)),
        assignedToId: UserId('user_2'),
        createdById: UserId('user_1'),
        createdAt: DateTime.now(),
        completedAt: null,
        points: Points(15),
        tags: ['laundry', 'clothes'],
        recurringPattern: null,
        lastCompletedAt: null,
        familyId: FamilyId('family_1'),
      ),
      Task(
        id: TaskId('task_3'),
        title: 'Take out trash',
        description: 'Empty all trash bins',
        status: TaskStatus.completed,
        difficulty: TaskDifficulty.easy,
        dueDate: DateTime.now().subtract(const Duration(hours: 2)),
        assignedToId: UserId('user_3'),
        createdById: UserId('user_1'),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        completedAt: DateTime.now().subtract(const Duration(hours: 1)),
        points: Points(5),
        tags: ['trash', 'cleaning'],
        recurringPattern: null,
        lastCompletedAt: null,
        familyId: FamilyId('family_1'),
      ),
    ];

    _tasks.addAll(mockTasks);
    _taskStreamController.add(List.from(_tasks));
  }

  @override
  Future<List<Task>> getTasksForFamily(FamilyId familyId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      return _tasks.where((task) => task.familyId == familyId).toList();
    } catch (e) {
      throw ServerException('Failed to get tasks for family: $e', code: 'TASK_FETCH_ERROR');
    }
  }

  @override
  Future<List<Task>> getTasksForUser(UserId userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      return _tasks.where((task) => task.assignedToId == userId).toList();
    } catch (e) {
      throw ServerException('Failed to get tasks for user: $e', code: 'TASK_FETCH_ERROR');
    }
  }

  @override
  Future<Task> createTask(Task task) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final newTask = task.copyWith(
        id: TaskId('task_${_tasks.length + 1}'),
        createdAt: DateTime.now(),
      );
      
      _tasks.add(newTask);
      _taskStreamController.add(List.from(_tasks));
      
      return newTask;
    } catch (e) {
      throw ServerException('Failed to create task: $e', code: 'TASK_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateTask(Task task) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        _taskStreamController.add(List.from(_tasks));
      } else {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to update task: $e', code: 'TASK_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteTask(TaskId taskId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final initialLength = _tasks.length;
      _tasks.removeWhere((task) => task.id == taskId);
      
      if (_tasks.length == initialLength) {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }
      
      _taskStreamController.add(List.from(_tasks));
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to delete task: $e', code: 'TASK_DELETE_ERROR');
    }
  }

  @override
  Future<void> assignTask(TaskId taskId, UserId userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          assignedToId: userId,
          status: TaskStatus.assigned,
        );
        _taskStreamController.add(List.from(_tasks));
      } else {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to assign task: $e', code: 'TASK_ASSIGN_ERROR');
    }
  }

  @override
  Future<void> unassignTask(TaskId taskId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          assignedToId: null,
          status: TaskStatus.available,
        );
        _taskStreamController.add(List.from(_tasks));
      } else {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to unassign task: $e', code: 'TASK_UNASSIGN_ERROR');
    }
  }

  @override
  Future<void> completeTask(TaskId taskId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          status: TaskStatus.pendingApproval,
          completedAt: DateTime.now(),
        );
        _taskStreamController.add(List.from(_tasks));
      } else {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to complete task: $e', code: 'TASK_COMPLETE_ERROR');
    }
  }

  @override
  Future<void> uncompleteTask(TaskId taskId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          status: TaskStatus.assigned,
          completedAt: null,
        );
        _taskStreamController.add(List.from(_tasks));
      } else {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to uncomplete task: $e', code: 'TASK_UNCOMPLETE_ERROR');
    }
  }

  @override
  Future<void> updateTaskStatus(TaskId taskId, TaskStatus status) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(status: status);
        _taskStreamController.add(List.from(_tasks));
      } else {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to update task status: $e', code: 'TASK_STATUS_UPDATE_ERROR');
    }
  }

  @override
  Future<Task?> getTask(FamilyId familyId, TaskId taskId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final task = _tasks.where((task) => 
        task.id == taskId && task.familyId == familyId
      ).firstOrNull;
      
      return task;
    } catch (e) {
      throw ServerException('Failed to get task: $e', code: 'TASK_FETCH_ERROR');
    }
  }

  @override
  Stream<List<Task>> streamTasks(FamilyId familyId) {
    return _taskStreamController.stream
        .map((tasks) => tasks.where((task) => task.familyId == familyId).toList());
  }

  @override
  Stream<List<Task>> streamAvailableTasks(FamilyId familyId) {
    return _taskStreamController.stream
        .map((tasks) => tasks.where((task) => 
          task.familyId == familyId && task.status == TaskStatus.available
        ).toList());
  }

  @override
  Stream<List<Task>> streamTasksByAssignee(FamilyId familyId, UserId assigneeId) {
    return _taskStreamController.stream
        .map((tasks) => tasks.where((task) => 
          task.familyId == familyId && task.assignedToId == assigneeId
        ).toList());
  }

  @override
  Future<void> approveTask(TaskId taskId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          status: TaskStatus.completed,
        );
        _taskStreamController.add(List.from(_tasks));
      } else {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to approve task: $e', code: 'TASK_APPROVE_ERROR');
    }
  }

  @override
  Future<void> rejectTask(TaskId taskId, {String? comments}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          status: TaskStatus.needsRevision,
        );
        _taskStreamController.add(List.from(_tasks));
      } else {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to reject task: $e', code: 'TASK_REJECT_ERROR');
    }
  }

  @override
  Future<void> claimTask(TaskId taskId, UserId userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        final task = _tasks[index];
        if (task.status != TaskStatus.available) {
          throw ValidationException('Task is not available for claiming', code: 'TASK_NOT_AVAILABLE');
        }
        
        _tasks[index] = task.copyWith(
          assignedToId: userId,
          status: TaskStatus.assigned,
        );
        _taskStreamController.add(List.from(_tasks));
      } else {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to claim task: $e', code: 'TASK_CLAIM_ERROR');
    }
  }

  /// Dispose the stream controller
  void dispose() {
    _taskStreamController.close();
  }
} 