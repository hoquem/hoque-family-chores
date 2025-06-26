import 'package:hoque_family_chores/models/leaderboard_entry.dart';

abstract class LeaderboardServiceInterface {
  Stream<List<LeaderboardEntry>> streamLeaderboard({required String familyId});

  Future<void> updateLeaderboardEntry({
    required String familyId,
    required LeaderboardEntry entry,
  });

  Future<List<LeaderboardEntry>> getLeaderboard({required String familyId});

  Future<LeaderboardEntry?> getLeaderboardEntry({
    required String familyId,
    required String memberId,
  });
}
