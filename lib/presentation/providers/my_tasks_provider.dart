import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';
import 'package:hoque_family_chores/utils/exceptions.dart';

enum MyTasksState { initial, loading, loaded, error }

class MyTasksProvider with ChangeNotifier {
  TaskServiceInterface? _taskService;
  AuthProvider? _authProvider;
  StreamSubscription? _tasksSubscription;

  MyTasksState _state = MyTasksState.initial;
  String? _errorMessage;
  List<Task> _tasks = [];

  MyTasksState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Task> get tasks => _tasks;

  void update(TaskServiceInterface taskService, AuthProvider authProvider) {
    if (_taskService != taskService || _authProvider != authProvider) {
      _taskService = taskService;
      _authProvider = authProvider;
      _listenToMyTasks();
    }
  }

  void _listenToMyTasks() {
    if (_taskService == null || _authProvider?.currentUserId == null || _authProvider?.userFamilyId == null) return;

    _state = MyTasksState.loading;
    notifyListeners();
    
    _tasksSubscription?.cancel();
    _tasksSubscription = _taskService!
        // FIX: The streamMyTasks method now requires both userId and familyId.
        .streamMyTasks(
          userId: _authProvider!.currentUserId!,
          familyId: _authProvider!.userFamilyId!,
        )
        .listen((tasks) {
      _tasks = tasks;
      _state = MyTasksState.loaded;
      notifyListeners();
    }, onError: (e, s) {
      logger.e("Error listening to my tasks", error: e, stackTrace: s);
      _errorMessage = e is AppException ? e.message : "An unknown error occurred.";
      _state = MyTasksState.error;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}