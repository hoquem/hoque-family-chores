// lib/presentation/widgets/task_list_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/available_tasks_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
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
  bool _isProcessing = false;
  String? _errorMessage;
  final _logger = AppLogger();

  bool get _isAdmin =>
      widget.user.role == UserRole.parent ||
      widget.user.role == UserRole.guardian;

  bool get _isAssignedToMe =>
      widget.task.assignedToId == widget.user.id;

  Future<void> _handleTakeOwnership() async {
    _logger.d('TaskListTile: Taking ownership of task ${widget.task.id}');

    setState(() {
      _isError = false;
      _errorMessage = null;
      _isProcessing = true;
    });

    try {
      final familyId = widget.task.familyId;
      final availableTasksNotifier =
          ref.read(availableTasksNotifierProvider(familyId).notifier);
      final taskListNotifier =
          ref.read(taskListNotifierProvider(familyId).notifier);

      await availableTasksNotifier.claimTask(
        widget.task.id.value,
        widget.user.id,
        familyId,
      );

      await taskListNotifier.refresh();
      _logger.i(
          'TaskListTile: Successfully took ownership of task ${widget.task.id}');
    } catch (e) {
      _logger.e('TaskListTile: Error taking ownership of task: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Failed to take ownership of task';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleCantDoIt() async {
    _logger.d(
        'TaskListTile: Returning task ${widget.task.id} to available status');

    setState(() {
      _isError = false;
      _errorMessage = null;
      _isProcessing = true;
    });

    try {
      if (widget.onReturnToAvailable != null) {
        widget.onReturnToAvailable!();
        _logger.i(
            'TaskListTile: Successfully returned task ${widget.task.id} to available status');
      } else {
        _logger.w('TaskListTile: onReturnToAvailable callback is null');
        setState(() {
          _isError = true;
          _errorMessage = 'Cannot return task to available status';
        });
      }
    } catch (e) {
      _logger.e('TaskListTile: Error returning task to available status: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Failed to return task to available status';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleMarkComplete() async {
    _logger.d('TaskListTile: Marking task ${widget.task.id} as complete');

    setState(() {
      _isError = false;
      _errorMessage = null;
      _isProcessing = true;
    });

    try {
      final familyId = widget.task.familyId;
      final notifier =
          ref.read(taskListNotifierProvider(familyId).notifier);

      await notifier.completeTask(
        widget.task.id.value,
        widget.user.id,
        familyId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task submitted for approval!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _logger.i('TaskListTile: Task ${widget.task.id} marked as complete');
    } catch (e) {
      _logger.e('TaskListTile: Error marking task as complete: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Failed to mark task as complete';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleApprove() async {
    _logger.d('TaskListTile: Approving task ${widget.task.id}');

    setState(() {
      _isError = false;
      _errorMessage = null;
      _isProcessing = true;
    });

    try {
      final familyId = widget.task.familyId;
      final notifier =
          ref.read(taskListNotifierProvider(familyId).notifier);

      await notifier.approveTask(
        widget.task.id.value,
        widget.user.id,
        familyId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task approved! Points awarded.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _logger.i('TaskListTile: Task ${widget.task.id} approved');
    } catch (e) {
      _logger.e('TaskListTile: Error approving task: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Failed to approve task';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleReject() async {
    // Show a dialog to get rejection comments
    final comments = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Why are you rejecting this task?'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Add a comment (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    // User cancelled the dialog
    if (comments == null) return;

    _logger.d('TaskListTile: Rejecting task ${widget.task.id}');

    setState(() {
      _isError = false;
      _errorMessage = null;
      _isProcessing = true;
    });

    try {
      final familyId = widget.task.familyId;
      final notifier =
          ref.read(taskListNotifierProvider(familyId).notifier);

      await notifier.rejectTask(widget.task.id.value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task sent back for revision.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      _logger.i('TaskListTile: Task ${widget.task.id} rejected');
    } catch (e) {
      _logger.e('TaskListTile: Error rejecting task: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Failed to reject task';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildActionButtons() {
    if (_isProcessing || widget.isUpdating) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    switch (widget.task.status) {
      case TaskStatus.available:
        return ElevatedButton.icon(
          onPressed: _handleTakeOwnership,
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text('Claim'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );

      case TaskStatus.assigned:
        if (_isAssignedToMe) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _handleMarkComplete,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _handleCantDoIt,
                icon: const Icon(Icons.undo, size: 20),
                tooltip: "Can't do it — return to available",
                color: Colors.orange,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          );
        }
        return const SizedBox.shrink();

      case TaskStatus.pendingApproval:
        if (_isAdmin) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _handleApprove,
                icon: const Icon(Icons.thumb_up, size: 16),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(width: 4),
              OutlinedButton.icon(
                onPressed: _handleReject,
                icon: const Icon(Icons.thumb_down, size: 16),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_top, size: 16, color: Colors.purple),
              SizedBox(width: 4),
              Text(
                'Awaiting\nApproval',
                style: TextStyle(fontSize: 11, color: Colors.purple),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

      case TaskStatus.needsRevision:
        if (_isAssignedToMe) {
          return ElevatedButton.icon(
            onPressed: _handleMarkComplete,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Resubmit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }
        return const Icon(Icons.warning, color: Colors.orange, size: 24);

      case TaskStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green, size: 24);
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 2.0),
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
                const SizedBox(width: 8),
                _buildActionButtons(),
              ],
            ),
            if (_isError) ...[
              const SizedBox(height: 8.0),
              Text(
                _errorMessage ?? 'An error occurred',
                style: const TextStyle(color: Colors.red, fontSize: 12.0),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
