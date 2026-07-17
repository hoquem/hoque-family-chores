// lib/presentation/screens/task_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/status_pill.dart';
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
    // Effort gradient: small/easy → big/challenging, green → amber → orange
    // → red. Reads as increasing effort, stays in the warm family.
    final t = context.tokens;
    switch (difficulty) {
      case TaskDifficulty.easy:
        return t.sprout;
      case TaskDifficulty.medium:
        return t.amberWarn;
      case TaskDifficulty.hard:
        return t.carrot;
      case TaskDifficulty.challenging:
        return t.brick;
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
          SnackBar(
            content: Text('✅ Task claimed!'),
            backgroundColor: context.tokens.sproutDeep,
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
            backgroundColor: context.tokens.brickDeep,
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
          SnackBar(
            content: Text('✅ Task submitted for approval!'),
            backgroundColor: context.tokens.sproutDeep,
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
            backgroundColor: context.tokens.brickDeep,
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
          SnackBar(
            content: Text('✅ Task approved!'),
            backgroundColor: context.tokens.sproutDeep,
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
            backgroundColor: context.tokens.brickDeep,
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
          SnackBar(
            content: Text('Task sent back for revision'),
            backgroundColor: context.tokens.carrotDeep,
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
            backgroundColor: context.tokens.brickDeep,
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
    final isAssignedToMe =
        currentUser != null && task.assignedToId == currentUser.id;
    // Anyone in the family may sign off a chore — except the person who did it.
    // This is the same rule ApproveTaskUseCase enforces and the Tasks list tile
    // shows (_canJudge). The detail screen used to gate on role.isAdmin, so a
    // sibling saw a working Approve button in the list, tapped through to here,
    // and it was gone. Match the tile; the domain layer is the real boundary.
    final canJudge = currentUser != null && !isAssignedToMe;

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
                  // One card carries the task identity: title, status +
                  // difficulty pills, and the points/due-date meta. No more
                  // card-per-section (DESIGN.md: one card groups; dividers
                  // separate).
                  _buildHeader(),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildDescriptionSection(),
                  ],
                  if (task.tags.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildTagsSection(),
                  ],
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildTimelineSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(
                    currentUser: currentUser,
                    canJudge: canJudge,
                    isAssignedToMe: isAssignedToMe,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final t = context.tokens;
    final dateFormat = DateFormat('MMM d, yyyy');
    final bool isOverdue = task.isOverdue;
    final difficultyColor = _difficultyColor(task.difficulty);

    // Points + due date sit inline under the pills, not as twin hero-metric
    // cards. The number is still there, just no longer the loudest thing on
    // the screen.
    final metaStyle = TextStyle(color: t.inkSoft, fontSize: 14);

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
                StatusPill(
                  status: task.status,
                  label: _statusLabel(task.status),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _difficultyIcon(task.difficulty),
                        size: 16,
                        color: difficultyColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.difficulty.displayName,
                        style: TextStyle(
                          color: difficultyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: t.starGold, size: 18),
                const SizedBox(width: 4),
                Text('${task.points.value} pts', style: metaStyle),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  color: isOverdue ? t.brick : t.inkSoft,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(task.dueDate),
                  style: isOverdue
                      ? metaStyle.copyWith(
                          color: t.brick, fontWeight: FontWeight.bold)
                      : metaStyle,
                ),
                if (isOverdue) ...[
                  const SizedBox(width: 6),
                  Text(
                    '· OVERDUE',
                    style: TextStyle(
                      color: t.brick,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// A flat labelled section (no card): icon + title row, then content.
  /// Used for Description, Tags, and Timeline, separated by [Divider]s in
  /// [build]. Keeps the screen to one card total.
  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: t.inkMuted),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return _buildSection(
      icon: Icons.description,
      title: 'Description',
      child: Text(
        task.description,
        style: const TextStyle(fontSize: 15, height: 1.5),
      ),
    );
  }

  Widget _buildTagsSection() {
    return _buildSection(
      icon: Icons.label,
      title: 'Tags',
      child: Wrap(
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
    );
  }

  Widget _buildTimelineSection() {
    final dateTimeFormat = DateFormat('MMM d, yyyy • h:mm a');
    final t = context.tokens;
    return _buildSection(
      icon: Icons.timeline,
      title: 'Timeline',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _timelineRow(
            icon: Icons.add_circle_outline,
            label: 'Created',
            date: dateTimeFormat.format(task.createdAt),
            color: t.inkSoft,
          ),
          if (task.completedAt != null) ...[
            const SizedBox(height: 8),
            _timelineRow(
              icon: Icons.check_circle_outline,
              label: 'Completed',
              date: dateTimeFormat.format(task.completedAt!),
              color: t.sprout,
            ),
          ],
          if (task.recurringPattern != null) ...[
            const SizedBox(height: 8),
            _timelineRow(
              icon: Icons.repeat,
              label: 'Recurring',
              date: task.recurringPattern!,
              color: t.marigold,
            ),
          ],
        ],
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
            style: TextStyle(color: context.tokens.inkMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons({
    required User? currentUser,
    required bool canJudge,
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
              backgroundColor: context.tokens.sproutDeep,
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
              backgroundColor: context.tokens.carrotDeep,
            ),
          ),
        ),
      );
    }

    // Pending approval, and I'm not the one who did it — approve/reject
    if (task.status == TaskStatus.pendingApproval && canJudge) {
      buttons.add(
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _handleApproveTask(currentUser),
                icon: const Icon(Icons.thumb_up),
                label: const Text('Approve'),
                style: FilledButton.styleFrom(
                  backgroundColor: context.tokens.sproutDeep,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _handleRejectTask,
                icon: Icon(Icons.thumb_down, color: context.tokens.brick),
                label: Text('Reject',
                    style: TextStyle(color: context.tokens.brick)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.tokens.brick),
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
            color: context.tokens.sprout.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.tokens.sprout.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: context.tokens.sproutDeep),
              const SizedBox(width: 8),
              Text(
                'Task Completed! 🎉',
                style: TextStyle(
                  color: context.tokens.sproutDeep,
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
