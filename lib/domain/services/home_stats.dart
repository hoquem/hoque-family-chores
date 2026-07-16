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

  const TodayMissions({
    required this.toDo,
    required this.waiting,
    required this.done,
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

  final toDo = <Task>[];
  final waiting = <Task>[];
  final done = <Task>[];
  for (final task in mine) {
    switch (task.status) {
      case TaskStatus.assigned:
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
  return TodayMissions(toDo: toDo, waiting: waiting, done: done);
}

/// Consecutive days (ending today, or yesterday when today has no
/// completion yet) on which the user completed at least one task.
int streakDays(List<Task> tasks, UserId userId, DateTime now) {
  final completionDays = tasks
      .where((t) => t.assignedToId == userId && t.completedAt != null)
      .map((t) => _dayOf(t.completedAt!))
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

/// Stars each member earned from tasks completed since Monday 00:00,
/// sorted from most to fewest.
List<MemberStars> weeklyStars(
    List<Task> tasks, List<User> members, DateTime now) {
  final weekStart =
      _dayOf(now).subtract(Duration(days: now.weekday - DateTime.monday));

  final ranking = members.map((member) {
    final stars = tasks
        .where((t) =>
            t.assignedToId == member.id &&
            t.completedAt != null &&
            !t.completedAt!.isBefore(weekStart))
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
