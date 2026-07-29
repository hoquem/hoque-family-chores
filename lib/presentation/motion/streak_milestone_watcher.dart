import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';

part 'streak_milestone_watcher.g.dart';

const Set<int> kStreakMilestones = {3, 7, 14, 30, 50, 100};

/// Session-scoped streak milestone detector. Home reports the live streak
/// (it already computes it from the task stream); crossing INTO a milestone
/// during the session celebrates once. The first report is the baseline
/// (spec §2) — launching the app on day 7 must not celebrate day 7.
@Riverpod(keepAlive: true)
class StreakMilestoneWatcher extends _$StreakMilestoneWatcher {
  int? _last;

  @override
  void build() {}

  void report(int streakDays) {
    final previous = _last;
    _last = streakDays;
    if (previous == null) return; // baseline
    if (streakDays > previous && kStreakMilestones.contains(streakDays)) {
      // Deferred: report() is called from HomeScreen.build, and mutating a
      // provider during build throws. A microtask lands after this frame's
      // build phase.
      Future.microtask(() => ref
          .read(celebrationQueueProvider.notifier)
          .celebrate(StreakMilestone(streakDays)));
    }
  }
}
