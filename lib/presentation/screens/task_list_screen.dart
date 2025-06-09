// lib/presentation/screens/task_list_screen.dart

import 'package:flutter/material.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/presentation/providers/task_list_provider.dart';
import 'package:provider/provider.dart';

class TaskListScreen extends StatefulWidget {
  // Correct constructor
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the provider is available
    // when we call listenToTasks.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize the stream when the screen loads
      Provider.of<TaskListProvider>(context, listen: false).setFilter(TaskFilterType.all);
    });
  }

  @override
  Widget build(BuildContext context) {
    // We use a Consumer here to rebuild when the filter changes
    return Consumer<TaskListProvider>(
      builder: (context, taskProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('All Chores'),
            // TODO: Add a filter button here to call provider.setFilter()
          ),
          body: StreamBuilder<List<Task>>(
            // The stream now comes directly from the provider
            stream: taskProvider.tasksStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No chores available.'));
              }

              final tasks = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  // Assuming you have a TaskListCard widget from before
                  return ListTile(title: Text(task.title));
                },
              );
            },
          ),
        );
      },
    );
  }
}