// lib/presentation/widgets/task_list_tile.dart
import 'package:flutter/material.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class TaskListTile extends StatefulWidget {
  final Task task;
  final UserProfile user;
  final ValueChanged<bool?> onToggleStatus;
  final bool isUpdating;

  const TaskListTile({
    super.key,
    required this.task,
    required this.user,
    required this.onToggleStatus,
    this.isUpdating = false,
  });

  @override
  State<TaskListTile> createState() => _TaskListTileState();
}

class _TaskListTileState extends State<TaskListTile> {
  bool _isError = false;
  String? _errorMessage;
  final _logger = AppLogger();

  void _handleStatusChange(bool? value) {
    if (value == null) return;

    setState(() {
      _isError = false;
      _errorMessage = null;
    });

    try {
      widget.onToggleStatus(value);
    } catch (e) {
      _logger.e('Error updating task status: $e');
      setState(() {
        _isError = true;
        _errorMessage = 'Failed to update task status';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = widget.task.status == TaskStatus.completed;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task.title,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Assigned to: ${widget.user.member.name} (Lvl ${UserProfile.calculateLevelFromPoints(widget.user.points)})',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Points: ${widget.task.points}',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (widget.task.description.isNotEmpty) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          widget.task.description,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.isUpdating)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Checkbox(
                    value: isCompleted,
                    onChanged: _handleStatusChange,
                    activeColor: theme.primaryColor,
                  ),
              ],
            ),
            if (_isError) ...[
              const SizedBox(height: 8.0),
              Text(
                _errorMessage ?? 'An error occurred',
                style: const TextStyle(color: Colors.red, fontSize: 12.0),
              ),
              const SizedBox(height: 4.0),
              TextButton(
                onPressed: () => _handleStatusChange(!isCompleted),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
