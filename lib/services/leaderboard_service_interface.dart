// lib/services/leaderboard_service_interface.dart
import '../models/leaderboard_entry.dart';

abstract class LeaderboardServiceInterface {
  /// Fetches a sorted list of leaderboard entries.
  Future<List<LeaderboardEntry>> getLeaderboard();
}