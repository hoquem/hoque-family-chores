import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/widgets/task_list_tile.dart';
import 'package:hoque_family_chores/presentation/screens/add_task_screen.dart';
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
          // This would need to be handled differently - need user ID
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
    final logger = AppLogger();
    logger.i('TaskListScreen: Navigating to Add New Task screen');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );
  }

  Widget _buildTaskList(BuildContext context, WidgetRef ref, FamilyId familyId) {
    final logger = AppLogger();
    final tasksAsync = ref.watch(taskListNotifierProvider(familyId));
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
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
                    logger.d(
                      'TaskListScreen: Toggling status for task ${task.id} to $newStatus',
                    );
                    _handleTaskStatusUpdate(ref, familyId, task.id.value, newStatus, currentUser.id);
                  }
                },
                onReturnToAvailable: () {
                  logger.d(
                    'TaskListScreen: Returning task ${task.id} to available status',
                  );
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
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading tasks:',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red),
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
    final logger = AppLogger();
    logger.d('TaskListScreen: Building screen');
    
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;
    final familyId = currentUser?.familyId;

    if (currentUser == null || familyId == null) {
      logger.w(
        'TaskListScreen: User ID or Family ID is null, cannot display tasks',
      );
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
                value: TaskFilterType.completed,
                child: Text('Completed'),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: _buildTaskList(context, ref, familyId),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTask(context),
        child: const Icon(Icons.add),
        tooltip: 'Add New Task',
      ),
    );
  }
}