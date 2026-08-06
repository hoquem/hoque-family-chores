import '../entities/task.dart';
import '../value_objects/user_id.dart';

/// Something a family member can do to a chore.
///
/// Deliberately not a widget, an icon or a label — those differ between the
/// Tasks list and the task-details screen, and always will. This is the
/// decision; the wording and styling belong to whoever renders it.
enum TaskAction {
  /// Take an unclaimed chore ("I'll do it!").
  claim,

  /// Begin a photo-proof chore by taking the before photo.
  start,

  /// Submit the chore for sign-off ("I've done it!").
  complete,

  /// Submit again after it was sent back ("Send again").
  resubmit,

  /// Return a chore I claimed to the pool ("Give it back").
  handBack,

  /// Sign off someone else's finished chore and release the stars.
  approve,

  /// Send someone else's finished chore back for another go.
  sendBack,
}

/// The actions [viewerId] may take on [task], in the order they should appear.
///
/// Empty when this combination of state and viewer offers nothing — a chore
/// someone else is doing, an approved chore, or a chore you created yourself
/// and therefore cannot claim.
///
/// **This is not a security boundary.** The Cloud Functions and
/// `firestore.rules` are the real guard; a button hidden here is a courtesy,
/// not a lock. It exists so the two screens cannot drift apart again, and so
/// the rules can be read and tested without building a widget.
///
/// Role is deliberately absent from the signature. Approval is open to any
/// family member except the doer — a family is peers, not a hierarchy — so the
/// only thing that matters is whether the viewer did the work.
///
/// Pinned by `test/domain/services/task_actions_test.dart`.
List<TaskAction> taskActionsFor({
  required Task task,
  required UserId viewerId,
}) {
  final isMine = task.assignedToId != null && task.assignedToId == viewerId;

  switch (task.status) {
    case TaskStatus.available:
      // You cannot claim a chore you created yourself; a parent assigns it.
      // Otherwise one person could create, claim, do and bank it alone.
      return task.createdById == viewerId ? const [] : const [TaskAction.claim];

    case TaskStatus.assigned:
      if (!isMine) return const [];
      // Start replaces complete for a photo-proof chore rather than joining
      // it — offering both would let the before photo be skipped entirely.
      return [
        task.requiresPhotoProof ? TaskAction.start : TaskAction.complete,
        TaskAction.handBack,
      ];

    case TaskStatus.inProgress:
      if (!isMine) return const [];
      return const [TaskAction.complete, TaskAction.handBack];

    case TaskStatus.needsRevision:
      if (!isMine) return const [];
      return const [TaskAction.resubmit, TaskAction.handBack];

    case TaskStatus.pendingApproval:
      // Anyone but the doer. An unassigned chore in this state is bad data;
      // treating it as judgeable is the safe reading, since the Cloud Function
      // re-checks before it pays out.
      return isMine
          ? const []
          : const [TaskAction.approve, TaskAction.sendBack];

    case TaskStatus.completed:
      return const [];
  }
}
