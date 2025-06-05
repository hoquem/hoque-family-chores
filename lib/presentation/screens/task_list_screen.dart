// lib/presentation/screens/task_list_screen.dart
import 'package:flutter/material.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
      ),
      body: const Center(
        child: Text('Task List Screen - Content Coming Soon!'),
      ),
    );
  }
}