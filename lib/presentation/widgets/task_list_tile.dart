// lib/presentation/widgets/task_list_tile.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:hoque_family_chores/data/services/photo_storage_service.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/task_details_screen.dart';
import 'package:hoque_family_chores/presentation/motion/snappy_press.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/theme/motion.dart';
import 'package:hoque_family_chores/presentation/widgets/member_display_name.dart';
import 'package:hoque_family_chores/presentation/widgets/status_pill.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import '../utils/task_status_label.dart';
import '../../domain/services/task_actions.dart';

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

  Future<void> _handleTakeOwnership() async {
    _logger.d('TaskListTile: Taking ownership of task ${widget.task.id}');

    setState(() {
      _isError = false;
      _errorMessage = null;
      _isProcessing = true;
    });

    try {
      final familyId = widget.task.familyId;
      // Claim through the notifier the Tasks tab actually watches. The
      // available-tasks notifier isn't loaded on this screen, and its claim
      // path null-checks its own (absent) state — so it threw *after* the
      // claim had already gone through, reporting a false "failed" while the
      // task really had been taken. This path refreshes the visible list via
      // invalidateSelf, matching the details screen and home hub.
      await ref
          .read(taskListNotifierProvider(familyId).notifier)
          .claimTask(widget.task.id.value, widget.user.id, familyId);
      _logger.i(
          'TaskListTile: Successfully took ownership of task ${widget.task.id}');
    } catch (e) {
      _logger.e('TaskListTile: Error taking ownership of task: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = "Couldn't take this one — please try again.";
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

    // A photo-proof task needs its "after" shot before it can be submitted.
    // Captured here rather than at Start for the obvious reason: the work has
    // to happen first. Same rule as Start — no photo, no completion — because
    // a proof task submitted without one gives the parent nothing to judge.
    String? afterPhotoUrl;
    if (widget.task.requiresPhotoProof) {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera);
      if (picked == null) return;

      setState(() {
        _isError = false;
        _errorMessage = null;
        _isProcessing = true;
      });

      final upload = await ref.read(photoStorageServiceProvider).upload(
            photo: File(picked.path),
            familyId: widget.task.familyId,
            taskId: widget.task.id,
            kind: PhotoKind.after,
          );

      final url = upload.fold((failure) {
        setState(() {
          _isError = true;
          _errorMessage = failure.message;
          _isProcessing = false;
        });
        return null;
      }, (url) => url);

      if (url == null) return;
      afterPhotoUrl = url;
    }

    setState(() {
      _isError = false;
      _errorMessage = null;
      _isProcessing = true;
    });

    try {
      final familyId = widget.task.familyId;
      final notifier =
          ref.read(taskListNotifierProvider(familyId).notifier);

      if (afterPhotoUrl != null) {
        // Store the photo before flipping status: a task that reaches the
        // approval queue without its "after" gives the parent nothing to look
        // at, and they cannot tell it is still coming.
        await ref.read(taskRepositoryProvider).setAfterPhoto(
              familyId,
              widget.task.id,
              afterPhotoUrl,
            );
      }

      await notifier.completeTask(
        widget.task.id.value,
        widget.user.id,
        familyId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Sent for a check!'),
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
            content: Text('Chore approved! Stars awarded.'),
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
          title: const Text('Send it back?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Why send it back?'),
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
              child: const Text('Send back'),
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
            content: Text('Sent back to have another go'),
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
  ///
  /// What appears is `taskActionsFor`'s decision; this only dresses it. The
  /// icons for needsRevision and completed are status indicators, not actions —
  /// they show precisely when there is nothing to do.
  Widget? _buildActionButtons() {
    if (_isProcessing || widget.isUpdating) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final actions =
        taskActionsFor(
          task: widget.task,
          viewerId: widget.user.id,
          viewerRole: widget.user.role,
        );

    if (actions.isEmpty) {
      return switch (widget.task.status) {
        TaskStatus.needsRevision => Icon(Icons.warning,
            color: context.tokens.amberWarnDeep, size: 24),
        TaskStatus.completed => Icon(Icons.check_circle,
            color: context.tokens.sproutDeep, size: 24),
        _ => null,
      };
    }

    final widgets = [for (final a in actions) _actionWidget(a)];
    if (widgets.length == 1) return widgets.single;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: widgets,
    );
  }

  /// How one action looks in a list tile: compact, and secondary actions
  /// reduced to an icon so a row of chores stays scannable.
  Widget _actionWidget(TaskAction action) {
    final t = context.tokens;
    // Cream, not Ink, on every *Deep fill: a Deep is dark, so Ink is under
    // 4.5:1 on it.
    ButtonStyle filled(Color background) => ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: t.cream,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        );

    switch (action) {
      case TaskAction.claim:
        return ElevatedButton.icon(
          onPressed: _handleTakeOwnership,
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text("I'll do it!"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: t.ink,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      case TaskAction.start:
        return ElevatedButton.icon(
          onPressed: _handleStart,
          icon: const Icon(Icons.play_circle, size: 16),
          label: const Text('Start'),
          style: filled(t.carrotDeep),
        );
      case TaskAction.complete:
        return ElevatedButton.icon(
          onPressed: _handleMarkComplete,
          icon: const Icon(Icons.check, size: 16),
          label: const Text("I've done it!"),
          style: filled(t.sproutDeep),
        );
      case TaskAction.resubmit:
        return ElevatedButton.icon(
          onPressed: _handleMarkComplete,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Send again'),
          style: filled(t.carrotDeep),
        );
      case TaskAction.handBack:
        return IconButton(
          onPressed: _handleCantDoIt,
          // Not Icons.undo: DESIGN.md:205 gives undo to the needsRevision
          // status pill, and both appear on the same tile once a chore is sent
          // back. Two undos meaning different things is worse than a less
          // obvious glyph.
          icon: const Icon(Icons.assignment_return, size: 20),
          tooltip: "Can't do it — return to available",
          color: t.amberWarn,
        );
      case TaskAction.approve:
        return ElevatedButton.icon(
          onPressed: _handleApprove,
          icon: const Icon(Icons.thumb_up, size: 16),
          label: const Text('Give stars ⭐'),
          style: filled(t.sproutDeep),
        );
      case TaskAction.sendBack:
        return OutlinedButton.icon(
          onPressed: _handleReject,
          icon: const Icon(Icons.thumb_down, size: 16),
          label: const Text('Send back'),
          style: OutlinedButton.styleFrom(
            foregroundColor: t.brick,
            side: BorderSide(color: t.brick),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = widget.task.status == TaskStatus.completed;
    final actions = _buildActionButtons();

    return SnappyPress(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 2.0,
        // The whole card is the tap target for opening the task. Without a label
        // a screen reader reads the contents and leaves the user to infer that
        // the pile of text is also a button.
        child: Semantics(
          button: true,
          label: 'Open chore ${widget.task.title}, ${taskStatusLabel(widget.task.status)}',
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
                              label: taskStatusLabel(widget.task.status),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            '${widget.task.points} ⭐',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: context.tokens.inkSoft,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      _AssigneeLabel(
                        task: widget.task,
                        currentUser: widget.user,
                      ),
                      _CheckedByLabel(
                        task: widget.task,
                        currentUser: widget.user,
                      ),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedSwitcher(
                      duration: context.prefersReducedMotion
                          ? Duration.zero
                          : kMotionDuration,
                      switchInCurve: kMotionCurve,
                      switchOutCurve: kMotionExitCurve,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(widget.task.status),
                        child: actions,
                      ),
                    ),
                  ),
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
      ),
    );
  }
}

/// The "Assigned to: …" line. Resolves the task's real assignee from the family
/// members (not the viewer — that bug made every assigned task read as "you").
/// Renders nothing for an unassigned task.
class _AssigneeLabel extends ConsumerWidget {
  const _AssigneeLabel({required this.task, required this.currentUser});

  final Task task;
  final User currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assigneeId = task.assignedToId;
    if (assigneeId == null) return const SizedBox.shrink();

    final name = memberDisplayName(ref, task.familyId, assigneeId, currentUser);

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        'Assigned to: $name',
        style: TextStyle(fontSize: 14.0, color: context.tokens.inkSoft),
      ),
    );
  }
}

/// The "Checked by: …" line on a completed chore — the transparency half of
/// peer approval: anyone but the doer may sign a chore off, so the family can
/// see who did. Renders nothing when no approver is on record (chores
/// completed before approvedBy existed).
class _CheckedByLabel extends ConsumerWidget {
  const _CheckedByLabel({required this.task, required this.currentUser});

  final Task task;
  final User currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approverId = task.approvedBy;
    if (task.status != TaskStatus.completed || approverId == null) {
      return const SizedBox.shrink();
    }

    final name = memberDisplayName(ref, task.familyId, approverId, currentUser);

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        'Checked by: $name',
        style: TextStyle(fontSize: 14.0, color: context.tokens.inkSoft),
      ),
    );
  }
}
