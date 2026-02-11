import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/domain/entities/leaderboard_entry.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'alltime_leaderboard_notifier.g.dart';

/// Manages all-time leaderboard data for a family.
/// 
/// This notifier fetches and manages all-time leaderboard entries showing
/// family member lifetime statistics: total stars, quests completed, longest streak.
@riverpod
class AllTimeLeaderboardNotifier extends _$AllTimeLeaderboardNotifier {
  final _logger = AppLogger();

  @override
  Future<List<LeaderboardEntry>> build(FamilyId familyId) async {
    _logger.d('AllTimeLeaderboardNotifier: Building for family $familyId');
    
    try {
      final getAllTimeLeaderboardUseCase = ref.watch(getAllTimeLeaderboardUseCaseProvider);
      final result = await getAllTimeLeaderboardUseCase.call(familyId: familyId);
      
      return result.fold(
        (failure) => throw Exception(failure.message),
        (entries) {
          _logger.d('AllTimeLeaderboardNotifier: Loaded ${entries.length} entries for all-time leaderboard');
          return entries;
        },
      );
    } catch (e) {
      _logger.e('AllTimeLeaderboardNotifier: Error loading all-time leaderboard', error: e);
      throw Exception('Failed to load all-time leaderboard: $e');
    }
  }

  /// Refreshes the all-time leaderboard data.
  Future<void> refresh() async {
    _logger.d('AllTimeLeaderboardNotifier: Refreshing all-time leaderboard');
    ref.invalidateSelf();
  }

  /// Gets the current list of leaderboard entries.
  List<LeaderboardEntry> get entries => state.value ?? [];

  /// Gets the current loading state.
  bool get isLoading => state.isLoading;

  /// Gets the current error message.
  String? get errorMessage => state.hasError ? state.error.toString() : null;

  /// Gets entries for a specific user.
  LeaderboardEntry? getEntryForUser(String userId) {
    try {
      return entries.firstWhere((entry) => entry.userId.value == userId);
    } catch (e) {
      return null;
    }
  }

  /// Gets the all-time champion (most total stars).
  LeaderboardEntry? get allTimeChampion {
    return entries.isNotEmpty ? entries.first : null;
  }

  /// Gets the highest all-time stars achieved.
  int get highestAllTimeStars {
    if (entries.isEmpty) return 0;
    return entries.first.allTimeStars;
  }

  /// Gets the most quests completed by any member.
  int get mostQuestsCompleted {
    if (entries.isEmpty) return 0;
    return entries.map((entry) => entry.questsCompleted).reduce((a, b) => a > b ? a : b);
  }

  /// Gets the longest streak achieved by any member.
  int get longestStreakAchieved {
    if (entries.isEmpty) return 0;
    return entries.map((entry) => entry.longestStreak).reduce((a, b) => a > b ? a : b);
  }

  /// Gets the total all-time stars across all members.
  int get totalAllTimeStars {
    return entries.fold<int>(0, (sum, entry) => sum + entry.allTimeStars);
  }

  /// Gets the total quests completed across all members.
  int get totalQuestsCompleted {
    return entries.fold<int>(0, (sum, entry) => sum + entry.questsCompleted);
  }
}
