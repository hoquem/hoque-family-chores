// lib/presentation/screens/task_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:intl/intl.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  final _logger = AppLogger();
  bool _isLoading = false;

  Task get task => widget.task;

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.available:
        return Colors.blue;
      case TaskStatus.assigned:
        return Colors.orange;
      case TaskStatus.pendingApproval:
        return Colors.purple;
      case TaskStatus.needsRevision:
        return Colors.red;
      case TaskStatus.completed:
        return Colors.green;
    }
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.available:
        return 'Available';
      case TaskStatus.assigned:
        return 'Assigned';
      case TaskStatus.pendingApproval:
        return 'Pending Approval';
      case TaskStatus.needsRevision:
        return 'Needs Revision';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  IconData _difficultyIcon(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Icons.sentiment_satisfied;
      case TaskDifficulty.medium:
        return Icons.sentiment_neutral;
      case TaskDifficulty.hard:
        return Icons.sentiment_dissatisfied;
      case TaskDifficulty.challenging:
        return Icons.whatshot;
    }
  }

  Color _difficultyColor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Colors.green;
      case TaskDifficulty.medium:
        return Colors.orange;
      case TaskDifficulty.hard:
        return Colors.deepOrange;
      case TaskDifficulty.challenging:
        return Colors.red;
    }
  }

  Future<void> _handleClaimTask(User currentUser) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(taskListNotifierProvider(task.familyId).notifier)
          .claimTask(task.id.value, currentUser.id, task.familyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Task claimed!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate change
      }
    } catch (e) {
      _logger.e('Error claiming task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCompleteTask(User currentUser) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(taskListNotifierProvider(task.familyId).notifier)
          .completeTask(task.id.value, currentUser.id, task.familyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Task submitted for approval!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _logger.e('Error completing task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApproveTask(User currentUser) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(taskListNotifierProvider(task.familyId).notifier)
          .approveTask(task.id.value, currentUser.id, task.familyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Task approved!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _logger.e('Error approving task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRejectTask() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Task'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Reason for rejection (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason == null) return; // User cancelled

    setState(() => _isLoading = true);
    try {
      await ref
          .read(taskListNotifierProvider(task.familyId).notifier)
          .rejectTask(task.id.value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task sent back for revision'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _logger.e('Error rejecting task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;
    final isAdmin = currentUser?.role.isAdmin ?? false;
    final isAssignedToMe =
        currentUser != null && task.assignedToId == currentUser.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Status Header
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Info Cards
                  _buildInfoCards(),
                  const SizedBox(height: 24),

                  // Description
                  _buildDescriptionSection(),
                  const SizedBox(height: 24),

                  // Tags
                  if (task.tags.isNotEmpty) ...[
                    _buildTagsSection(),
                    const SizedBox(height: 24),
                  ],

                  // Timeline
                  _buildTimelineSection(),
                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(
                    currentUser: currentUser,
                    isAdmin: isAdmin,
                    isAssignedToMe: isAssignedToMe,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(task.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            _statusColor(task.status).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: _statusColor(task.status),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _statusLabel(task.status),
                        style: TextStyle(
                          color: _statusColor(task.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _difficultyColor(task.difficulty)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _difficultyIcon(task.difficulty),
                        size: 16,
                        color: _difficultyColor(task.difficulty),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.difficulty.displayName,
                        style: TextStyle(
                          color: _difficultyColor(task.difficulty),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    final dateFormat = DateFormat('MMM d, yyyy');
    final bool isOverdue = task.isOverdue;

    return Row(
      children: [
        // Points Card
        Expanded(
          child: Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '${task.points.value}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Points',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Due Date Card
        Expanded(
          child: Card(
            color: isOverdue ? Colors.red.shade50 : Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: isOverdue ? Colors.red : Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateFormat.format(task.dueDate),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? Colors.red : null,
                    ),
                  ),
                  Text(
                    isOverdue ? 'OVERDUE' : 'Due Date',
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.grey,
                      fontWeight: isOverdue ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.description.isEmpty
                  ? 'No description provided.'
                  : task.description,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: task.description.isEmpty ? Colors.grey : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.label, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: task.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.5),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    final dateTimeFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Timeline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _timelineRow(
              icon: Icons.add_circle_outline,
              label: 'Created',
              date: dateTimeFormat.format(task.createdAt),
              color: Colors.blue,
            ),
            if (task.completedAt != null) ...[
              const SizedBox(height: 8),
              _timelineRow(
                icon: Icons.check_circle_outline,
                label: 'Completed',
                date: dateTimeFormat.format(task.completedAt!),
                color: Colors.green,
              ),
            ],
            if (task.recurringPattern != null) ...[
              const SizedBox(height: 8),
              _timelineRow(
                icon: Icons.repeat,
                label: 'Recurring',
                date: task.recurringPattern!,
                color: Colors.purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timelineRow({
    required IconData icon,
    required String label,
    required String date,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            date,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons({
    required User? currentUser,
    required bool isAdmin,
    required bool isAssignedToMe,
  }) {
    if (currentUser == null) return const SizedBox.shrink();

    final buttons = <Widget>[];

    // Available task — anyone can claim
    if (task.status == TaskStatus.available) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _handleClaimTask(currentUser),
            icon: const Icon(Icons.add_task),
            label: const Text('Claim This Task'),
          ),
        ),
      );
    }

    // Assigned to me — I can mark as done
    if (task.status == TaskStatus.assigned && isAssignedToMe) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _handleCompleteTask(currentUser),
            icon: const Icon(Icons.check),
            label: const Text('Mark as Done'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ),
      );
    }

    // Needs revision & assigned to me — resubmit
    if (task.status == TaskStatus.needsRevision && isAssignedToMe) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _handleCompleteTask(currentUser),
            icon: const Icon(Icons.refresh),
            label: const Text('Resubmit for Approval'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        ),
      );
    }

    // Pending approval & admin — approve/reject
    if (task.status == TaskStatus.pendingApproval && isAdmin) {
      buttons.add(
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _handleApproveTask(currentUser),
                icon: const Icon(Icons.thumb_up),
                label: const Text('Approve'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _handleRejectTask,
                icon: const Icon(Icons.thumb_down, color: Colors.red),
                label: const Text('Reject',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Completed task — show completion message
    if (task.status == TaskStatus.completed) {
      buttons.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Task Completed! 🎉',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Column(
      children: buttons
          .expand((btn) => [btn, const SizedBox(height: 12)])
          .toList()
        ..removeLast(),
    );
  }
}
