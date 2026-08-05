import '../../entities/task.dart';
import '../../entities/user.dart';

/// Data needed to render the home-screen widget.
class HomeWidgetData {
  final String greeting;
  final int currentStreakDays;
  final List<String> missionTitles;
  final int pendingApprovalCount;

  const HomeWidgetData({
    required this.greeting,
    required this.currentStreakDays,
    required this.missionTitles,
    required this.pendingApprovalCount,
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
  }) {
    final titles = todayTasks.map((t) => t.title).take(3).toList();

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
    );
  }
}
