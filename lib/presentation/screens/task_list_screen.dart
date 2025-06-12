import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/models/user_profile.dart'; // Import UserProfile
import 'package:hoque_family_chores/models/enums.dart'; // Import enums for TaskFilterType, TaskStatus
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/presentation/providers/task_list_provider.dart'
    as app_task_list_provider;
import 'package:hoque_family_chores/presentation/widgets/task_list_tile.dart';
import 'package:hoque_family_chores/presentation/screens/add_task_screen.dart';
import 'package:hoque_family_chores/services/logging_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  Widget build(BuildContext context) {
    final taskListProvider =
        Provider.of<app_task_list_provider.TaskListProvider>(context);
    final authProvider = context.read<AuthProvider>();

    final currentUserId = authProvider.currentUserId;
    final userFamilyId = authProvider.userFamilyId;

    if (currentUserId == null || userFamilyId == null) {
      logger.w(
        "TaskListScreen: User ID or Family ID is null, cannot display tasks.",
      );
      return Scaffold(
        appBar: AppBar(title: const Text('Tasks')),
        body: const Center(
          child: Text('Please log in and join a family to view tasks.'),
        ),
      );
    }

    // Assign to local non-nullable variables after null check
    final String userId = currentUserId!;
    final String familyId = userFamilyId!;

    void handleTaskOperation() {
      taskListProvider.fetchTasks(familyId: familyId, userId: userId);
    }

    void handleTaskStatusUpdate(String taskId, TaskStatus status) {
      taskListProvider.updateTaskStatus(
        familyId: familyId,
        taskId: taskId,
        newStatus: status,
      );
    }

    if (taskListProvider.isLoading && taskListProvider.tasks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tasks')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (taskListProvider.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tasks')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading tasks: ${taskListProvider.errorMessage}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    if (taskListProvider.tasks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tasks')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No tasks found for you in this family!'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  handleTaskOperation();
                },
                child: const Text('Retry Loading Tasks'),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            logger.i("Navigating to Add New Task screen.");
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddTaskScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Chores'),
        actions: [
          PopupMenuButton<TaskFilterType>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              taskListProvider.setFilter(filter);
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: TaskFilterType.all,
                    child: Text('All Tasks'),
                  ),
                  const PopupMenuItem(
                    value: TaskFilterType.myTasks,
                    child: Text('My Tasks'),
                  ),
                  const PopupMenuItem(
                    value: TaskFilterType.available,
                    child: Text('Available Tasks'),
                  ),
                  const PopupMenuItem(
                    value: TaskFilterType.completed,
                    child: Text('Completed Tasks'),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              logger.i("Navigating to User Profile/Settings.");
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: taskListProvider.tasks.length,
        itemBuilder: (context, index) {
          final task = taskListProvider.tasks[index];
          final UserProfile? assignedUserProfile = authProvider.getFamilyMember(
            task.assigneeId ?? '',
          );

          final UserProfile displayUserProfile =
              assignedUserProfile ??
              UserProfile(
                id: task.assigneeId ?? 'unknown',
                name: 'Unknown User',
                joinedAt: DateTime(2000),
              );

          return TaskListTile(
            key: ValueKey(task.id ?? 'no-id'),
            task: task,
            user: displayUserProfile,
            onToggleStatus: (bool? newValue) {
              if (newValue != null && task.id != null) {
                final newStatus =
                    newValue ? TaskStatus.pendingApproval : TaskStatus.assigned;
                logger.d("Toggling status for task ${task.id} to $newStatus.");
                handleTaskStatusUpdate(task.id!, newStatus);
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          logger.i("Navigating to Add New Task screen.");
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddTaskScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
