import '../entities/user.dart';
import '../entities/leaderboard_entry.dart';
import '../value_objects/family_id.dart';

/// Abstract interface for leaderboard data operations
abstract class LeaderboardRepository {
  /// Get leaderboard entries for a family (all-time)
  Future<List<User>> getLeaderboard(FamilyId familyId);
  
  /// Get weekly leaderboard entries for a family
  /// Returns entries sorted by stars earned this week (Monday-Sunday)
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard(FamilyId familyId);
  
  /// Get all-time statistics leaderboard
  Future<List<LeaderboardEntry>> getAllTimeLeaderboard(FamilyId familyId);
  
  /// Get the current week start date (Monday at 00:00)
  DateTime getCurrentWeekStart();
  
  /// Get the current week end date (Sunday at 23:59)
  DateTime getCurrentWeekEnd();
} 