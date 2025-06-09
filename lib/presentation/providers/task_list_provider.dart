// lib/presentation/providers/task_list_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart'; // Import AuthProvider
import 'package:hoque_family_chores/services/task_service_interface.dart';

enum TaskFilterType { all, myTasks, available, completed }

class TaskListProvider with ChangeNotifier {
  // Dependencies will be injected by a ProxyProvider
  TaskServiceInterface? _taskService;
  AuthProvider? _authProvider;

  TaskListProvider() {
    // Initial filter can be set here or when dependencies are first provided.
    _currentFilter = TaskFilterType.all;
  }

  TaskFilterType _currentFilter = TaskFilterType.all;
  Stream<List<Task>> _tasksStream = const Stream.empty();

  TaskFilterType get currentFilter => _currentFilter;
  Stream<List<Task>> get tasksStream => _tasksStream;

  // Method for ProxyProvider to update dependencies
  void update(TaskServiceInterface taskService, AuthProvider authProvider) {
    _taskService = taskService;
    _authProvider = authProvider;
    // When dependencies are first provided, initialize the stream
    _updateStream();
  }

  void setFilter(TaskFilterType filter) {
    _currentFilter = filter;
    _updateStream();
    notifyListeners(); // Notify UI to rebuild and use the new stream
  }

  void _updateStream() {
    if (_taskService == null || _authProvider == null) {
      _tasksStream = const Stream.empty();
      return;
    }

    // You need a way to get the current user's family ID.
    // This should come from the AuthProvider after the user profile is loaded.
    final familyId = _authProvider!.userFamilyId; 
    final userId = _authProvider!.currentUserId;

    if (familyId == null || userId == null) {
      _tasksStream = const Stream.empty();
      return;
    }
    
    switch (_currentFilter) {
      case TaskFilterType.all:
        _tasksStream = _taskService!.streamAllTasks(familyId: familyId);
        break;
      case TaskFilterType.myTasks:
        _tasksStream = _taskService!.streamMyTasks(userId: userId);
        break;
      case TaskFilterType.available:
        _tasksStream = _taskService!.streamAvailableTasks(familyId: familyId);
        break;
      case TaskFilterType.completed:
        _tasksStream = _taskService!.streamCompletedTasks(familyId: familyId);
        break;
    }
  }
}