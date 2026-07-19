import '../entities/task.dart';

/// The order the Tasks tab shows chores in.
///
/// Grouped by how much attention a chore still needs, then alphabetically
/// within each group. The groups, top to bottom:
///  0. unclaimed (available) — a free chore nobody has taken, shown first
///  1. claimed / in progress (assigned, inProgress, needsRevision)
///  2. awaiting approval (pendingApproval)
///  3. done (completed) — least actionable, shown last
///
/// Within a group, titles sort alphabetically and case-insensitively, so
/// "wash up" and "Wash up" sit together rather than the lowercase one jumping
/// the list. Newest-first only breaks a title tie.
int _statusRank(TaskStatus status) => switch (status) {
      TaskStatus.available => 0,
      TaskStatus.assigned => 1,
      TaskStatus.inProgress => 1,
      TaskStatus.needsRevision => 1,
      TaskStatus.pendingApproval => 2,
      TaskStatus.completed => 3,
    };

List<Task> tasksForDisplay(List<Task> tasks) {
  final sorted = [...tasks];
  sorted.sort((a, b) {
    final byGroup = _statusRank(a.status).compareTo(_statusRank(b.status));
    if (byGroup != 0) return byGroup;
    final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    if (byTitle != 0) return byTitle;
    return b.createdAt.compareTo(a.createdAt); // newest first, as a tiebreak
  });
  return sorted;
}
