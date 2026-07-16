// lib/presentation/widgets/task_list_tile.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:hoque_family_chores/data/services/photo_storage_service.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/available_tasks_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/task_details_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/status_pill.dart';
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

  /// Captures the before photo and starts the task.
  ///
  /// No photo, no start. If the child backs out of the camera the task is left
  /// exactly as it was — a started task without a before photo would defeat
  /// the point, and there is no second chance to photograph a mess once it has
  /// been tidied.
  Future<void> _handleStart() async {
    final picked = await ImagePicker().pickImage(
      // Camera only, never the gallery: the gallery turns photo proof into
      // "find any tidy room on this phone", and opens a child's whole camera
      // roll inside a chore app.
      source: ImageSource.camera,
    );
    if (picked == null) return;

    setState(() {
      _isError = false;
      _errorMessage = null;
      _isProcessing = true;
    });

    try {
      final upload = await ref.read(photoStorageServiceProvider).upload(
            photo: File(picked.path),
            familyId: widget.task.familyId,
            taskId: widget.task.id,
            kind: PhotoKind.before,
          );

      await upload.fold(
        (failure) async {
          setState(() {
            _isError = true;
            _errorMessage = failure.message;
          });
        },
        (url) async {
          final result = await ref.read(startTaskUseCaseProvider)(
            taskId: widget.task.id,
            userId: widget.user.id,
            familyId: widget.task.familyId,
            beforePhotoUrl: url,
          );
          result.fold(
            (failure) {
              // The photo uploaded but the task did not start. Say so and
              // leave the status alone rather than half-starting it; the blob
              // is orphaned, which is the accepted trade until retention
              // exists. Never swallow this.
              setState(() {
                _isError = true;
                _errorMessage = failure.message;
              });
            },
            (_) => ref
                .read(taskListNotifierProvider(widget.task.familyId).notifier)
                .refresh(),
          );
        },
      );
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
          SnackBar(
            content: Text('Task submitted for approval!'),
            backgroundColor: context.tokens.sproutDeep,
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
            backgroundColor: context.tokens.brickDeep,
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
          SnackBar(
            content: Text('Task approved! Points awarded.'),
            backgroundColor: context.tokens.sproutDeep,
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
            backgroundColor: context.tokens.brickDeep,
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
                backgroundColor: context.tokens.brickDeep,
                // Cream, not Ink: a *Deep fill is dark, so Ink on it is under 4.5:1.
                foregroundColor: context.tokens.cream,
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
          SnackBar(
            content: Text('Task sent back for revision.'),
            backgroundColor: context.tokens.carrotDeep,
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
            backgroundColor: context.tokens.brickDeep,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// The actions for this task, or null when this status/role has none.
  Widget? _buildActionButtons() {
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
            foregroundColor: context.tokens.ink,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );

      case TaskStatus.assigned:
        if (_isAssignedToMe) {
          // A photo-proof task is STARTED, not completed, from here. Start
          // replaces Done rather than joining it: leaving Done in place would
          // let a child finish without ever taking the before photo, which is
          // the entire point of the feature. The domain guard in
          // CompleteTaskUseCase enforces the same rule, because the UI is not
          // a security boundary.
          final primary = widget.task.requiresPhotoProof
              ? ElevatedButton.icon(
                  onPressed: _handleStart,
                  icon: const Icon(Icons.play_circle, size: 16),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.tokens.carrotDeep,
                    foregroundColor: context.tokens.cream,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: _handleMarkComplete,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.tokens.sproutDeep,
                    // Cream, not Ink: a *Deep fill is dark, so Ink on it is
                    // under 4.5:1.
                    foregroundColor: context.tokens.cream,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                );

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              primary,
              const SizedBox(width: 4),
              IconButton(
                onPressed: _handleCantDoIt,
                icon: const Icon(Icons.undo, size: 20),
                tooltip: "Can't do it — return to available",
                color: context.tokens.amberWarn,
              ),
            ],
          );
        }
        return null;

      case TaskStatus.inProgress:
        // Nothing reaches this state yet; a later task adds Done + "Can't
        // do it" here.
        return null;

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
                  backgroundColor: context.tokens.sproutDeep,
                  // Cream, not Ink: a *Deep fill is dark, so Ink on it is under 4.5:1.
                  foregroundColor: context.tokens.cream,
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
                  foregroundColor: context.tokens.brick,
                  side: BorderSide(color: context.tokens.brick),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          );
        }
        // "Waiting" per DESIGN.md's status table, not "Awaiting Approval":
        // this pill sits in the narrow action column beside the task title,
        // where the longer wording overflows by ~51px on a 390pt phone. The
        // old code reached for a hardcoded '\n' to force two lines; the
        // shorter word is what the design system actually asks for.
        return const StatusPill(
          status: TaskStatus.pendingApproval,
          label: 'Waiting',
        );

      case TaskStatus.needsRevision:
        if (_isAssignedToMe) {
          return ElevatedButton.icon(
            onPressed: _handleMarkComplete,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Resubmit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.tokens.carrotDeep,
              // Cream, not Ink: a *Deep fill is dark, so Ink on it is under 4.5:1.
              foregroundColor: context.tokens.cream,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }
        return Icon(Icons.warning,
            color: context.tokens.amberWarnDeep, size: 24);

      case TaskStatus.completed:
        return Icon(Icons.check_circle,
            color: context.tokens.sproutDeep, size: 24);
    }
  }

  String _getStatusText() {
    switch (widget.task.status) {
      case TaskStatus.available:
        return 'Available';
      case TaskStatus.assigned:
        return 'Assigned';
      case TaskStatus.inProgress:
        return 'In progress';
      case TaskStatus.pendingApproval:
        return 'Pending Approval';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.needsRevision:
        return 'Needs Revision';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = widget.task.status == TaskStatus.completed;
    final actions = _buildActionButtons();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      // The whole card is the tap target for opening the task. Without a label
      // a screen reader reads the contents and leaves the user to infer that
      // the pile of text is also a button.
      child: Semantics(
        button: true,
        label: 'Open task ${widget.task.title}, ${_getStatusText()}',
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
            // Actions sit on their own row below the task, not beside it.
            // Side by side, an Approve + Reject pair left the title column
            // 42.7px on a 390pt phone and the status pill overflowed it by
            // 51px. The whole width belongs to the task; the actions get their
            // own line underneath.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
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
                          color: isCompleted
                              ? context.tokens.inkMuted
                              : context.tokens.ink,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          Flexible(
                            child: StatusPill(
                              status: widget.task.status,
                              label: _getStatusText(),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            '${widget.task.points} pts',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: context.tokens.inkSoft,
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
                            color: context.tokens.inkSoft,
                          ),
                        ),
                      ],
                      if (widget.task.description.isNotEmpty) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          widget.task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: context.tokens.inkSoft),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null) ...[
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              ],
            ),
            if (_isError) ...[
              const SizedBox(height: 8.0),
              Text(
                _errorMessage ?? 'An error occurred',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: context.tokens.brickDeep),
              ),
            ],
          ],
        ),
        ),
      ),
      ),
    );
  }
}
