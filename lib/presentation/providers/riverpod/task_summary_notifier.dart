import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/task_summary.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/domain/usecases/task/stream_tasks_usecase.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'task_summary_notifier.g.dart';
part 'task_summary_notifier.freezed.dart';

/// Task summary state for the application.
@freezed
abstract class TaskSummaryState with _$TaskSummaryState {
  const factory TaskSummaryState({
    @Default(TaskSummaryStatus.loading) TaskSummaryStatus status,
    TaskSummary? summary,
    String? errorMessage,
    @Default(false) bool isLoading,
  }) = _TaskSummaryState;
}

/// Task summary status enum
enum TaskSummaryStatus {
  loading,
  loaded,
  error,
}

/// Manages task summary data for a family.
/// 
/// This notifier streams tasks and computes summary statistics
/// including completed tasks, pending tasks, and points earned.
/// 
/// Example:
/// ```dart
/// final summaryAsync = ref.watch(taskSummaryNotifierProvider(familyId));
/// final notifier = ref.read(taskSummaryNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
@riverpod
class TaskSummaryNotifier extends _$TaskSummaryNotifier {
  final _logger = AppLogger();

  @override
  Future<TaskSummary> build(FamilyId familyId) async {
    _logger.d('TaskSummaryNotifier: Building for family $familyId');
    
    try {
      final streamTasksUseCase = ref.watch(streamTasksUseCaseProvider);
      final tasksStream = streamTasksUseCase.call(familyId: familyId);
      
      // Listen to the stream and compute summary
      await for (final result in tasksStream) {
        result.fold(
          (failure) => throw Exception(failure.message),
          (tasks) {
            _logger.d('TaskSummaryNotifier: Received ${tasks.length} tasks');
            final summary = _computeSummary(tasks);
            state = AsyncValue.data(summary);
          },
        );
      }
      
      // This should never be reached as the stream is continuous
      throw Exception('Task stream ended unexpectedly');
    } catch (e) {
      _logger.e('TaskSummaryNotifier: Error loading task summary', error: e);
      throw Exception('Failed to load task summary: $e');
    }
  }

  /// Computes task summary from a list of tasks.
  TaskSummary _computeSummary(List<Task> tasks) {
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((task) => 
      task.status == TaskStatus.completed || 
      task.status == TaskStatus.approved
    ).length;
    final pendingTasks = tasks.where((task) => 
      task.status == TaskStatus.pendingApproval
    ).length;
    final availableTasks = tasks.where((task) => 
      task.status == TaskStatus.available
    ).length;
    final assignedTasks = tasks.where((task) => 
      task.status == TaskStatus.assigned
    ).length;
    final needsRevisionTasks = tasks.where((task) => 
      task.status == TaskStatus.needsRevision
    ).length;
    final dueToday = tasks.where((task) => 
      task.dueDate != null && 
      task.dueDate!.isBefore(DateTime.now().add(const Duration(days: 1)))
    ).length;
    
    // Calculate points (assuming 10 points per completed task)
    final pointsEarned = completedTasks * 10;
    
    // Calculate completion percentage
    final completionPercentage = totalTasks > 0 
      ? (completedTasks / totalTasks * 100).round() 
      : 0;
    
    return TaskSummary(
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      pendingTasks: pendingTasks,
      availableTasks: availableTasks,
      needsRevisionTasks: needsRevisionTasks,
      assignedTasks: assignedTasks,
      dueToday: dueToday,
      pointsEarned: pointsEarned,
      completionPercentage: completionPercentage,
    );
  }

  /// Refreshes the task summary.
  Future<void> refresh() async {
    _logger.d('TaskSummaryNotifier: Refreshing task summary');
    ref.invalidateSelf();
  }

  /// Gets the current task summary.
  TaskSummary? get summary => state.value;

  /// Gets the current loading state.
  bool get isLoading => state.isLoading;

  /// Gets the current error message.
  String? get errorMessage => state.hasError ? state.error.toString() : null;

  /// Gets the current state status.
  TaskSummaryStatus get status {
    if (state.isLoading) return TaskSummaryStatus.loading;
    if (state.hasError) return TaskSummaryStatus.error;
    return TaskSummaryStatus.loaded;
  }

  /// Counts tasks by status.
  void _countTasksByStatus(List<Task> tasks) {
    _completedTasks = tasks.where((task) => 
      task.status == TaskStatus.completed
    ).length;
    
    _pendingTasks = tasks.where((task) => 
      task.status == TaskStatus.pendingApproval
    ).length;
    
    _availableTasks = tasks.where((task) => 
      task.status == TaskStatus.available
    ).length;
    
    _assignedTasks = tasks.where((task) => 
      task.status == TaskStatus.assigned
    ).length;
  }

  /// Calculates completion percentage.
  double _calculateCompletionPercentage() {
    if (_totalTasks == 0) return 0.0;
    return (_completedTasks / _totalTasks) * 100;
  }
} 