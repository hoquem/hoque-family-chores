import '../entities/task.dart';
import '../entities/user.dart';
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
/// Approval is open to any family member except the doer — a family is peers,
/// not a hierarchy, and a sibling checking a sibling's work is the point. Role
/// enters in exactly one place: a parent or guardian may also sign off their
/// own chore.
///
/// That exception is not a hierarchy creeping back in. It is what the Cloud
/// Function has always allowed (the no-self-approval throw binds non-parents
/// only) and what the product decision of 2026-08-10 chose to keep: the app is
/// trust-based, so a parent signing off their own work is a fact to show — the
/// timeline says "their own chore" — rather than an act to forbid. Without it a
/// lone parent could never bank their own work at all, and that timeline note
/// could never appear. TASK-500.
///
/// Role used to be absent from this signature entirely, on the argument that
/// only "did you do it" mattered. That was right about siblings and wrong about
/// parents, and it left this layer disagreeing with the server. Role is
/// **required**, not defaulted, so a caller cannot quietly get child semantics
/// for a parent — which is the bug this whole function exists to prevent. It
/// was written after the list tile checked "not the doer" while the detail
/// screen checked `role.isAdmin`: a sibling saw a working Approve button in the
/// list, tapped through, and found it gone.
///
/// Pinned by `test/domain/services/task_actions_test.dart`.
List<TaskAction> taskActionsFor({
  required Task task,
  required UserId viewerId,
  required UserRole viewerRole,
}) {
  final isMine = task.assignedToId != null && task.assignedToId == viewerId;
  final isAdult =
      viewerRole == UserRole.parent || viewerRole == UserRole.guardian;

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
      // Anyone but the doer, plus a parent or guardian on their own chore.
      // Approve alone in that case: sending your own work back to yourself for
      // another go is something you can simply do, so a button for it is noise.
      //
      // An unassigned chore in this state is bad data; treating it as judgeable
      // is the safe reading, since the Cloud Function re-checks before it pays
      // out.
      if (!isMine) return const [TaskAction.approve, TaskAction.sendBack];
      return isAdult ? const [TaskAction.approve] : const [];

    case TaskStatus.completed:
      return const [];
  }
}
