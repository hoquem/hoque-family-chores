// lib/presentation/providers/my_tasks_provider.dart
import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';

enum MyTasksState { initial, loading, loaded, error }

class MyTasksProvider with ChangeNotifier {
  final TaskServiceInterface _taskService;

  MyTasksProvider(this._taskService);

  MyTasksState _state = MyTasksState.initial;
  List<Task> _tasks = [];
  String _errorMessage = '';

  MyTasksState get state => _state;
  List<Task> get tasks => _tasks;
  String get errorMessage => _errorMessage;

  Future<void> fetchMyPendingTasks() async {
    _state = MyTasksState.loading;
    notifyListeners();

    try {
      // FOR NOW: Hardcode the logged-in user's ID for the mock service.
      // In a real app, this ID would come from your AuthProvider.
      const mockLoggedInUserId = 'fm_001';
      _tasks = await _taskService.getMyPendingTasks(mockLoggedInUserId);
      _state = MyTasksState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = MyTasksState.error;
    }
    notifyListeners();
  }
}