import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/domain/entities/leaderboard_entry.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/usecases/leaderboard/get_leaderboard_usecase.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'leaderboard_notifier.g.dart';

/// Manages leaderboard data for a family.
/// 
/// This notifier fetches and manages leaderboard entries showing
/// family member rankings based on points and completed tasks.
/// 
/// Example:
/// ```dart
/// final leaderboardAsync = ref.watch(leaderboardNotifierProvider(familyId));
/// final notifier = ref.read(leaderboardNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
@riverpod
class LeaderboardNotifier extends _$LeaderboardNotifier {
  final _logger = AppLogger();

  @override
  Future<List<LeaderboardEntry>> build(FamilyId familyId) async {
    _logger.d('LeaderboardNotifier: Building for family $familyId');
    
    try {
      final getLeaderboardUseCase = ref.watch(getLeaderboardUseCaseProvider);
      final result = await getLeaderboardUseCase.call(familyId: familyId);
      
      return result.fold(
        (failure) => throw Exception(failure.message),
        (users) {
          _logger.d('LeaderboardNotifier: Loaded ${users.length} leaderboard entries');
          // Convert User entities to LeaderboardEntry
          final entries = users.asMap().entries.map((entry) {
            final user = entry.value;
            return LeaderboardEntry(
              userId: user.id,
              userName: user.name,
              userPhotoUrl: user.photoUrl,
              points: user.points,
              completedTasks: 0, // TODO: Get actual completed tasks count
              rank: entry.key + 1,
            );
          }).toList();
          return _sortEntries(entries);
        },
      );
    } catch (e) {
      _logger.e('LeaderboardNotifier: Error loading leaderboard', error: e);
      throw Exception('Failed to load leaderboard: $e');
    }
  }

  /// Sorts leaderboard entries by points (descending) and then by completed tasks (descending).
  List<LeaderboardEntry> _sortEntries(List<LeaderboardEntry> entries) {
    final sortedEntries = List<LeaderboardEntry>.from(entries);
    sortedEntries.sort((a, b) {
      // First sort by points (descending)
      final pointsComparison = b.points.value.compareTo(a.points.value);
      if (pointsComparison != 0) return pointsComparison;
      
      // If points are equal, sort by completed tasks (descending)
      return b.completedTasks.compareTo(a.completedTasks);
    });
    
    // Rebuild entries with correct rank
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      sortedEntries[i] = LeaderboardEntry(
        userId: entry.userId,
        userName: entry.userName,
        userPhotoUrl: entry.userPhotoUrl,
        points: entry.points,
        completedTasks: entry.completedTasks,
        rank: i + 1,
      );
    }
    
    return sortedEntries;
  }

  /// Refreshes the leaderboard data.
  Future<void> refresh() async {
    _logger.d('LeaderboardNotifier: Refreshing leaderboard');
    ref.invalidateSelf();
  }

  /// Gets the current list of leaderboard entries.
  List<LeaderboardEntry> get entries => state.value ?? [];

  /// Gets the current loading state.
  bool get isLoading => state.isLoading;

  /// Gets the current error message.
  String? get errorMessage => state.hasError ? state.error.toString() : null;

  /// Gets the current state status.
  LeaderboardState get status {
    if (state.isLoading) return LeaderboardState.loading;
    if (state.hasError) return LeaderboardState.error;
    return LeaderboardState.loaded;
  }

  /// Gets the top 3 entries.
  List<LeaderboardEntry> get topThree {
    return entries.take(3).toList();
  }

  /// Gets the top 10 entries.
  List<LeaderboardEntry> get topTen {
    return entries.take(10).toList();
  }

  /// Gets entries for a specific user.
  LeaderboardEntry? getEntryForUser(String userId) {
    try {
      return entries.firstWhere((entry) => entry.userId.value == userId);
    } catch (e) {
      return null;
    }
  }

  /// Gets the rank of a specific user.
  int? getRankForUser(String userId) {
    final entry = getEntryForUser(userId);
    return entry?.rank;
  }

  /// Gets entries filtered by minimum points.
  List<LeaderboardEntry> getEntriesWithMinimumPoints(int minPoints) {
    return entries.where((entry) => entry.points.value >= minPoints).toList();
  }

  /// Gets entries filtered by minimum completed tasks.
  List<LeaderboardEntry> getEntriesWithMinimumTasks(int minTasks) {
    return entries.where((entry) => entry.completedTasks >= minTasks).toList();
  }

  /// Gets the average points across all members.
  double get averagePoints {
    if (entries.isEmpty) return 0.0;
    final totalPoints = entries.fold<int>(0, (sum, entry) => sum + entry.points.value);
    return totalPoints / entries.length;
  }

  /// Gets the total points across all members.
  int get totalPoints {
    return entries.fold<int>(0, (sum, entry) => sum + entry.points.value);
  }

  /// Gets the total completed tasks across all members.
  int get totalCompletedTasks {
    return entries.fold<int>(0, (sum, entry) => sum + entry.completedTasks);
  }

  /// Gets the highest points achieved by any member.
  int get highestPoints {
    if (entries.isEmpty) return 0;
    return entries.first.points.value;
  }

  /// Gets the most completed tasks by any member.
  int get mostCompletedTasks {
    if (entries.isEmpty) return 0;
    return entries.map((entry) => entry.completedTasks).reduce((a, b) => a > b ? a : b);
  }

  /// Gets entries for a specific rank range.
  List<LeaderboardEntry> getEntriesInRankRange(int startRank, int endRank) {
    return entries.where((entry) => 
      entry.rank >= startRank && 
      entry.rank <= endRank
    ).toList();
  }

  /// Gets entries that have moved up in rank (for animation purposes).
  List<LeaderboardEntry> getEntriesWithRankImprovement() {
    // This would typically compare with previous state
    // For now, return empty list
    return [];
  }

  /// Gets entries that have moved down in rank (for animation purposes).
  List<LeaderboardEntry> getEntriesWithRankDecline() {
    // This would typically compare with previous state
    // For now, return empty list
    return [];
  }
}

/// Enum for leaderboard state.
enum LeaderboardState { initial, loading, loaded, error } 