import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'available_tasks_notifier.g.dart';

/// Manages the list of available tasks that can be claimed by users.
/// 
/// This notifier streams available tasks within a family and provides
/// methods for claiming tasks.
/// 
/// Example:
/// ```dart
/// final availableTasksAsync = ref.watch(availableTasksNotifierProvider(familyId));
/// final notifier = ref.read(availableTasksNotifierProvider(familyId).notifier);
/// await notifier.claimTask(taskId, userId);
/// ```
@riverpod
class AvailableTasksNotifier extends _$AvailableTasksNotifier {
  final _logger = AppLogger();

  @override
  Future<List<Task>> build(FamilyId familyId) async {
    _logger.d('AvailableTasksNotifier: Building for family $familyId');
    
    try {
      final getTasksUseCase = ref.watch(getTasksUseCaseProvider);
      final result = await getTasksUseCase.call(familyId: familyId);
      
      return result.fold(
        (failure) => throw Exception(failure.message),
        (tasks) {
          // Filter to only available tasks
          final availableTasks = tasks.where((task) => 
            task.status == TaskStatus.available
          ).toList();
          
          _logger.d('AvailableTasksNotifier: Loaded ${availableTasks.length} available tasks');
          return availableTasks;
        },
      );
    } catch (e) {
      _logger.e('AvailableTasksNotifier: Error loading available tasks', error: e);
      throw Exception('Failed to load available tasks: $e');
    }
  }

  /// Claims a task for the specified user.
  Future<void> claimTask(String taskId, UserId userId, FamilyId familyId) async {
    _logger.d('AvailableTasksNotifier: Claiming task $taskId for user $userId');
    
    try {
      final claimTaskUseCase = ref.read(claimTaskUseCaseProvider);
      final result = await claimTaskUseCase.call(
        taskId: TaskId(taskId), 
        userId: userId,
        familyId: familyId,
      );
      
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) {
          _logger.d('AvailableTasksNotifier: Task claimed successfully');
          // The stream will automatically update the list
        },
      );
    } catch (e) {
      _logger.e('AvailableTasksNotifier: Error claiming task', error: e);
      throw Exception('Failed to claim task: $e');
    }
  }

  /// Refreshes the available tasks list.
  Future<void> refresh() async {
    _logger.d('AvailableTasksNotifier: Refreshing available tasks');
    ref.invalidateSelf();
  }

  /// Gets the current list of available tasks.
  List<Task> get availableTasks => state.value ?? [];

  /// Gets the current loading state.
  bool get isLoading => state.isLoading;

  /// Gets the current error message.
  String? get errorMessage => state.hasError ? state.error.toString() : null;

  /// Gets the current state status.
  AvailableTasksState get status {
    if (state.isLoading) return AvailableTasksState.loading;
    if (state.hasError) return AvailableTasksState.error;
    return AvailableTasksState.loaded;
  }

  /// Gets tasks due soon (within 24 hours).
  List<Task> get tasksDueSoon {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    return availableTasks.where((task) => 
      task.dueDate.isBefore(tomorrow) &&
      task.dueDate.isAfter(now)
    ).toList();
  }

  /// Gets overdue tasks.
  List<Task> get overdueTasks {
    final now = DateTime.now();
    
    return availableTasks.where((task) => 
      now.isAfter(task.dueDate)
    ).toList();
  }

  /// Gets tasks with no due date.
  List<Task> get tasksWithNoDueDate {
    // Since all tasks have dueDate in the domain entity, this would be empty
    return [];
  }

  /// Gets tasks sorted by due date (earliest first).
  List<Task> get tasksSortedByDueDate {
    final sortedTasks = List<Task>.from(availableTasks);
    sortedTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return sortedTasks;
  }

  /// Gets tasks sorted by difficulty (easy to challenging).
  List<Task> get tasksSortedByDifficulty {
    final sortedTasks = List<Task>.from(availableTasks);
    sortedTasks.sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));
    return sortedTasks;
  }
} 