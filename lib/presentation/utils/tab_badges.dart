import '../../domain/entities/task.dart';
import '../../domain/entities/user.dart';
import '../../domain/services/task_actions.dart';

/// The little red numbers on the tab bar.
class TabBadgeCounts {
  /// Chores tab: work waiting for this person.
  final int chores;

  /// Profile tab: unread notifications.
  final int profile;

  const TabBadgeCounts({required this.chores, required this.profile});

  /// Tab index → count, for [BottomNavBar]. Zeroes are omitted; a badge of 0
  /// is not a badge.
  Map<int, int> get byTabIndex => {
        if (chores > 0) 1: chores,
        if (profile > 0) 4: profile,
      };
}

/// How much needs [viewer]'s attention, per tab.
///
/// Extracted from MainScreen, where it was untested and where a role check was
/// being made by substring-matching a user-facing display string.
///
/// Pinned by `test/presentation/utils/tab_badges_test.dart`.
TabBadgeCounts tabBadgeCounts({
  required User viewer,
  required List<Task> tasks,
  required int unreadNotifications,
}) {
  final isParent =
      viewer.role == UserRole.parent || viewer.role == UserRole.guardian;

  final chores = isParent
      // A parent's job is signing off finished work — but not their own. Asking
      // taskActionsFor rather than re-deriving the rule is what keeps the badge
      // and the buttons from disagreeing: a number here with nothing to tap
      // behind it is worse than no number at all.
      ? tasks
          .where((t) => taskActionsFor(task: t, viewerId: viewer.id)
              .contains(TaskAction.approve))
          .length
      // Everyone else: chores free to take, plus their own live work. Submitted
      // work is deliberately absent — it needs nothing further from the doer.
      : tasks.where((t) {
          final isMine = t.assignedToId == viewer.id;
          return t.status == TaskStatus.available ||
              (isMine &&
                  (t.status == TaskStatus.assigned ||
                      t.status == TaskStatus.inProgress ||
                      t.status == TaskStatus.needsRevision));
        }).length;

  return TabBadgeCounts(chores: chores, profile: unreadNotifications);
}
