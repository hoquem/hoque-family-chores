// lib/presentation/providers/available_tasks_provider.dart

import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';

/// Enum to represent the provider's state, matching what the UI widget expects.
enum AvailableTasksState { initial, loading, loaded, error }

class AvailableTasksProvider with ChangeNotifier {
  // Dependencies that will be injected by a ProxyProvider in main.dart.
  TaskServiceInterface? _taskService;
  AuthProvider? _authProvider;

  // Internal state properties.
  AvailableTasksState _state = AvailableTasksState.initial;
  String? _errorMessage;
  List<Task> _tasks = [];
  bool _isAssigning = false;

  // Public getters for the UI to consume, matching the expected names.
  AvailableTasksState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Task> get tasks => _tasks;
  bool get isAssigning => _isAssigning;

  /// Called by the ProxyProvider in main.dart to update dependencies.
  /// This approach ensures the provider always has the services it needs.
  void update(TaskServiceInterface taskService, AuthProvider authProvider) {
    if (_taskService != taskService || _authProvider != authProvider) {
      _taskService = taskService;
      _authProvider = authProvider;
      // Fetch data immediately when dependencies are available.
      fetchUnassignedTasks();
    }
  }

  /// Fetches the list of unassigned tasks from the data service.
  Future<void> fetchUnassignedTasks() async {
    // Ensure dependencies are ready before making a call.
    if (_taskService == null || _authProvider?.userFamilyId == null) {
      return;
    }

    _state = AvailableTasksState.loading;
    notifyListeners();

    try {
      // Correctly calls the service method with the required familyId from AuthProvider.
      _tasks = await _taskService!.getUnassignedTasks(familyId: _authProvider!.userFamilyId!);
      _state = AvailableTasksState.loaded;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _state = AvailableTasksState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Assigns a selected task to the currently logged-in user.
  /// The method name matches what the UI widget expects.
  Future<bool> selectTask(String taskId) async {
    if (_taskService == null ||
        _authProvider?.currentUserId == null ||
        _authProvider?.displayName == null) {
      _errorMessage = "Cannot assign task: user information is missing.";
      notifyListeners();
      return false;
    }

    _isAssigning = true;
    notifyListeners();

    try {
      // Correctly calls the service method with all required named arguments.
      await _taskService!.assignTask(
        taskId: taskId,
        userId: _authProvider!.currentUserId!,
        userName: _authProvider!.displayName!,
      );
      // Refresh the list of available tasks after one has been assigned.
      await fetchUnassignedTasks();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      // We don't need to notify here as the `finally` block will do it.
      return false;
    } finally {
      _isAssigning = false;
      notifyListeners();
    }
  }
}