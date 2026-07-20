import '../entities/task.dart';
import '../entities/user.dart';
import '../value_objects/user_id.dart';

/// Pure home-screen statistics derived from the already-loaded task list.
///
/// :param now: Every function takes the current time as a parameter so the
///             logic stays deterministic and unit-testable.

/// The user's missions for today, split by what still needs doing.
class TodayMissions {
  /// Still to do (assigned or sent back for revision).
  final List<Task> toDo;

  /// Completed by the user, waiting for a parent's approval.
  final List<Task> waiting;

  /// Approved/completed today.
  final List<Task> done;

  /// Unclaimed family tasks the user could pick up today.
  ///
  /// Shown only when the user has nothing of their own — see
  /// ``TodayMissionsCard``. A child with no missions was otherwise met with a
  /// dead end on the one screen meant to bring them back daily.
  final List<Task> claimable;

  const TodayMissions({
    required this.toDo,
    required this.waiting,
    required this.done,
    this.claimable = const [],
  });

  /// True when the day had missions and none are left to do.
  bool get allDone => toDo.isEmpty && (waiting.isNotEmpty || done.isNotEmpty);
}

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Splits [tasks] into the user's missions for today.
///
/// A mission is a task assigned to [userId] due today or earlier. Completed
/// tasks only count when they were completed today, so old tasks don't
/// linger on the home screen.
TodayMissions todayMissions(List<Task> tasks, UserId userId, DateTime now) {
  final endOfToday = _dayOf(now).add(const Duration(days: 1));
  final today = _dayOf(now);

  final mine = tasks.where(
      (t) => t.assignedToId == userId && t.dueDate.isBefore(endOfToday));

  // Unclaimed work anyone could take. Drawn from every task rather than
  // `mine`, since an available task has no assignee and so never reaches the
  // loop below. Same date window as the rest: offering Friday's chore under
  // "Today's Missions" would be a small lie.
  final claimable = tasks
      .where((t) =>
          t.status == TaskStatus.available &&
          t.assignedToId == null &&
          t.dueDate.isBefore(endOfToday))
      .toList();

  final toDo = <Task>[];
  final waiting = <Task>[];
  final done = <Task>[];
  for (final task in mine) {
    switch (task.status) {
      case TaskStatus.assigned:
      case TaskStatus.inProgress:
      case TaskStatus.needsRevision:
        toDo.add(task);
      case TaskStatus.pendingApproval:
        waiting.add(task);
      case TaskStatus.completed:
        final completedAt = task.completedAt;
        if (completedAt != null && _dayOf(completedAt) == today) {
          done.add(task);
        }
      case TaskStatus.available:
        break; // Not claimed by anyone; not a personal mission.
    }
  }
  return TodayMissions(
    toDo: toDo,
    waiting: waiting,
    done: done,
    claimable: claimable,
  );
}

/// Consecutive days (ending today, or yesterday when today has no
/// approval yet) on which the user had at least one task approved.
///
/// Keyed off approval, not submission: a task counts the day a parent
/// approved it (``approvedAt``), so a streak means "earned stars", matching
/// the balance and the weekly leaderboard. Submitted-but-pending and rejected
/// work do not count.
int streakDays(List<Task> tasks, UserId userId, DateTime now) {
  final completionDays = tasks
      .where((t) =>
          t.assignedToId == userId &&
          t.status == TaskStatus.completed &&
          t.approvedAt != null)
      .map((t) => _dayOf(t.approvedAt!))
      .toSet();

  var day = _dayOf(now);
  // Today isn't over: a missing completion today doesn't break the streak.
  if (!completionDays.contains(day)) {
    day = day.subtract(const Duration(days: 1));
  }

  var streak = 0;
  while (completionDays.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

/// A family member's stars earned this week.
class MemberStars {
  final User member;
  final int stars;

  const MemberStars({required this.member, required this.stars});
}

/// Stars each member earned from tasks approved since Monday 00:00,
/// sorted from most to fewest.
///
/// Counts only approved work, keyed off ``approvedAt`` — the moment stars are
/// actually awarded. Submitted-but-pending and rejected tasks are excluded, so
/// the leaderboard can't disagree with the real star balance.
List<MemberStars> weeklyStars(
    List<Task> tasks, List<User> members, DateTime now) {
  final weekStart =
      _dayOf(now).subtract(Duration(days: now.weekday - DateTime.monday));

  final ranking = members.map((member) {
    final stars = tasks
        .where((t) =>
            t.assignedToId == member.id &&
            t.status == TaskStatus.completed &&
            t.approvedAt != null &&
            !t.approvedAt!.isBefore(weekStart))
        .fold<int>(0, (sum, t) => sum + t.points.value);
    return MemberStars(member: member, stars: stars);
  }).toList()
    ..sort((a, b) => b.stars.compareTo(a.stars));
  return ranking;
}

/// Level for a star balance: 100 stars per level, starting at level 1.
int levelFromPoints(int points) => points ~/ 100 + 1;

/// Progress (0..1) toward the next level.
double levelProgress(int points) => (points % 100) / 100;
