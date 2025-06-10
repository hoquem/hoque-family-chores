import 'package:flutter/material.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/enums.dart'; // For TaskFilterType, TaskStatus
import 'package:hoque_family_chores/services/task_service_interface.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'dart:async';

class TaskListProvider with ChangeNotifier {
  // Make these final and required in the constructor
  final TaskServiceInterface _taskService;
  final AuthProvider _authProvider;

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  TaskFilterType _currentFilter = TaskFilterType.all;

  List<Task> get tasks {
    switch (_currentFilter) {
      case TaskFilterType.myTasks:
        final currentUserId = _authProvider.currentUserId;
        if (currentUserId == null) return [];
        return _tasks.where((task) => task.assigneeId == currentUserId).toList();
      case TaskFilterType.available:
        return _tasks.where((task) => task.status == TaskStatus.available).toList();
      case TaskFilterType.completed:
        return _tasks.where((task) => task.status == TaskStatus.completed).toList();
      case TaskFilterType.all:
        return _tasks;
    }
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TaskFilterType get currentFilter => _currentFilter;

  // Constructor now takes required dependencies directly
  TaskListProvider({
    required TaskServiceInterface taskService, // <--- Required parameter
    required AuthProvider authProvider,       // <--- Required parameter
  })  : _taskService = taskService,
        _authProvider = authProvider {
    logger.d("TaskListProvider initialized with dependencies. Performing initial fetch...");
    _fetchTasksDebounced(); // Initial fetch happens here when created
  }

  // The `update` method is crucial for ChangeNotifierProxyProvider2
  // It checks if dependencies change and triggers a data refresh.
  void update(TaskServiceInterface taskService, AuthProvider authProvider) {
    // Only trigger a re-fetch if the *dependencies themselves* have changed.
    // If they are the same instances, no need to re-initialize or re-fetch.
    if (!identical(_taskService, taskService) || !identical(_authProvider, authProvider)) {
      // (Note: _taskService and _authProvider are now final, so they cannot be reassigned here.
      // This update method conceptually signals a change, but doesn't reassign fields.
      // The main purpose of this method is to trigger the _fetchTasksDebounced
      // when a change in parent providers (like AuthProvider's user) occurs.)

      logger.d("TaskListProvider dependencies observed to change. Triggering re-fetch...");
      _fetchTasksDebounced();
    }
  }

  Timer? _fetchDebounceTimer;
  void _fetchTasksDebounced() {
    _fetchDebounceTimer?.cancel();
    _fetchDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (_authProvider.currentUserProfile != null && _authProvider.userFamilyId != null) {
        fetchTasks(
          familyId: _authProvider.userFamilyId!,
          userId: _authProvider.currentUserProfile!.id,
        );
      } else {
        logger.w("TaskListProvider: Cannot fetch tasks, user profile or family ID is null.");
        _tasks = [];
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchTasks({required String familyId, required String userId}) async {
    if (_isLoading && _tasks.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    if (_tasks.isEmpty) {
       notifyListeners();
    }
    logger.i("Fetching tasks for user $userId in family $familyId...");

    try {
      _taskService.streamTasksByAssignee(familyId: familyId, assigneeId: userId).listen(
        (taskList) {
          logger.d("Tasks received: ${taskList.length} tasks.");
          _tasks = taskList;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (e, s) {
          _errorMessage = 'Failed to load tasks: $e';
          _isLoading = false;
          notifyListeners();
          logger.e("Error fetching tasks: $e", error: e, stackTrace: s);
        },
        onDone: () {
          logger.i("Task stream completed (should not happen for continuous streams).");
        },
      );
    } catch (e, s) {
      _errorMessage = 'An unexpected error occurred while setting up task stream: $e';
      _isLoading = false;
      notifyListeners();
      logger.e("Unexpected error setting up task stream: $e", error: e, stackTrace: s);
    }
  }

  Future<void> updateTaskStatus({
    required String familyId,
    required String taskId,
    required TaskStatus newStatus,
  }) async {
    final originalTasks = List<Task>.from(_tasks);
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(status: newStatus);
      notifyListeners();
    }

    _isLoading = true;
    _errorMessage = null;
    logger.i("Updating status for task $taskId to $newStatus.");

    try {
      await _taskService.updateTaskStatus(
        familyId: familyId,
        taskId: taskId,
        newStatus: newStatus,
      );
      _isLoading = false;
      logger.d("Task $taskId status updated successfully.");
    } catch (e, s) {
      _errorMessage = 'Failed to update task status: $e';
      _isLoading = false;
      if (taskIndex != -1) {
        _tasks = originalTasks;
      }
      notifyListeners();
      logger.e("Error updating task status $taskId: $e", error: e, stackTrace: s);
    }
  }

  void setFilter(TaskFilterType filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      logger.d("Task list filter set to: $filter");
      notifyListeners();
    }
  }

  void dispose() {
    super.dispose();
  }
}