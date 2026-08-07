import '../../entities/task.dart';
import '../../entities/user.dart';

/// Data needed to render the home-screen widget.
class HomeWidgetData {
  final String greeting;
  final int currentStreakDays;
  final List<String> missionTitles;
  final int pendingApprovalCount;

  /// What to show in place of the mission list when [missionTitles] is empty.
  ///
  /// Decided here rather than in the native widgets so iOS and Android cannot
  /// disagree about the same day — they had already drifted once over how their
  /// respective languages split an empty string.
  final String emptyMessage;

  const HomeWidgetData({
    required this.greeting,
    required this.currentStreakDays,
    required this.missionTitles,
    required this.pendingApprovalCount,
    this.emptyMessage = '',
  });
}

/// Builds widget data from domain state.
///
/// Truncates missions to three items, surfaces the current streak, and passes
/// through the pending-approval count. The greeting is always present so the
/// widget never renders an empty headline.
class BuildHomeWidgetDataUseCase {
  const BuildHomeWidgetDataUseCase();

  HomeWidgetData call({
    required User user,
    required List<Task> todayTasks,
    required int streakDays,
    required int pendingApprovals,

    /// Today's missions the user has handed in and that are with a grown-up.
    int missionsWaiting = 0,

    /// Today's missions already approved.
    int missionsDone = 0,
  }) {
    final titles = todayTasks.map((t) => t.title).take(3).toList();

    // "Nothing to do" is not the same as "nothing was ever asked of you".
    // Finishing your chores must not read back as having had none.
    final emptyMessage = (missionsWaiting > 0 || missionsDone > 0)
        ? 'All done for today! 🎉'
        : 'No missions today';

    String greeting;
    if (streakDays > 0) {
      greeting = 'Hi ${user.name}! 🔥 $streakDays-day streak';
    } else {
      greeting = 'Hi ${user.name}!';
    }

    return HomeWidgetData(
      greeting: greeting,
      currentStreakDays: streakDays,
      missionTitles: titles,
      pendingApprovalCount: pendingApprovals,
      emptyMessage: emptyMessage,
    );
  }
}
