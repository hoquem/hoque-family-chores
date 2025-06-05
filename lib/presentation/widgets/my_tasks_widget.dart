// lib/presentation/widgets/my_tasks_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/my_tasks_provider.dart';
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart'; // For navigation

class MyTasksWidget extends StatelessWidget {
  const MyTasksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<MyTasksProvider>(
          builder: (context, provider, child) {
            switch (provider.state) {
              case MyTasksState.loading:
              case MyTasksState.initial:
                return const Center(child: CircularProgressIndicator());
              case MyTasksState.error:
                return Center(child: Text('Error: ${provider.errorMessage}'));
              case MyTasksState.loaded:
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
                      itemCount: provider.tasks.length > 3 ? 3 : provider.tasks.length, // Show max 3
                      itemBuilder: (context, index) {
                        final task = provider.tasks[index];
                        return ListTile(
                          leading: Icon(Icons.check_box_outline_blank, color: Theme.of(context).primaryColor),
                          title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                          // You could add due date info here
                          // subtitle: Text(task.dueDate != null ? 'Due: ${DateFormat.yMd().format(task.dueDate!)}' : 'No due date'),
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
                                MaterialPageRoute(builder: (context) => const TaskListScreen()),
                              );
                            },
                            child: const Text('View All My Tasks →'),
                          ),
                        ),
                      ),
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}