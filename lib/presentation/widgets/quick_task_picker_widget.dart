// lib/presentation/widgets/quick_task_picker_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/available_tasks_provider.dart';

class QuickTaskPickerWidget extends StatelessWidget {
  const QuickTaskPickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AvailableTasksProvider>(
      builder: (context, provider, child) {
        if (provider.state == AvailableTasksState.loading || provider.state == AvailableTasksState.initial) {
          return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
        }

        if (provider.state == AvailableTasksState.error) {
          return SizedBox(height: 80, child: Center(child: Text('Error: ${provider.errorMessage}')));
        }

        if (provider.tasks.isEmpty) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle_outline, color: Colors.green),
              title: Text('No available tasks right now!'),
              subtitle: Text('Great job, team!'),
            ),
          );
        }

        return SizedBox(
          height: 100, // Fixed height for the horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: provider.tasks.length,
            itemBuilder: (context, index) {
              final task = provider.tasks[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: InkWell(
                  onTap: provider.isAssigning ? null : () async {
                    final success = await provider.selectTask(task.id);
                    if (context.mounted && success) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                          content: Text('"${task.title}" assigned to you!'),
                          backgroundColor: Colors.green,
                        ));
                    }
                  },
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          task.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        const Text('Tap to claim!', style: TextStyle(color: Colors.blue, fontSize: 12))
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}