// lib/presentation/providers/task_list_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';

enum TaskFilterType { all, myTasks, available, completed }

class TaskListProvider with ChangeNotifier {
  final TaskServiceInterface _taskService;
  final String _currentUserId; // In a real app, get this from an AuthProvider

  TaskListProvider(this._taskService, this._currentUserId) {
    // Initialize with the 'all' filter
    setFilter(TaskFilterType.all);
  }

  TaskFilterType _currentFilter = TaskFilterType.all;
  Stream<List<Task>> _tasksStream = const Stream.empty();

  TaskFilterType get currentFilter => _currentFilter;
  Stream<List<Task>> get tasksStream => _tasksStream;

  void setFilter(TaskFilterType filter) {
    _currentFilter = filter;
    _updateStream();
    notifyListeners();
  }

  void _updateStream() {
    switch (_currentFilter) {
      case TaskFilterType.all:
        _tasksStream = _taskService.streamAllTasks();
        break;
      case TaskFilterType.myTasks:
        _tasksStream = _taskService.streamMyTasks(_currentUserId);
        break;
      case TaskFilterType.available:
        _tasksStream = _taskService.streamAvailableTasks();
        break;
      case TaskFilterType.completed:
        _tasksStream = _taskService.streamCompletedTasks();
        break;
    }
  }
}