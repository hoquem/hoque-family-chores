// lib/presentation/screens/task_details_screen.dart
import 'package:flutter/material.dart';

class TaskDetailsScreen extends StatelessWidget {
  final String taskId;
  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: Center(
        child: Text('Details for Task ID: $taskId - Content Coming Soon!'),
      ),
    );
  }
}