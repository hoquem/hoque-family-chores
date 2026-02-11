import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

class LeaderboardEntry {
  final UserId userId;
  final String userName;
  final String? userPhotoUrl;
  final Points points;
  final int completedTasks;
  final int rank;
  
  // Weekly competition fields
  final int weeklyStars;
  final int allTimeStars;
  final int questsCompleted;
  final int longestStreak;
  final int currentStreak;
  final int? previousRank;
  final bool hasChampionBadge;

  const LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.points,
    required this.completedTasks,
    required this.rank,
    this.weeklyStars = 0,
    this.allTimeStars = 0,
    this.questsCompleted = 0,
    this.longestStreak = 0,
    this.currentStreak = 0,
    this.previousRank,
    this.hasChampionBadge = false,
  });

  /// Creates a copy of this entry with optional new values.
  LeaderboardEntry copyWith({
    UserId? userId,
    String? userName,
    String? userPhotoUrl,
    Points? points,
    int? completedTasks,
    int? rank,
    int? weeklyStars,
    int? allTimeStars,
    int? questsCompleted,
    int? longestStreak,
    int? currentStreak,
    int? previousRank,
    bool? hasChampionBadge,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      points: points ?? this.points,
      completedTasks: completedTasks ?? this.completedTasks,
      rank: rank ?? this.rank,
      weeklyStars: weeklyStars ?? this.weeklyStars,
      allTimeStars: allTimeStars ?? this.allTimeStars,
      questsCompleted: questsCompleted ?? this.questsCompleted,
      longestStreak: longestStreak ?? this.longestStreak,
      currentStreak: currentStreak ?? this.currentStreak,
      previousRank: previousRank ?? this.previousRank,
      hasChampionBadge: hasChampionBadge ?? this.hasChampionBadge,
    );
  }
  
  /// Check if user is on the podium (top 3)
  bool get isOnPodium => rank >= 1 && rank <= 3;
  
  /// Get rank change indicator
  RankChange get rankChange {
    if (previousRank == null) return RankChange.none;
    if (previousRank! > rank) return RankChange.up;
    if (previousRank! < rank) return RankChange.down;
    return RankChange.same;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntry &&
        other.userId == userId &&
        other.userName == userName &&
        other.userPhotoUrl == userPhotoUrl &&
        other.points == points &&
        other.completedTasks == completedTasks &&
        other.rank == rank &&
        other.weeklyStars == weeklyStars &&
        other.allTimeStars == allTimeStars &&
        other.questsCompleted == questsCompleted &&
        other.longestStreak == longestStreak &&
        other.currentStreak == currentStreak &&
        other.previousRank == previousRank &&
        other.hasChampionBadge == hasChampionBadge;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        userName.hashCode ^
        userPhotoUrl.hashCode ^
        points.hashCode ^
        completedTasks.hashCode ^
        rank.hashCode ^
        weeklyStars.hashCode ^
        allTimeStars.hashCode ^
        questsCompleted.hashCode ^
        longestStreak.hashCode ^
        currentStreak.hashCode ^
        previousRank.hashCode ^
        hasChampionBadge.hashCode;
  }

  @override
  String toString() {
    return 'LeaderboardEntry(userId: $userId, userName: $userName, rank: $rank, weeklyStars: $weeklyStars, allTimeStars: $allTimeStars)';
  }
}

/// Enum for rank change indicators
enum RankChange {
  up,
  down,
  same,
  none;
} 