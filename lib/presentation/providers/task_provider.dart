import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/services/interfaces/task_service_interface.dart';
import 'package:hoque_family_chores/utils/logger.dart';

enum TaskState { initial, loading, loaded, error }

class TaskProvider extends ChangeNotifier {
  final TaskServiceInterface _taskService;
  final _logger = AppLogger();

  TaskState _state = TaskState.initial;
  String? _errorMessage;
  List<Task> _quickTasks = [];

  TaskProvider(this._taskService);

  TaskState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Task> get quickTasks => _quickTasks;

  Future<void> fetchQuickTasks({
    required String familyId,
    required String userId,
  }) async {
    _logger.d('TaskProvider: Fetching quick tasks');
    _state = TaskState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get available tasks for the family
      _quickTasks = await _taskService.getTasksForFamily(familyId: familyId);
      // Filter to only show unassigned tasks as quick tasks
      _quickTasks = _quickTasks.where((task) => task.assignedTo == null).toList();
      _state = TaskState.loaded;
      _logger.d('TaskProvider: Fetched ${_quickTasks.length} quick tasks');
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _state = TaskState.error;
      _logger.e(
        'TaskProvider: Error fetching quick tasks',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> assignTask({
    required String taskId,
    required String userId,
    required String familyId,
  }) async {
    _logger.d('TaskProvider: Assigning task $taskId to user $userId');
    try {
      await _taskService.assignTask(taskId: taskId, userId: userId);
      _logger.d('TaskProvider: Task assigned successfully');
      // Refresh quick tasks after assignment
      await fetchQuickTasks(
        familyId: familyId,
        userId: userId,
      );
    } catch (e, stackTrace) {
      _logger.e(
        'TaskProvider: Error assigning task',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
