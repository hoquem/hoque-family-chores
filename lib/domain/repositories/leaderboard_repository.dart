import '../entities/user.dart';
import '../value_objects/family_id.dart';

/// Abstract interface for leaderboard data operations
abstract class LeaderboardRepository {
  /// Get leaderboard entries for a family
  Future<List<User>> getLeaderboard(FamilyId familyId);
} 