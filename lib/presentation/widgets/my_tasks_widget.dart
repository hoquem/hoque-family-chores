// lib/presentation/widgets/my_tasks_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/my_tasks_provider.dart';
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart'; // For navigation
import 'package:hoque_family_chores/utils/logger.dart';

class MyTasksWidget extends StatefulWidget {
  const MyTasksWidget({super.key});

  @override
  State<MyTasksWidget> createState() => _MyTasksWidgetState();
}

class _MyTasksWidgetState extends State<MyTasksWidget> {
  final _logger = AppLogger();

  Future<void> _refreshData() async {
    _logger.d('MyTasksWidget: Refreshing data');
    final provider = context.read<MyTasksProvider>();
    provider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<MyTasksProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: IntrinsicHeight(
                  child: switch (provider.state) {
                    MyTasksState.loading => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    MyTasksState.error => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Error: ${provider.errorMessage}',
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
                    MyTasksState.loaded => _buildTasksList(provider),
                    MyTasksState.initial => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTasksList(MyTasksProvider provider) {
    if (provider.tasks.isEmpty) {
      return const Center(
        child: ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text("You're all caught up!"),
          subtitle: Text("No pending tasks."),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.tasks.length > 3 ? 3 : provider.tasks.length,
          itemBuilder: (context, index) {
            final task = provider.tasks[index];
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
                '${task.points} points',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.0),
              ),
            );
          },
        ),
        if (provider.tasks.length > 3)
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
