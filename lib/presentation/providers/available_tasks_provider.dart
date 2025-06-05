// lib/presentation/providers/available_tasks_provider.dart
import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';

enum AvailableTasksState { initial, loading, loaded, error }

class AvailableTasksProvider with ChangeNotifier {
  final TaskServiceInterface _taskService;

  AvailableTasksProvider(this._taskService);

  AvailableTasksState _state = AvailableTasksState.initial;
  List<Task> _tasks = [];
  String _errorMessage = '';
  bool _isAssigning = false;

  AvailableTasksState get state => _state;
  List<Task> get tasks => _tasks;
  String get errorMessage => _errorMessage;
  bool get isAssigning => _isAssigning;

  Future<void> fetchAvailableTasks() async {
    _state = AvailableTasksState.loading;
    notifyListeners();

    try {
      _tasks = await _taskService.getUnassignedTasks();
      _state = AvailableTasksState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = AvailableTasksState.error;
    }
    notifyListeners();
  }

  Future<bool> selectTask(String taskId) async {
    _isAssigning = true;
    notifyListeners();

    try {
      // FOR NOW: Hardcode the logged-in user's ID.
      // In a real app, this would come from your AuthProvider.
      const mockLoggedInUserId = 'fm_001';
      await _taskService.assignTask(taskId: taskId, userId: mockLoggedInUserId);

      // Refresh the list of available tasks after assigning one
      await fetchAvailableTasks();
      _isAssigning = false;
      notifyListeners();
      return true; // Indicate success
    } catch (e) {
      _errorMessage = "Failed to assign task: $e";
      _isAssigning = false;
      notifyListeners();
      return false; // Indicate failure
    }
  }
}