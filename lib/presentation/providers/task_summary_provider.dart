import 'package:flutter/material.dart';
import 'package:hoque_family_chores/services/interfaces/task_service_interface.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'dart:async';

enum TaskSummaryState { loading, loaded, error }

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

  TaskSummaryState _state = TaskSummaryState.loading;
  TaskSummary? _summary;
  String? _errorMessage;
  StreamSubscription<List<Task>>? _taskSummarySubscription;

  TaskSummary get summary => _summary ?? const TaskSummary();
  TaskSummaryState get state => _state;
  String? get errorMessage => _errorMessage;

  TaskSummaryProvider({
    required TaskServiceInterface taskService,
    required AuthProvider authProvider,
  }) : _taskService = taskService,
       _authProvider = authProvider {
    logger.i("[TaskSummaryProvider] Initialized with dependencies. Waiting for authentication...");
    // Listen to auth provider changes
    _authProvider.addListener(_onAuthChanged);
    // Don't fetch immediately - wait for authentication
  }

  @override
  void dispose() {
    logger.i("[TaskSummaryProvider] Disposing provider...");
    _taskSummarySubscription?.cancel();
    _fetchDebounceTimer?.cancel();
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    logger.d("[TaskSummaryProvider] Auth state changed, checking if we should fetch data");
    _fetchSummaryDebounced();
  }

  Timer? _fetchDebounceTimer;
  void _fetchSummaryDebounced() {
    _fetchDebounceTimer?.cancel();
    _fetchDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      final userProfile = _authProvider.currentUserProfile;
      final familyId = _authProvider.userFamilyId;
      
      if (userProfile != null && familyId != null) {
        logger.d("[TaskSummaryProvider] Debounced fetch triggered for user ${userProfile.member.id} in family $familyId");
        _setupTaskStream(
          familyId: familyId,
          userId: userProfile.member.id,
        );
      } else {
        logger.w("[TaskSummaryProvider] Cannot fetch summary, user profile or family ID is null. UserProfile: $userProfile, FamilyId: $familyId");
        _summary = const TaskSummary();
        _state = TaskSummaryState.loaded;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  /// Public method to refresh the summary manually
  Future<void> refreshSummary({required String familyId, required String userId}) async {
    logger.i("[TaskSummaryProvider] Manual refresh requested for user $userId in family $familyId");
    await _setupTaskStream(familyId: familyId, userId: userId);
  }

  Future<void> _setupTaskStream({
    required String familyId,
    required String userId,
  }) async {
    logger.i("[TaskSummaryProvider] Setting up task stream for user $userId in family $familyId");

    // Cancel any existing subscription
    if (_taskSummarySubscription != null) {
      logger.d("[TaskSummaryProvider] Cancelling existing stream subscription");
      await _taskSummarySubscription?.cancel();
      _taskSummarySubscription = null;
    }

    try {
      _setState(TaskSummaryState.loading);
      bool hasReceivedData = false;

      logger.d("[TaskSummaryProvider] Starting task stream with timeout...");
      _taskSummarySubscription = _taskService
          .streamTasks(familyId: familyId)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: (sink) {
              logger.w("[TaskSummaryProvider] Stream timeout after 15 seconds");
              sink.close();
              // Set empty summary instead of staying in loading state
              if (!hasReceivedData) {
                logger.d("[TaskSummaryProvider] Setting empty summary due to timeout");
                _summary = const TaskSummary();
                _setState(TaskSummaryState.loaded);
                // Try to fetch tasks using regular method as fallback
                logger.i("[TaskSummaryProvider] Triggering fallback fetch after timeout");
                _fetchTasksAsFallback(familyId: familyId, userId: userId);
              } else {
                logger.d("[TaskSummaryProvider] Timeout occurred but we already received data, not triggering fallback");
              }
            },
          )
          .listen(
        (tasks) {
          logger.d("[TaskSummaryProvider] Received ${tasks.length} tasks from stream");

          if (!hasReceivedData) {
            hasReceivedData = true;
            logger.d("[TaskSummaryProvider] First data received from stream");
          }

          // Calculate summary from tasks
          final totalTasks = tasks.length;
          final totalCompleted = tasks
              .where((task) => task.status == TaskStatus.completed)
              .length;
          final waitingOverall = tasks
              .where((task) => task.status == TaskStatus.assigned)
              .length;
          final waitingAssigned = tasks
              .where((task) =>
                  task.status == TaskStatus.assigned &&
                  task.assignedTo?.id == userId)
              .length;
          final availableTasks = tasks
              .where((task) => task.status == TaskStatus.available)
              .length;
          final needsRevisionTasks = tasks
              .where((task) => task.status == TaskStatus.needsRevision)
              .length;

          final newSummary = TaskSummary(
            totalTasks: totalTasks,
            completedTasks: totalCompleted,
            pendingTasks: waitingOverall,
            availableTasks: availableTasks,
            needsRevisionTasks: needsRevisionTasks,
            assignedTasks: waitingAssigned,
          );

          logger.d("[TaskSummaryProvider] Calculated new summary: $newSummary");

          _summary = newSummary;
          _setState(TaskSummaryState.loaded);
        },
        onError: (error, stackTrace) {
          logger.e("[TaskSummaryProvider] Error in task stream: $error", error: error, stackTrace: stackTrace);
          
          // Handle permission denied errors gracefully
          if (error.toString().contains('permission-denied') || 
              error.toString().contains('PERMISSION_DENIED')) {
            logger.w("[TaskSummaryProvider] Permission denied - setting empty summary");
            _summary = const TaskSummary();
            _setState(TaskSummaryState.loaded);
          } else {
            _errorMessage = "Failed to load tasks: $error";
            _setState(TaskSummaryState.error);
          }
        },
        onDone: () {
          logger.d("[TaskSummaryProvider] Task stream completed");
          // If we haven't received any data and the stream is done, set empty summary
          if (!hasReceivedData) {
            logger.d("[TaskSummaryProvider] Stream completed without data - setting empty summary");
            _summary = const TaskSummary();
            _setState(TaskSummaryState.loaded);
          }
        },
      );

      logger.d("[TaskSummaryProvider] Task stream subscription set up successfully");
    } catch (e, s) {
      logger.e("[TaskSummaryProvider] Failed to set up task stream: $e", error: e, stackTrace: s);
      
      // Handle permission errors gracefully
      if (e.toString().contains('permission-denied') || 
          e.toString().contains('PERMISSION_DENIED')) {
        logger.w("[TaskSummaryProvider] Permission denied during setup - setting empty summary");
        _summary = const TaskSummary();
        _setState(TaskSummaryState.loaded);
      } else {
        _errorMessage = "Failed to set up task stream: $e";
        _setState(TaskSummaryState.error);
      }
    }
  }

  void _setState(TaskSummaryState newState) {
    logger.d("[TaskSummaryProvider] State changing from $_state to $newState");
    _state = newState;
    notifyListeners();
  }

  /// Fallback method to fetch tasks using regular method when stream times out
  Future<void> _fetchTasksAsFallback({
    required String familyId,
    required String userId,
  }) async {
    logger.i("[TaskSummaryProvider] Attempting fallback fetch for user $userId in family $familyId");
    try {
      logger.d("[TaskSummaryProvider] Calling _taskService.getTasksForFamily...");
      final tasks = await _taskService.getTasksForFamily(familyId: familyId);
      logger.d("[TaskSummaryProvider] Fallback fetch successful, got ${tasks.length} tasks");
      
      if (tasks.isNotEmpty) {
        logger.d("[TaskSummaryProvider] Processing ${tasks.length} tasks from fallback fetch");
        // Calculate summary from tasks
        final totalTasks = tasks.length;
        final totalCompleted = tasks
            .where((task) => task.status == TaskStatus.completed)
            .length;
        final waitingOverall = tasks
            .where((task) => task.status == TaskStatus.assigned)
            .length;
        final waitingAssigned = tasks
            .where((task) =>
                task.status == TaskStatus.assigned &&
                task.assignedTo?.id == userId)
            .length;
        final availableTasks = tasks
            .where((task) => task.status == TaskStatus.available)
            .length;
        final needsRevisionTasks = tasks
            .where((task) => task.status == TaskStatus.needsRevision)
            .length;

        final newSummary = TaskSummary(
          totalTasks: totalTasks,
          completedTasks: totalCompleted,
          pendingTasks: waitingOverall,
          availableTasks: availableTasks,
          needsRevisionTasks: needsRevisionTasks,
          assignedTasks: waitingAssigned,
        );

        logger.d("[TaskSummaryProvider] Updated summary from fallback: $newSummary");
        _summary = newSummary;
        _setState(TaskSummaryState.loaded);
        logger.i("[TaskSummaryProvider] Successfully updated summary from fallback fetch");
      } else {
        logger.w("[TaskSummaryProvider] Fallback fetch returned empty task list");
      }
    } catch (e, s) {
      logger.e("[TaskSummaryProvider] Fallback fetch failed: $e", error: e, stackTrace: s);
    }
  }

  Future<void> updateTaskStatus({
    required String taskId,
    required TaskStatus newStatus,
  }) async {
    logger.i("[TaskSummaryProvider] Updating status for task $taskId to $newStatus");
    try {
      await _taskService.updateTaskStatus(taskId: taskId, status: newStatus);
      logger.d("[TaskSummaryProvider] Task $taskId status updated successfully");
    } catch (e, s) {
      _errorMessage = 'Failed to update task status: $e';
      logger.e("[TaskSummaryProvider] Error updating task status $taskId: $e", error: e, stackTrace: s);
      notifyListeners();
    }
  }
}
