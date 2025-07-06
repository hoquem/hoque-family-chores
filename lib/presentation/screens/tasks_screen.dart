import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/widgets/my_tasks_widget.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/my_tasks_notifier.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _logger = AppLogger();

    Future<void> _refreshData() async {
      _logger.d('TasksScreen: Refreshing data');
      ref.read(myTasksNotifierProvider.notifier).refresh();
    }

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
