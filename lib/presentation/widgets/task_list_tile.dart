// lib/presentation/widgets/task_list_tile.dart
import 'package:flutter/material.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/user_profile.dart'; // Import UserProfile
import 'package:hoque_family_chores/models/enums.dart'; // For TaskStatus

class TaskListTile extends StatelessWidget {
  final Task task;
  final UserProfile user; // Change type to UserProfile
  final ValueChanged<bool?> onToggleStatus;

  const TaskListTile({
    super.key,
    required this.task,
    required this.user,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = task.status == TaskStatus.completed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? Colors.grey : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  // Access user.name, user.totalPoints, user.currentLevel etc.
                  // since it's a UserProfile now
                  Text(
                    'Assigned to: ${user.name} (Lvl ${user.currentLevel})',
                    style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Points: ${task.points}',
                    style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      task.description,
                      style: TextStyle(fontSize: 12.0, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
            Checkbox(
              value: isCompleted,
              onChanged: onToggleStatus,
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}