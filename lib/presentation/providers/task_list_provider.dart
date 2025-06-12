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

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TaskFilterType get currentFilter => _currentFilter;

  // Constructor now takes required dependencies directly
  TaskListProvider({
    required TaskServiceInterface taskService, // <--- Required parameter
    required AuthProvider authProvider, // <--- Required parameter
  }) : _taskService = taskService,
       _authProvider = authProvider {
    logger.d(
      "TaskListProvider initialized with dependencies. Performing initial fetch...",
    );
    _fetchTasksDebounced(); // Initial fetch happens here when created
  }

  // The `update` method is crucial for ChangeNotifierProxyProvider2
  // It checks if dependencies change and triggers a data refresh.
  void update(TaskServiceInterface taskService, AuthProvider authProvider) {
    // Only trigger a re-fetch if the *dependencies themselves* have changed.
    // If they are the same instances, no need to re-initialize or re-fetch.
    if (!identical(_taskService, taskService) ||
        !identical(_authProvider, authProvider)) {
      // (Note: _taskService and _authProvider are now final, so they cannot be reassigned here.
      // This update method conceptually signals a change, but doesn't reassign fields.
      // The main purpose of this method is to trigger the _fetchTasksDebounced
      // when a change in parent providers (like AuthProvider's user) occurs.)

      logger.d(
        "TaskListProvider dependencies observed to change. Triggering re-fetch...",
      );
      _fetchTasksDebounced();
    }
  }

  Timer? _fetchDebounceTimer;
  void _fetchTasksDebounced() {
    _fetchDebounceTimer?.cancel();
    _fetchDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (_authProvider.currentUserProfile != null &&
          _authProvider.userFamilyId != null) {
        fetchTasks(
          familyId: _authProvider.userFamilyId!,
          userId: _authProvider.currentUserProfile!.id,
        );
      } else {
        logger.w(
          "TaskListProvider: Cannot fetch tasks, user profile or family ID is null.",
        );
        _tasks = [];
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchTasks({
    required String familyId,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tasks = await _taskService.getTasks(
        familyId: familyId,
        userId: userId,
        filter: _currentFilter,
      );
      _tasks = tasks;
      _errorMessage = null;
    } catch (e, s) {
      logger.e(
        "TaskListProvider: Error fetching tasks: $e",
        error: e,
        stackTrace: s,
      );
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTaskStatus({
    required String familyId,
    required String taskId,
    required TaskStatus newStatus,
  }) async {
    try {
      await _taskService.updateTaskStatus(
        familyId: familyId,
        taskId: taskId,
        newStatus: newStatus,
      );
      // Refresh the task list after status update
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(status: newStatus);
        notifyListeners();
      }
    } catch (e, s) {
      logger.e(
        "TaskListProvider: Error updating task status: $e",
        error: e,
        stackTrace: s,
      );
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void setFilter(TaskFilterType filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      notifyListeners();
    }
  }

  Future<void> createTask({
    required String familyId,
    required Task task,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskService.createTask(familyId: familyId, task: task);
      // Refresh the task list after creating a new task
      await fetchTasks(familyId: familyId, userId: task.creatorId);
    } catch (e, s) {
      logger.e(
        "TaskListProvider: Error creating task: $e",
        error: e,
        stackTrace: s,
      );
      _errorMessage = e.toString();
      rethrow; // Rethrow to handle in the UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
