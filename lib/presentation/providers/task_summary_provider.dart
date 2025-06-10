import 'package:flutter/material.dart';
import 'package:hoque_family_chores/models/enums.dart'; // <--- Ensure this is imported for TaskStatus AND TaskSummaryState
import 'package:hoque_family_chores/services/task_service_interface.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'dart:async';

// REMOVED LOCAL DEFINITION OF TaskSummaryState, as it is now defined in enums.dart
// enum TaskSummaryState { loading, loaded, error } // <--- THIS LINE IS REMOVED

class TaskSummary {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int availableTasks;
  final int needsRevisionTasks;
  final int assignedTasks;

  const TaskSummary({
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.pendingTasks = 0,
    this.availableTasks = 0,
    this.needsRevisionTasks = 0,
    this.assignedTasks = 0,
  });

  int get totalCompleted => completedTasks;
  int get waitingOverall => pendingTasks + needsRevisionTasks;
  int get waitingAssigned => assignedTasks + needsRevisionTasks;
}

class TaskSummaryProvider with ChangeNotifier {
  late TaskServiceInterface _taskService;
  late AuthProvider _authProvider;

  TaskSummary _summary = const TaskSummary();
  TaskSummaryState _state = TaskSummaryState.loading; // Uses enum from enums.dart
  String? _errorMessage;

  TaskSummary get summary => _summary;
  TaskSummaryState get state => _state;
  String? get errorMessage => _errorMessage;

  TaskSummaryProvider();

  void update(TaskServiceInterface taskService, AuthProvider authProvider) {
    if (!identical(_taskService, taskService) || !identical(_authProvider, authProvider)) {
      _taskService = taskService;
      _authProvider = authProvider;
      logger.d("TaskSummaryProvider dependencies updated. Attempting to fetch summary...");
      _fetchSummaryDebounced();
    }
  }

  Timer? _fetchDebounceTimer;
  void _fetchSummaryDebounced() {
    _fetchDebounceTimer?.cancel();
    _fetchDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (_authProvider.currentUserProfile != null && _authProvider.userFamilyId != null) {
        fetchTaskSummary(
          familyId: _authProvider.userFamilyId!,
          userId: _authProvider.currentUserProfile!.id,
        );
      } else {
        logger.w("TaskSummaryProvider: Cannot fetch summary, user profile or family ID is null.");
        _summary = const TaskSummary();
        _state = TaskSummaryState.loaded;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchTaskSummary({required String familyId, required String userId}) async {
    if (_state == TaskSummaryState.loading) return;

    _state = TaskSummaryState.loading;
    _errorMessage = null;
    notifyListeners();
    logger.i("Fetching task summary for user $userId in family $familyId...");

    try {
      _taskService.streamTasks(familyId: familyId).listen(
        (allTasks) {
          final assignedToMe = allTasks.where((task) => task.assigneeId == userId);

          _summary = TaskSummary(
            totalTasks: allTasks.length,
            completedTasks: assignedToMe.where((task) => task.status == TaskStatus.completed).length,
            pendingTasks: assignedToMe.where((task) =>
                task.status == TaskStatus.assigned ||
                task.status == TaskStatus.pendingApproval ||
                task.status == TaskStatus.needsRevision).length,
            availableTasks: allTasks.where((task) => task.status == TaskStatus.available).length,
            needsRevisionTasks: assignedToMe.where((task) => task.status == TaskStatus.needsRevision).length,
            assignedTasks: assignedToMe.where((task) => task.status == TaskStatus.assigned).length,
          );
          _state = TaskSummaryState.loaded;
          _errorMessage = null;
          notifyListeners();
          logger.d("Task summary updated: $_summary");
        },
        onError: (e, s) {
          _errorMessage = 'Failed to load task summary: $e';
          _state = TaskSummaryState.error;
          notifyListeners();
          logger.e("Error fetching task summary: $e", error: e, stackTrace: s);
        },
        onDone: () {
          logger.i("Task summary stream completed (should not happen for continuous streams).");
        },
      );
    } catch (e, s) {
      _errorMessage = 'An unexpected error occurred while setting up task summary stream: $e';
      _state = TaskSummaryState.error;
      notifyListeners();
      logger.e("Unexpected error setting up task summary stream: $e", error: e, stackTrace: s);
    }
  }

  Future<void> updateTaskStatus({
    required String familyId,
    required String taskId,
    required TaskStatus newStatus,
  }) async {
    logger.i("TaskSummaryProvider: Updating status for task $taskId to $newStatus.");
    try {
      await _taskService.updateTaskStatus(
        familyId: familyId,
        taskId: taskId,
        newStatus: newStatus,
      );
      logger.d("Task $taskId status updated successfully by TaskSummaryProvider.");
    } catch (e, s) {
      _errorMessage = 'Failed to update task status: $e';
      notifyListeners();
      logger.e("Error updating task status $taskId from TaskSummaryProvider: $e", error: e, stackTrace: s);
    }
  }

  void dispose() {
    super.dispose();
  }
}