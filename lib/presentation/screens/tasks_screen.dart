import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/widgets/my_tasks_widget.dart';
import 'package:hoque_family_chores/presentation/providers/my_tasks_provider.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _logger = AppLogger();

  Future<void> _refreshData() async {
    _logger.d('TasksScreen: Refreshing data');
    final myTasksProvider = context.read<MyTasksProvider>();
    myTasksProvider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('TasksScreen: Building screen');
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: MyTasksWidget(),
        ),
      ),
    );
  }
}
