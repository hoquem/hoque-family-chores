import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/presentation/providers/task_list_provider.dart'
    as app_task_list_provider;
import 'package:hoque_family_chores/presentation/widgets/task_list_tile.dart';
import 'package:hoque_family_chores/presentation/screens/add_task_screen.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _logger = AppLogger();

  Future<void> _refreshData() async {
    _logger.d('TaskListScreen: Refreshing tasks');
    final taskListProvider =
        context.read<app_task_list_provider.TaskListProvider>();
    final authProvider = context.read<AuthProvider>();

    final currentUserId = authProvider.currentUserId;
    final userFamilyId = authProvider.userFamilyId;

    if (currentUserId == null || userFamilyId == null) {
      _logger.w(
        'TaskListScreen: Cannot refresh - User ID or Family ID is null',
      );
      return;
    }

    await taskListProvider.fetchTasks(
      familyId: userFamilyId,
      userId: currentUserId,
    );
  }

  Future<void> _handleTaskStatusUpdate(
    String taskId,
    TaskStatus newStatus,
  ) async {
    try {
      final taskListProvider =
          context.read<app_task_list_provider.TaskListProvider>();
      final authProvider = context.read<AuthProvider>();
      final familyId = authProvider.userFamilyId;

      if (familyId == null) {
        _logger.e('TaskListScreen: Cannot update task status - No family ID');
        return;
      }

      await taskListProvider.updateTaskStatus(
        familyId: familyId,
        taskId: taskId,
        newStatus: newStatus,
      );
      _logger.i('TaskListScreen: Task status updated successfully');
    } catch (e, s) {
      _logger.e(
        'TaskListScreen: Error updating task status',
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update task status. Please try again.'),
          ),
        );
      }
    }
  }

  void _navigateToAddTask() {
    _logger.i('TaskListScreen: Navigating to Add New Task screen');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddTaskScreen()));
  }

  Widget _buildTaskList() {
    final taskListProvider =
        context.watch<app_task_list_provider.TaskListProvider>();
    final authProvider = context.read<AuthProvider>();

    if (taskListProvider.isLoading && taskListProvider.tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading tasks...'),
          ],
        ),
      );
    }

    if (taskListProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading tasks:',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text(
                taskListProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (taskListProvider.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No tasks found for you in this family!'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Retry Loading Tasks'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        itemCount: taskListProvider.tasks.length,
        itemBuilder: (context, index) {
          final task = taskListProvider.tasks[index];
          final UserProfile? assignedUserProfile =
              authProvider.currentUserProfile;

          final String assignedToId = task.assignedTo?.toString() ?? 'unknown';
          final UserProfile displayUserProfile =
              assignedUserProfile ??
              UserProfile(
                id: assignedToId,
                member: FamilyMember(
                  id: assignedToId,
                  userId: assignedToId,
                  familyId: task.familyId,
                  name: 'Unknown User',
                  role: FamilyRole.child,
                  points: 0,
                  joinedAt: DateTime(2000),
                  updatedAt: DateTime(2000),
                ),
                points: 0,
                badges: [],
                achievements: [],
                createdAt: DateTime(2000),
                updatedAt: DateTime(2000),
                completedTasks: [],
                inProgressTasks: [],
                availableTasks: [],
                preferences: {},
                statistics: {},
              );

          return TaskListTile(
            key: ValueKey(task.id),
            task: task,
            user: displayUserProfile,
            onToggleStatus: (bool? newValue) {
              if (newValue != null) {
                final newStatus =
                    newValue ? TaskStatus.pendingApproval : TaskStatus.assigned;
                _logger.d(
                  'TaskListScreen: Toggling status for task ${task.id} to $newStatus',
                );
                _handleTaskStatusUpdate(task.id, newStatus);
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('TaskListScreen: Building screen');
    final authProvider = context.read<AuthProvider>();

    final currentUserId = authProvider.currentUserId;
    final userFamilyId = authProvider.userFamilyId;

    if (currentUserId == null || userFamilyId == null) {
      _logger.w(
        'TaskListScreen: User ID or Family ID is null, cannot display tasks',
      );
      return const Scaffold(
        body: Center(
          child: Text('Please log in and join a family to view tasks.'),
        ),
      );
    }

    return Scaffold(
      body: _buildTaskList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTask,
        child: const Icon(Icons.add),
        tooltip: 'Add New Task',
      ),
    );
  }
}
