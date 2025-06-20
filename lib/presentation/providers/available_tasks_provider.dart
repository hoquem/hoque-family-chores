import 'package:flutter/material.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/enums.dart'; // Needed for AvailableTasksState and TaskStatus
import 'package:hoque_family_chores/services/task_service_interface.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'dart:async';

// Define AvailableTasksState enum (if not already in enums.dart)
// (Note: This enum is now expected to be in enums.dart for consistency)
// enum AvailableTasksState { loading, loaded, error, claiming }

class AvailableTasksProvider with ChangeNotifier {
  final TaskServiceInterface _taskService;
  final AuthProvider _authProvider;
  StreamSubscription? _taskStreamSubscription;

  List<Task> _availableTasks = [];
  AvailableTasksState _state = AvailableTasksState.loading;
  String? _errorMessage;
  bool _isClaiming = false;
  bool _hasReceivedData = false;

  List<Task> get availableTasks => _availableTasks;
  AvailableTasksState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == AvailableTasksState.loading;
  bool get isClaiming => _isClaiming;

  AvailableTasksProvider({
    required TaskServiceInterface taskService,
    required AuthProvider authProvider,
  }) : _taskService = taskService,
       _authProvider = authProvider {
    logger.d(
      "AvailableTasksProvider initialized with dependencies. Performing initial fetch...",
    );
    _fetchAvailableTasksDebounced();
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
        "AvailableTasksProvider dependencies updated. Attempting to fetch available tasks...",
      );
      _fetchAvailableTasksDebounced();
    }
  }

  Timer? _fetchDebounceTimer;
  void _fetchAvailableTasksDebounced() {
    _fetchDebounceTimer?.cancel();
    _fetchDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (_authProvider.currentUserProfile != null &&
          _authProvider.userFamilyId != null) {
        fetchAvailableTasks(
          familyId: _authProvider.userFamilyId!,
          userId: _authProvider.currentUserProfile!.id,
        );
      } else {
        logger.w(
          "AvailableTasksProvider: Cannot fetch available tasks, user profile or family ID is null.",
        );
        _availableTasks = [];
        _state = AvailableTasksState.loaded;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchAvailableTasks({
    required String familyId,
    required String userId,
  }) async {
    logger.d(
      "AvailableTasksProvider: Starting to fetch available tasks for family $familyId",
    );

    // Cancel any existing subscription
    await _taskStreamSubscription?.cancel();
    _taskStreamSubscription = null;

    _state = AvailableTasksState.loading;
    _errorMessage = null;
    _hasReceivedData = false;
    notifyListeners();

    try {
      _taskStreamSubscription = _taskService
          .streamAvailableTasks(familyId: familyId)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: (sink) {
              logger.w(
                "AvailableTasksProvider: Stream timeout after 5 seconds",
              );
              if (!_hasReceivedData) {
                logger.d(
                  "AvailableTasksProvider: No data received before timeout, clearing tasks",
                );
                _availableTasks = [];
                _state = AvailableTasksState.loaded;
                _errorMessage = null;
                notifyListeners();
              } else {
                logger.d(
                  "AvailableTasksProvider: Timeout occurred but we have existing data, keeping current tasks",
                );
              }
              sink.close();
            },
          )
          .listen(
            (tasks) {
              _hasReceivedData = true;
              logger.d(
                "AvailableTasksProvider: Received ${tasks.length} available tasks",
              );

              // Log details of each task for debugging
              for (var task in tasks) {
                logger.d(
                  "AvailableTasksProvider: Task ${task.id}: status=${task.status.name}, title=${task.title}, points=${task.points}",
                );
              }

              _availableTasks = tasks;
              _state = AvailableTasksState.loaded;
              _errorMessage = null;
              notifyListeners();
            },
            onError: (e, s) {
              logger.e(
                "AvailableTasksProvider: Error in available tasks stream: $e",
                error: e,
                stackTrace: s,
              );
              _state = AvailableTasksState.error;
              _errorMessage = "Error fetching available tasks: $e";
              notifyListeners();
            },
          );
    } catch (e, s) {
      logger.e(
        "AvailableTasksProvider: Error setting up available tasks stream: $e",
        error: e,
        stackTrace: s,
      );
      _state = AvailableTasksState.error;
      _errorMessage = "Error setting up available tasks stream: $e";
      notifyListeners();
    }
  }

  Future<void> claimTask(String taskId) async {
    final currentUserId = _authProvider.currentUserId;
    final userFamilyId = _authProvider.userFamilyId;

    if (currentUserId == null || userFamilyId == null) {
      logger.w(
        "AvailableTasksProvider: Cannot claim task - missing user ID or family ID",
      );
      _errorMessage =
          "Cannot claim task: user not authenticated or family not set.";
      notifyListeners();
      return;
    }

    logger.i(
      "AvailableTasksProvider: Attempting to claim task $taskId by user $currentUserId in family $userFamilyId",
    );

    _isClaiming = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskService.claimTask(
        familyId: userFamilyId,
        taskId: taskId,
        userId: currentUserId,
      );
      logger.d("AvailableTasksProvider: Task $taskId claimed successfully");
    } catch (e, s) {
      logger.e(
        "AvailableTasksProvider: Error claiming task $taskId: $e",
        error: e,
        stackTrace: s,
      );
      _errorMessage = 'Failed to claim task: $e';
      notifyListeners();
    } finally {
      _isClaiming = false;
      notifyListeners();
    }
  }
}
