// lib/presentation/widgets/task_list_tile.dart
import 'package:flutter/material.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/presentation/screens/task_details_screen.dart'; // <-- THIS IS THE REQUIRED IMPORT
import 'package:intl/intl.dart';

class TaskListTile extends StatelessWidget {
  final Task task;
  const TaskListTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final statusIcon = _getStatusIcon(task.status);

    final bool isOverdue = task.dueDate != null &&
        task.dueDate!.toDate().isBefore(DateTime.now()) &&
        task.status != TaskStatus.completed;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(statusIcon.icon, color: statusIcon.color, size: 30),
        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(task.assigneeName ?? 'Unassigned'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${task.points} pts',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            if (task.dueDate != null)
              Text(
                DateFormat.yMd().format(task.dueDate!.toDate()),
                style: TextStyle(
                  color: isOverdue ? Colors.red : Colors.grey.shade600,
                  fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailsScreen(taskId: task.id),
            ),
          );
        },
      ),
    );
  }

  ({IconData icon, Color color}) _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.available:
        return (icon: Icons.person_add_alt_1_outlined, color: Colors.blue);
      case TaskStatus.assigned:
        return (icon: Icons.person_outline, color: Colors.orange);
      case TaskStatus.pendingApproval:
        return (icon: Icons.hourglass_top_rounded, color: Colors.purple);
      case TaskStatus.completed:
        return (icon: Icons.check_circle, color: Colors.green);
    }
  }
}