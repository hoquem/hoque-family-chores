// lib/presentation/widgets/task_list_tile.dart

import 'package:flutter/material.dart';
import 'package:hoque_family_chores/models/enums.dart'; // ADDED: Missing import for enums
import 'package:hoque_family_chores/models/task.dart';
import 'package:intl/intl.dart'; // A great package for date formatting

class TaskListTile extends StatelessWidget {
  final Task task;

  const TaskListTile({super.key, required this.task});

  // This helper method determines the correct icon and color based on the task status.
  // It now handles all cases to fix the 'body_might_complete_normally' error.
  ({IconData icon, Color color}) _getStatusAppearance(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
      case TaskStatus.available:
        return (icon: Icons.radio_button_unchecked, color: Colors.grey.shade600);
      case TaskStatus.assigned:
      case TaskStatus.inProgress:
        return (icon: Icons.person, color: Colors.blue.shade700);
      case TaskStatus.pendingApproval:
        return (icon: Icons.hourglass_top_rounded, color: Colors.orange.shade700);
      case TaskStatus.completed:
      case TaskStatus.verified:
        return (icon: Icons.check_circle, color: Colors.green.shade700);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAppearance = _getStatusAppearance(task.status);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${task.points}',
              style: textTheme.titleLarge?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'pts',
              style: textTheme.bodySmall?.copyWith(color: Theme.of(context).primaryColor),
            ),
          ],
        ),
        title: Text(
          task.title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(statusAppearance.icon, size: 16, color: statusAppearance.color),
                const SizedBox(width: 6),
                Text(
                  task.assigneeName ?? 'Available',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Gracefully handle the due date, checking if it exists
            if (task.dueDate != null)
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                  const SizedBox(width: 6),
                  // MODIFIED: Use the DateTime object directly without the incorrect .toDate() call
                  Text(
                    'Due: ${DateFormat.yMMMd().format(task.dueDate!)}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Navigate to Task Details Screen
        },
      ),
    );
  }
}