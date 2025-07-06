import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/domain/usecases/task/stream_tasks_by_assignee_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/task/get_tasks_usecase.dart';
import 'package:hoque_family_chores/utils/logger.dart';

part 'my_tasks_notifier.g.dart';

/// Manages the list of tasks assigned to the current user.
/// 
/// This notifier streams tasks assigned to a specific user within a family
/// and provides methods for task management.
/// 
/// Example:
/// ```dart
/// final myTasksAsync = ref.watch(myTasksNotifierProvider(familyId, userId));
/// final notifier = ref.read(myTasksNotifierProvider(familyId, userId).notifier);
/// await notifier.refresh();
/// ```
@riverpod
class MyTasksNotifier extends _$MyTasksNotifier {
  final _logger = AppLogger();

  @override
  Future<List<Task>> build(FamilyId familyId, UserId userId) async {
    _logger.d('MyTasksNotifier: Building for family $familyId, user $userId');
    
    try {
      final streamTasksByAssigneeUseCase = ref.watch(streamTasksByAssigneeUseCaseProvider);
      final tasksStream = streamTasksByAssigneeUseCase.call(
        familyId: familyId,
        assigneeId: userId,
      );
      
      // Listen to the stream and update state
      await for (final result in tasksStream) {
        result.fold(
          (failure) => throw Exception(failure.message),
          (tasks) {
            _logger.d('MyTasksNotifier: Received ${tasks.length} tasks for user $userId');
            state = AsyncValue.data(tasks);
          },
        );
      }
      
      // This should never be reached as the stream is continuous
      throw Exception('Task stream ended unexpectedly');
    } catch (e) {
      _logger.e('MyTasksNotifier: Error loading my tasks', error: e);
      throw Exception('Failed to load my tasks: $e');
    }
  }

  /// Refreshes the task list.
  Future<void> refresh() async {
    _logger.d('MyTasksNotifier: Refreshing my tasks');
    ref.invalidateSelf();
  }

  /// Gets the current list of tasks.
  List<Task> get tasks => state.value ?? [];

  /// Gets the current loading state.
  bool get isLoading => state.isLoading;

  /// Gets the current error message.
  String? get errorMessage => state.hasError ? state.error.toString() : null;

  /// Gets the current state status.
  MyTasksState get status {
    if (state.isLoading) return MyTasksState.loading;
    if (state.hasError) return MyTasksState.error;
    return MyTasksState.loaded;
  }

  /// Gets tasks filtered by status.
  List<Task> getTasksByStatus(TaskStatus status) {
    return tasks.where((task) => task.status == status).toList();
  }

  /// Gets completed tasks.
  List<Task> get completedTasks => getTasksByStatus(TaskStatus.completed);

  /// Gets pending tasks.
  List<Task> get pendingTasks => getTasksByStatus(TaskStatus.pending);

  /// Gets assigned tasks.
  List<Task> get assignedTasks => getTasksByStatus(TaskStatus.assigned);

  /// Gets overdue tasks.
  List<Task> get overdueTasks {
    final now = DateTime.now();
    return tasks.where((task) => 
      task.dueDate != null && 
      now.isAfter(task.dueDate!) &&
      task.status != TaskStatus.completed
    ).toList();
  }

  /// Gets tasks due today.
  List<Task> get tasksDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return tasks.where((task) => 
      task.dueDate != null && 
      task.dueDate!.isAfter(today) &&
      task.dueDate!.isBefore(tomorrow) &&
      task.status != TaskStatus.completed
    ).toList();
  }

  /// Gets tasks due this week.
  List<Task> get tasksDueThisWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(const Duration(days: 7));
    
    return tasks.where((task) => 
      task.dueDate != null && 
      task.dueDate!.isAfter(today) &&
      task.dueDate!.isBefore(endOfWeek) &&
      task.status != TaskStatus.completed
    ).toList();
  }
}

/// Enum for my tasks state.
enum MyTasksState { initial, loading, loaded, error } 