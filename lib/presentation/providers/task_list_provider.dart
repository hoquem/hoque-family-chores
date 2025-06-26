import 'package:flutter/material.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/services/interfaces/task_service_interface.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'dart:async';

class TaskListProvider with ChangeNotifier {
  TaskServiceInterface _taskService;
  AuthProvider _authProvider;
  final _logger = AppLogger();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  TaskFilterType _currentFilter = TaskFilterType.all;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TaskFilterType get currentFilter => _currentFilter;

  TaskListProvider({
    required TaskServiceInterface taskService,
    required AuthProvider authProvider,
  }) : _taskService = taskService,
       _authProvider = authProvider {
    _logger.d(
      "TaskListProvider initialized with dependencies. Waiting for authentication...",
    );
    _logger.d("TaskListProvider: AuthProvider reference: $_authProvider");
    _logger.d("TaskListProvider: TaskService reference: $_taskService");
    // Listen to auth provider changes
    _authProvider.addListener(_onAuthChanged);
    _logger.d("TaskListProvider: Added listener to AuthProvider");
    
    // Check if user is already authenticated when provider is created
    _logger.d("TaskListProvider: Checking if user is already authenticated");
    _logger.d("TaskListProvider: Current auth status: ${_authProvider.status}");
    _logger.d("TaskListProvider: Current user profile: ${_authProvider.currentUserProfile?.member.id}");
    _logger.d("TaskListProvider: Current family ID: ${_authProvider.userFamilyId}");
    
    // If user is already authenticated, fetch tasks immediately
    if (_authProvider.currentUserProfile != null && _authProvider.userFamilyId != null) {
      _logger.d("TaskListProvider: User already authenticated, fetching tasks immediately");
      _fetchTasksDebounced();
    } else {
      _logger.d("TaskListProvider: User not authenticated yet, waiting for auth change");
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    _fetchDebounceTimer?.cancel();
    super.dispose();
  }

  void _onAuthChanged() {
    _logger.d("TaskListProvider: Auth state changed, checking if we should fetch data");
    _logger.d("TaskListProvider: Auth status: ${_authProvider.status}");
    _logger.d("TaskListProvider: Current user profile: ${_authProvider.currentUserProfile?.member.id}");
    _logger.d("TaskListProvider: Current family ID: ${_authProvider.userFamilyId}");
    _logger.d("TaskListProvider: Is loading: ${_authProvider.isLoading}");
    _fetchTasksDebounced();
  }

  Timer? _fetchDebounceTimer;
  void _fetchTasksDebounced() {
    _logger.d("TaskListProvider: _fetchTasksDebounced called");
    _fetchDebounceTimer?.cancel();
    _fetchDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      _logger.d("TaskListProvider: Debounced fetch executing");
      _logger.d("TaskListProvider: User profile: ${_authProvider.currentUserProfile?.member.id}");
      _logger.d("TaskListProvider: Family ID: ${_authProvider.userFamilyId}");
      if (_authProvider.currentUserProfile != null &&
          _authProvider.userFamilyId != null) {
        _logger.d("TaskListProvider: Calling fetchTasks");
        fetchTasks(
          familyId: _authProvider.userFamilyId!,
          userId: _authProvider.currentUserProfile!.member.id,
        );
      } else {
        _logger.w(
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
      _logger.d(
        'TaskListProvider: Fetching tasks for family $familyId and user $userId',
      );
      final tasks = await _taskService.getTasksForFamily(familyId: familyId);
      _logger.d('TaskListProvider: Received ${tasks.length} tasks');
      _tasks = tasks;
      _errorMessage = null;

      // If no tasks exist, create a default one
      if (_tasks.isEmpty) {
        _logger.d(
          'TaskListProvider: No tasks found, creating a default task...',
        );
        final now = DateTime.now();
        final defaultTask = Task(
          id: '', // Will be set by Firestore
          title: 'Welcome Task',
          description: 'This is your first task! Edit or delete as needed.',
          points: 10,
          difficulty: TaskDifficulty.easy,
          status: TaskStatus.available,
          familyId: familyId,
          assignedTo: null,
          createdAt: now,
          dueDate: now.add(const Duration(days: 7)),
          completedAt: null,
          tags: const [],
        );

        try {
          _logger.d(
            'TaskListProvider: Creating default task with ID ${defaultTask.id}',
          );
          await _taskService.createTask(task: defaultTask);
          _logger.d('TaskListProvider: Default task created successfully');

          // Fetch again to update the list
          _tasks = await _taskService.getTasksForFamily(familyId: familyId);
          _logger.d(
            'TaskListProvider: Refetched tasks after creating default task',
          );
        } catch (e, s) {
          _logger.e(
            'TaskListProvider: Error creating default task: $e',
            error: e,
            stackTrace: s,
          );
          _errorMessage = 'Failed to create default task: ${e.toString()}';
        }
      }
    } catch (e, s) {
      _logger.e(
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
      await _taskService.updateTaskStatus(taskId: taskId, status: newStatus);
      // Refresh the task list after status update
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(status: newStatus);
        notifyListeners();
      }
    } catch (e, s) {
      _logger.e(
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
    _logger.i('TaskListProvider: Starting task creation for family $familyId');
    _logger.d('Task details: ${task.toJson()}');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate task data before sending to service
      if (task.title.isEmpty) {
        throw Exception('Task title cannot be empty');
      }

      final createdTask = await _taskService.createTask(task: task);
      _logger.i(
        'TaskListProvider: Task created successfully with ID ${createdTask.id}',
      );

      // Add the new task to the list
      _tasks.add(createdTask);
      _errorMessage = null;
    } catch (e, s) {
      _logger.e(
        'TaskListProvider: Error creating task: $e',
        error: e,
        stackTrace: s,
      );
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTask({
    required String familyId,
    required Task task,
  }) async {
    _logger.i('TaskListProvider: Starting task update for task ${task.id}');
    _logger.d('Updated task details: ${task.toJson()}');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskService.updateTask(task: task);
      _logger.i('TaskListProvider: Task updated successfully');

      // Update the task in the list
      final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        _tasks[taskIndex] = task;
      }
      _errorMessage = null;
    } catch (e, s) {
      _logger.e(
        'TaskListProvider: Error updating task: $e',
        error: e,
        stackTrace: s,
      );
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask({
    required String familyId,
    required String taskId,
  }) async {
    _logger.i('TaskListProvider: Starting task deletion for task $taskId');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskService.deleteTask(taskId: taskId);
      _logger.i('TaskListProvider: Task deleted successfully');

      // Remove the task from the list
      _tasks.removeWhere((t) => t.id == taskId);
      _errorMessage = null;
    } catch (e, s) {
      _logger.e(
        'TaskListProvider: Error deleting task: $e',
        error: e,
        stackTrace: s,
      );
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void update(TaskServiceInterface taskService, AuthProvider authProvider) {
    _taskService = taskService;
    _authProvider = authProvider;
    notifyListeners();
  }
}
