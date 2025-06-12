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
  final TaskServiceInterface _taskService;
  final AuthProvider _authProvider;
  StreamSubscription? _taskStreamSubscription;

  TaskSummary _summary = const TaskSummary();
  TaskSummaryState _state = TaskSummaryState.loading;
  String? _errorMessage;

  TaskSummary get summary => _summary;
  TaskSummaryState get state => _state;
  String? get errorMessage => _errorMessage;

  TaskSummaryProvider({
    required TaskServiceInterface taskService,
    required AuthProvider authProvider,
  }) : _taskService = taskService,
       _authProvider = authProvider {
    logger.d(
      "TaskSummaryProvider initialized with dependencies. Performing initial fetch...",
    );
    _fetchSummaryDebounced();
  }

  @override
  void dispose() {
    _taskStreamSubscription?.cancel();
    super.dispose();
  }

  void update(TaskServiceInterface taskService, AuthProvider authProvider) {
    if (!identical(_taskService, taskService) ||
        !identical(_authProvider, authProvider)) {
      logger.d(
        "TaskSummaryProvider dependencies updated. Attempting to fetch summary...",
      );
      _fetchSummaryDebounced();
    }
  }

  Timer? _fetchDebounceTimer;
  void _fetchSummaryDebounced() {
    _fetchDebounceTimer?.cancel();
    _fetchDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (_authProvider.currentUserProfile != null &&
          _authProvider.userFamilyId != null) {
        fetchTaskSummary(
          familyId: _authProvider.userFamilyId!,
          userId: _authProvider.currentUserProfile!.id,
        );
      } else {
        logger.w(
          "TaskSummaryProvider: Cannot fetch summary, user profile or family ID is null.",
        );
        _summary = const TaskSummary();
        _state = TaskSummaryState.loaded;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchTaskSummary({
    required String familyId,
    required String userId,
  }) async {
    logger.d(
      "TaskSummaryProvider: fetchTaskSummary called for user $userId in family $familyId",
    );

    // Cancel any existing subscription
    if (_taskStreamSubscription != null) {
      logger.d("TaskSummaryProvider: Cancelling existing stream subscription");
      await _taskStreamSubscription?.cancel();
      _taskStreamSubscription = null;
    }

    // Always allow fetching to proceed, but track if we're already loading
    final wasLoading = _state == TaskSummaryState.loading;
    if (wasLoading) {
      logger.d(
        "TaskSummaryProvider: Was already loading, but proceeding with new fetch",
      );
    }

    _state = TaskSummaryState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      logger.d("TaskSummaryProvider: Setting up task stream...");
      bool hasReceivedData = false;

      _taskStreamSubscription = _taskService
          .streamTasks(familyId: familyId)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: (sink) {
              logger.w("TaskSummaryProvider: Stream timeout after 5 seconds");
              if (!hasReceivedData) {
                logger.d(
                  "TaskSummaryProvider: No data received before timeout, setting empty summary",
                );
                _summary = const TaskSummary();
                _state = TaskSummaryState.loaded;
                _errorMessage = null;
                notifyListeners();
              }
              sink.close();
            },
          )
          .listen(
            (allTasks) {
              hasReceivedData = true;
              logger.d(
                "TaskSummaryProvider: Received ${allTasks.length} tasks from stream.",
              );

              // Log each task's status for debugging
              for (var task in allTasks) {
                logger.d(
                  "TaskSummaryProvider: Task ${task.id}: status=${task.status.name}, assigneeId=${task.assigneeId}, title=${task.title}",
                );
              }

              // If no tasks, set empty summary immediately
              if (allTasks.isEmpty) {
                logger.d(
                  "TaskSummaryProvider: No tasks found, setting empty summary.",
                );
                _summary = const TaskSummary();
                _state = TaskSummaryState.loaded;
                _errorMessage = null;
                notifyListeners();
                return;
              }

              final assignedToMe = allTasks.where(
                (task) => task.assigneeId == userId,
              );
              logger.d(
                "TaskSummaryProvider: Found ${assignedToMe.length} tasks assigned to user $userId",
              );

              try {
                _summary = TaskSummary(
                  totalTasks: allTasks.length,
                  completedTasks:
                      assignedToMe
                          .where((task) => task.status == TaskStatus.completed)
                          .length,
                  pendingTasks:
                      assignedToMe
                          .where(
                            (task) =>
                                task.status == TaskStatus.assigned ||
                                task.status == TaskStatus.pendingApproval ||
                                task.status == TaskStatus.needsRevision,
                          )
                          .length,
                  availableTasks:
                      allTasks
                          .where((task) => task.status == TaskStatus.available)
                          .length,
                  needsRevisionTasks:
                      assignedToMe
                          .where(
                            (task) => task.status == TaskStatus.needsRevision,
                          )
                          .length,
                  assignedTasks:
                      assignedToMe
                          .where((task) => task.status == TaskStatus.assigned)
                          .length,
                );
                logger.d(
                  "TaskSummaryProvider: Successfully created summary: $_summary",
                );
                _state = TaskSummaryState.loaded;
                _errorMessage = null;
                notifyListeners();
              } catch (e, s) {
                logger.e(
                  "TaskSummaryProvider: Error creating summary: $e",
                  error: e,
                  stackTrace: s,
                );
                _state = TaskSummaryState.error;
                _errorMessage = "Error creating summary: $e";
                notifyListeners();
              }
            },
            onError: (e, s) {
              logger.e(
                "TaskSummaryProvider: Error in task stream: $e",
                error: e,
                stackTrace: s,
              );
              _state = TaskSummaryState.error;
              _errorMessage = "Error fetching tasks: $e";
              notifyListeners();
            },
          );
    } catch (e, s) {
      logger.e(
        "TaskSummaryProvider: Error setting up task stream: $e",
        error: e,
        stackTrace: s,
      );
      _state = TaskSummaryState.error;
      _errorMessage = "Error setting up task stream: $e";
      notifyListeners();
    }
  }

  Future<void> updateTaskStatus({
    required String familyId,
    required String taskId,
    required TaskStatus newStatus,
  }) async {
    logger.i(
      "TaskSummaryProvider: Updating status for task $taskId to $newStatus.",
    );
    try {
      await _taskService.updateTaskStatus(
        familyId: familyId,
        taskId: taskId,
        newStatus: newStatus,
      );
      logger.d(
        "Task $taskId status updated successfully by TaskSummaryProvider.",
      );
    } catch (e, s) {
      _errorMessage = 'Failed to update task status: $e';
      notifyListeners();
      logger.e(
        "Error updating task status $taskId from TaskSummaryProvider: $e",
        error: e,
        stackTrace: s,
      );
    }
  }
}
