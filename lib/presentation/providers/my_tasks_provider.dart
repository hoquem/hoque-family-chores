// lib/presentation/providers/my_tasks_provider.dart
import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';

// MODIFIED: State enum to match what the widget expects
enum MyTasksState { initial, loading, loaded, error }

class MyTasksProvider with ChangeNotifier {
  TaskServiceInterface? _taskService;
  AuthProvider? _authProvider;

  // MODIFIED: Public properties to match what the widget expects
  MyTasksState _state = MyTasksState.initial;
  String? _errorMessage;
  List<Task> _tasks = [];

  MyTasksState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Task> get tasks => _tasks; // The widget expects 'tasks'

  void update(TaskServiceInterface taskService, AuthProvider authProvider) {
    _taskService = taskService;
    _authProvider = authProvider;
    fetchMyTasks();
  }

  Future<void> fetchMyTasks() async {
    if (_taskService == null || _authProvider?.currentUserId == null) return;
    _state = MyTasksState.loading;
    notifyListeners();

    try {
      _tasks = await _taskService!.getMyPendingTasks(userId: _authProvider!.currentUserId!);
      _state = MyTasksState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = MyTasksState.error;
    }
    notifyListeners();
  }
}