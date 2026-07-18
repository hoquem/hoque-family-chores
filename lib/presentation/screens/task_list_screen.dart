import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/add_task_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/help_button.dart';
import 'package:hoque_family_chores/presentation/widgets/task_list_tile.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  Future<void> _refreshData(WidgetRef ref, FamilyId familyId) async {
    final logger = AppLogger();
    logger.d('TaskListScreen: Refreshing tasks');
    
    try {
      await ref.read(taskListNotifierProvider(familyId).notifier).refresh();
      logger.i('TaskListScreen: Tasks refreshed successfully');
    } catch (e, s) {
      logger.e(
        'TaskListScreen: Error refreshing tasks',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _handleTaskStatusUpdate(
    WidgetRef ref,
    FamilyId familyId,
    String taskId,
    TaskStatus newStatus,
    UserId userId,
  ) async {
    final logger = AppLogger();
    try {
      final notifier = ref.read(taskListNotifierProvider(familyId).notifier);
      
      switch (newStatus) {
        case TaskStatus.completed:
          await notifier.completeTask(taskId, userId, familyId);
          break;
        case TaskStatus.available:
          await notifier.unassignTask(taskId);
          break;
        case TaskStatus.assigned:
          break;
        default:
          logger.w('TaskListScreen: Unhandled status update: $newStatus');
      }
      
      logger.i('TaskListScreen: Task status updated successfully');
    } catch (e, s) {
      logger.e(
        'TaskListScreen: Error updating task status',
        error: e,
        stackTrace: s,
      );
    }
  }

  void _navigateToAddTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
  }

  /// Applies the selected filter; needs the current user for "My Tasks".
  List<Task> _applyFilter(
      List<Task> tasks, TaskFilterType filter, UserId userId) {
    switch (filter) {
      case TaskFilterType.all:
        return tasks;
      case TaskFilterType.myTasks:
        return tasks.where((t) => t.assignedToId == userId).toList();
      case TaskFilterType.available:
        return tasks.where((t) => t.status == TaskStatus.available).toList();
      case TaskFilterType.pendingApproval:
        return tasks
            .where((t) => t.status == TaskStatus.pendingApproval)
            .toList();
      case TaskFilterType.completed:
        return tasks.where((t) => t.status == TaskStatus.completed).toList();
    }
  }

  Widget _buildTaskList(BuildContext context, WidgetRef ref, FamilyId familyId) {
    final tasksAsync = ref.watch(taskListNotifierProvider(familyId));
    final filter = ref.watch(taskFilterNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return tasksAsync.when(
      data: (allTasks) {
        if (allTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No tasks found for you in this family!'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _refreshData(ref, familyId),
                  child: const Text('Retry Loading Tasks'),
                ),
              ],
            ),
          );
        }

        final tasks = _applyFilter(allTasks, filter, currentUser.id);
        if (tasks.isEmpty) {
          return const Center(child: Text('No tasks match this filter.'));
        }

        return RefreshIndicator(
          onRefresh: () => _refreshData(ref, familyId),
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];

              return TaskListTile(
                key: ValueKey(task.id.value),
                task: task,
                user: currentUser,
                onToggleStatus: (bool? newValue) {
                  if (newValue != null) {
                    final newStatus = newValue 
                        ? TaskStatus.completed 
                        : TaskStatus.assigned;
                    _handleTaskStatusUpdate(ref, familyId, task.id.value, newStatus, currentUser.id);
                  }
                },
                onReturnToAvailable: () {
                  _handleTaskStatusUpdate(ref, familyId, task.id.value, TaskStatus.available, currentUser.id);
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading tasks...'),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: context.tokens.brick, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading tasks:',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: context.tokens.brick),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _refreshData(ref, familyId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;
    final familyId = currentUser?.familyId;

    if (currentUser == null || familyId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in and join a family to view tasks.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          const HelpButton(content: kTasksHelp),
          PopupMenuButton<TaskFilterType>(
            onSelected: (TaskFilterType filter) {
              ref.read(taskFilterNotifierProvider.notifier).setFilter(filter);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: TaskFilterType.all,
                child: Text('All Tasks'),
              ),
              const PopupMenuItem(
                value: TaskFilterType.available,
                child: Text('Available'),
              ),
              const PopupMenuItem(
                value: TaskFilterType.myTasks,
                child: Text('My Tasks'),
              ),
              const PopupMenuItem(
                value: TaskFilterType.pendingApproval,
                child: Text('Needs Approval'),
              ),
              const PopupMenuItem(
                value: TaskFilterType.completed,
                child: Text('Completed'),
              ),
            ],
            // icon: renders a default 48x48 IconButton (was a ~32px padded
            // Icon via child: — below the touch-target floor).
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _buildTaskList(context, ref, familyId),
      floatingActionButton: FloatingActionButton(
        // Distinct from the Rewards tab's FAB: both live in MainScreen's
        // IndexedStack at once and would otherwise share Flutter's default
        // hero tag.
        heroTag: 'tasks_fab',
        onPressed: () => _navigateToAddTask(context),
        backgroundColor: context.tokens.starGold,
        foregroundColor: context.tokens.ink,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}
