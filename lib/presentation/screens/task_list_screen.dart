// lib/presentation/screens/task_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/presentation/providers/task_list_provider.dart';
import 'package:hoque_family_chores/presentation/widgets/task_list_tile.dart';
import 'package:hoque_family_chores/services/firebase_task_service.dart'; // To use the real service
// import 'package:hoque_family_chores/services/mock_task_service.dart'; // Or use this for testing

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TaskListProvider(
        FirebaseTaskService(), // <-- Using the REAL Firebase service
        // MockTaskService(), // <-- SWAP to this for mock data testing
        'fm_001', // TODO: Replace with actual logged-in user ID from AuthProvider
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Task List'),
          // You could add a "Create Task" button for admins here
        ),
        body: Column(
          children: [
            Consumer<TaskListProvider>(
              builder: (context, provider, child) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SegmentedButton<TaskFilterType>(
                    segments: const <ButtonSegment<TaskFilterType>>[
                      ButtonSegment(value: TaskFilterType.all, label: Text('All')),
                      ButtonSegment(value: TaskFilterType.myTasks, label: Text('My Tasks')),
                      ButtonSegment(value: TaskFilterType.available, label: Text('Available')),
                      ButtonSegment(value: TaskFilterType.completed, label: Text('Done')),
                    ],
                    selected: <TaskFilterType>{provider.currentFilter},
                    onSelectionChanged: (Set<TaskFilterType> newSelection) {
                      provider.setFilter(newSelection.first);
                    },
                  ),
                );
              },
            ),
            Expanded(
              child: Consumer<TaskListProvider>(
                builder: (context, provider, child) {
                  return StreamBuilder<List<Task>>(
                    stream: provider.tasksStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No tasks found for this filter.'));
                      }

                      final tasks = snapshot.data!;
                      return ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return TaskListTile(task: tasks[index]);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}