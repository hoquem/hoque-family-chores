// lib/presentation/widgets/task_list_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/available_tasks_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/task_details_screen.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class TaskListTile extends ConsumerStatefulWidget {
  final Task task;
  final User user;
  final ValueChanged<bool?> onToggleStatus;
  final VoidCallback? onReturnToAvailable;
  final bool isUpdating;

  const TaskListTile({
    super.key,
    required this.task,
    required this.user,
    required this.onToggleStatus,
    this.onReturnToAvailable,
    this.isUpdating = false,
  });

  @override
  ConsumerState<TaskListTile> createState() => _TaskListTileState();
}

class _TaskListTileState extends ConsumerState<TaskListTile> {
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

  Future<void> _handleTakeOwnership() async {
    _logger.d('TaskListTile: Taking ownership of task ${widget.task.id}');
    
    setState(() {
      _isError = false;
      _errorMessage = null;
    });

    try {
      final familyId = widget.task.familyId;
      final availableTasksNotifier = ref.read(availableTasksNotifierProvider(familyId).notifier);
      final taskListNotifier = ref.read(taskListNotifierProvider(familyId).notifier);
      
      await availableTasksNotifier.claimTask(
        widget.task.id.value,
        widget.user.id,
        familyId,
      );
      
      // Refresh task list after claiming
      await taskListNotifier.refresh();
      
      _logger.i('TaskListTile: Successfully took ownership of task ${widget.task.id}');
    } catch (e) {
      _logger.e('TaskListTile: Error taking ownership of task: $e');
      setState(() {
        _isError = true;
        _errorMessage = 'Failed to take ownership of task';
      });
    }
  }

  Future<void> _handleCantDoIt() async {
    _logger.d('TaskListTile: Returning task ${widget.task.id} to available status');
    
    setState(() {
      _isError = false;
      _errorMessage = null;
    });

    try {
      // Return task to available status using the new callback
      if (widget.onReturnToAvailable != null) {
        widget.onReturnToAvailable!();
        _logger.i('TaskListTile: Successfully returned task ${widget.task.id} to available status');
      } else {
        _logger.w('TaskListTile: onReturnToAvailable callback is null');
        setState(() {
          _isError = true;
          _errorMessage = 'Cannot return task to available status';
        });
      }
    } catch (e) {
      _logger.e('TaskListTile: Error returning task to available status: $e');
      setState(() {
        _isError = true;
        _errorMessage = 'Failed to return task to available status';
      });
    }
  }

  Widget _buildActionButton() {
    final theme = Theme.of(context);
    
    // Show different actions based on task status
    switch (widget.task.status) {
      case TaskStatus.available:
        return ElevatedButton.icon(
          onPressed: _handleTakeOwnership,
          icon: const Icon(Icons.person_add),
          label: const Text('Take Ownership'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
          ),
        );
      
      case TaskStatus.assigned:
        return ElevatedButton.icon(
          onPressed: _handleCantDoIt,
          icon: const Icon(Icons.cancel),
          label: const Text("Can't do it"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        );
      
      case TaskStatus.pendingApproval:
        // No action button for pending approval tasks
        return const SizedBox.shrink();
      
      case TaskStatus.completed:
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 24,
        );
      
      case TaskStatus.needsRevision:
        return const Icon(
          Icons.warning,
          color: Colors.orange,
          size: 24,
        );
    }
  }

  String _getStatusText() {
    switch (widget.task.status) {
      case TaskStatus.available:
        return 'Available';
      case TaskStatus.assigned:
        return 'Assigned';
      case TaskStatus.pendingApproval:
        return 'Pending Approval';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.needsRevision:
        return 'Needs Revision';
    }
  }

  Color _getStatusColor() {
    switch (widget.task.status) {
      case TaskStatus.available:
        return Colors.blue;
      case TaskStatus.assigned:
        return Colors.orange;
      case TaskStatus.pendingApproval:
        return Colors.purple;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.needsRevision:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = widget.task.status == TaskStatus.completed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailsScreen(task: widget.task),
            ),
          );
        },
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: _getStatusColor()),
                            ),
                            child: Text(
                              _getStatusText(),
                              style: TextStyle(
                                fontSize: 12.0,
                                color: _getStatusColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            '${widget.task.points} pts',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (widget.task.assignedToId != null) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          'Assigned to: ${widget.user.name}',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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
                  _buildActionButton(),
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
                onPressed: () {
                  if (widget.task.status == TaskStatus.available) {
                    _handleTakeOwnership();
                  } else {
                    _handleStatusChange(widget.task.status != TaskStatus.pendingApproval);
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}
