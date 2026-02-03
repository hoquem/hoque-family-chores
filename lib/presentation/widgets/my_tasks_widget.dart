// lib/presentation/widgets/my_tasks_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/my_tasks_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart'; // For navigation
import 'package:hoque_family_chores/utils/logger.dart';

class MyTasksWidget extends ConsumerWidget {
  const MyTasksWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _logger = AppLogger();
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.user?.id;
    final familyId = authState.user?.familyId;

    if (userId == null || familyId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final myTasksState = ref.watch(myTasksNotifierProvider(familyId, userId));

    Future<void> _refreshData() async {
      _logger.d('MyTasksWidget: Refreshing data');
      ref.read(myTasksNotifierProvider(familyId, userId).notifier).refresh();
    }

    _logger.d('MyTasksWidget: build() called');
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: IntrinsicHeight(
              child: myTasksState.when(
                data: (tasks) => _buildTasksList(context, tasks),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Error: $error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8.0),
                      ElevatedButton(
                        onPressed: _refreshData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTasksList(BuildContext context, List<dynamic> tasks) {
    final _logger = AppLogger();
    _logger.d('MyTasksWidget: _buildTasksList called with ${tasks.length} tasks');
    
    if (tasks.isEmpty) {
      _logger.d('MyTasksWidget: No tasks found - showing empty state');
      return const Center(
        child: ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text("You're all caught up!"),
          subtitle: Text("No pending tasks."),
        ),
      );
    }

    _logger.d('MyTasksWidget: Building task list with ${tasks.length} tasks');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length > 3 ? 3 : tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            _logger.d('MyTasksWidget: Building task item $index: ${task.title}');
            return ListTile(
              leading: Icon(
                Icons.check_box_outline_blank,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(
                task.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '${task.points.value} points',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.0),
              ),
            );
          },
        ),
        if (tasks.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TaskListScreen(),
                    ),
                  );
                },
                child: const Text('View All My Tasks →'),
              ),
            ),
          ),
      ],
    );
  }
}
