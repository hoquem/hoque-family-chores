import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

class LeaderboardEntry {
  final UserId userId;
  final String userName;
  final String? userPhotoUrl;
  final Points points;
  final int completedTasks;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.points,
    required this.completedTasks,
    required this.rank,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntry &&
        other.userId == userId &&
        other.userName == userName &&
        other.userPhotoUrl == userPhotoUrl &&
        other.points == points &&
        other.completedTasks == completedTasks &&
        other.rank == rank;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        userName.hashCode ^
        userPhotoUrl.hashCode ^
        points.hashCode ^
        completedTasks.hashCode ^
        rank.hashCode;
  }

  @override
  String toString() {
    return 'LeaderboardEntry(userId: $userId, userName: $userName, points: $points, completedTasks: $completedTasks, rank: $rank)';
  }
} 