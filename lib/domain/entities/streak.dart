import 'package:equatable/equatable.dart';
import '../value_objects/user_id.dart';

/// Domain entity representing a user's daily streak
class Streak extends Equatable {
  final UserId userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  final int freezesAvailable;
  final List<int> milestonesAchieved;
  final DateTime updatedAt;

  const Streak({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletedDate,
    required this.freezesAvailable,
    required this.milestonesAchieved,
    required this.updatedAt,
  });

  /// Creates a new streak for a user
  factory Streak.initial(UserId userId) {
    return Streak(
      userId: userId,
      currentStreak: 0,
      longestStreak: 0,
      lastCompletedDate: null,
      freezesAvailable: 0,
      milestonesAchieved: [],
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a copy of this streak with updated fields
  Streak copyWith({
    UserId? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
    int? freezesAvailable,
    List<int>? milestonesAchieved,
    DateTime? updatedAt,
  }) {
    return Streak(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      freezesAvailable: freezesAvailable ?? this.freezesAvailable,
      milestonesAchieved: milestonesAchieved ?? this.milestonesAchieved,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Checks if the user is on fire (30+ days)
  bool get isOnFire => currentStreak >= 30;

  /// Checks if the user has a legendary streak (100+ days)
  bool get isLegendary => currentStreak >= 100;

  /// Checks if the user has an active streak
  bool get hasActiveStreak => currentStreak > 0;

  /// Gets the streak state for UI display
  StreakState get state {
    if (currentStreak == 0) return StreakState.none;
    if (currentStreak >= 100) return StreakState.legendary;
    if (currentStreak >= 30) return StreakState.onFire;
    if (currentStreak >= 7) return StreakState.hot;
    return StreakState.active;
  }

  /// Checks if a milestone was achieved
  bool hasMilestone(int days) => milestonesAchieved.contains(days);

  @override
  List<Object?> get props => [
        userId,
        currentStreak,
        longestStreak,
        lastCompletedDate,
        freezesAvailable,
        milestonesAchieved,
        updatedAt,
      ];
}

/// Enum representing the state of a streak for UI display
enum StreakState {
  none,       // 0 days - grayed out
  active,     // 1-6 days - static orange
  hot,        // 7-29 days - pulse animation
  onFire,     // 30-99 days - glow effect
  legendary,  // 100+ days - rainbow shimmer
}

/// Milestone rewards configuration
class StreakMilestone {
  final int days;
  final String title;
  final int starReward;
  final String badgeIcon;

  const StreakMilestone({
    required this.days,
    required this.title,
    required this.starReward,
    required this.badgeIcon,
  });

  static const bronze = StreakMilestone(
    days: 7,
    title: 'Week Warrior',
    starReward: 50,
    badgeIcon: '🏅',
  );

  static const silver = StreakMilestone(
    days: 30,
    title: 'Monthly Master',
    starReward: 200,
    badgeIcon: '🥈',
  );

  static const gold = StreakMilestone(
    days: 100,
    title: 'Century Legend',
    starReward: 1000,
    badgeIcon: '🏆',
  );

  static const List<StreakMilestone> all = [bronze, silver, gold];

  /// Gets milestone for a specific day count
  static StreakMilestone? forDays(int days) {
    return all.where((m) => m.days == days).firstOrNull;
  }
}
