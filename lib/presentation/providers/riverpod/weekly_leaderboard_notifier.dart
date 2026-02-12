import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/domain/entities/leaderboard_entry.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'dart:async';

part 'weekly_leaderboard_notifier.g.dart';

/// Manages weekly leaderboard data for a family.
/// 
/// This notifier fetches and manages weekly leaderboard entries showing
/// family member rankings based on stars earned this week (Monday-Sunday).
/// 
/// Features:
/// - Weekly star tracking
/// - Podium for top 3
/// - Rank change indicators
/// - Champion badge tracking
/// - Week countdown timer
@riverpod
class WeeklyLeaderboardNotifier extends _$WeeklyLeaderboardNotifier {
  final _logger = AppLogger();
  Timer? _weekTimer;

  @override
  Future<List<LeaderboardEntry>> build(FamilyId familyId) async {
    _logger.d('WeeklyLeaderboardNotifier: Building for family $familyId');
    
    // Start week countdown timer
    _startWeekCountdownTimer();
    
    // Clean up timer when provider is disposed
    ref.onDispose(() {
      _weekTimer?.cancel();
    });
    
    try {
      final getWeeklyLeaderboardUseCase = ref.watch(getWeeklyLeaderboardUseCaseProvider);
      final result = await getWeeklyLeaderboardUseCase.call(familyId: familyId);
      
      return result.fold(
        (failure) => throw Exception(failure.message),
        (entries) {
          _logger.d('WeeklyLeaderboardNotifier: Loaded ${entries.length} entries for weekly leaderboard');
          return entries;
        },
      );
    } catch (e) {
      _logger.e('WeeklyLeaderboardNotifier: Error loading weekly leaderboard', error: e);
      throw Exception('Failed to load weekly leaderboard: $e');
    }
  }

  /// Starts a timer to refresh leaderboard when the week resets
  void _startWeekCountdownTimer() {
    final weekEnd = getWeekEnd();
    final now = DateTime.now();
    final timeUntilReset = weekEnd.difference(now);
    
    if (timeUntilReset.isNegative) {
      // Week already ended, refresh immediately
      Future.microtask(() => refresh());
      return;
    }
    
    // Schedule refresh at week end
    _weekTimer = Timer(timeUntilReset, () {
      _logger.d('WeeklyLeaderboardNotifier: Week reset, refreshing leaderboard');
      refresh();
    });
  }

  /// Refreshes the weekly leaderboard data.
  Future<void> refresh() async {
    _logger.d('WeeklyLeaderboardNotifier: Refreshing weekly leaderboard');
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

  /// Gets the top 3 entries for the podium.
  List<LeaderboardEntry> get podium {
    return entries.take(3).toList();
  }

  /// Gets entries beyond the podium (rank 4+).
  List<LeaderboardEntry> get remainingEntries {
    return entries.length > 3 ? entries.skip(3).toList() : [];
  }

  /// Gets the current week's champion (rank #1).
  LeaderboardEntry? get champion {
    return entries.isNotEmpty ? entries.first : null;
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

  /// Gets the current week start date (Monday at 00:00).
  DateTime getWeekStart() {
    final useCase = ref.read(getWeeklyLeaderboardUseCaseProvider);
    return useCase.getWeekStart();
  }

  /// Gets the current week end date (Sunday at 23:59).
  DateTime getWeekEnd() {
    final useCase = ref.read(getWeeklyLeaderboardUseCaseProvider);
    return useCase.getWeekEnd();
  }

  /// Gets time remaining until week reset.
  Duration getTimeUntilReset() {
    final weekEnd = getWeekEnd();
    final now = DateTime.now();
    return weekEnd.difference(now);
  }

  /// Gets formatted time until reset (e.g., "2d 14h 23m").
  String getFormattedTimeUntilReset() {
    final duration = getTimeUntilReset();
    
    if (duration.isNegative) return '0d 0h 0m';
    
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    
    return '${days}d ${hours}h ${minutes}m';
  }

  /// Gets week progress percentage (0.0 to 1.0).
  double getWeekProgress() {
    final weekStart = getWeekStart();
    final weekEnd = getWeekEnd();
    final now = DateTime.now();
    
    final totalDuration = weekEnd.difference(weekStart).inMilliseconds;
    final elapsedDuration = now.difference(weekStart).inMilliseconds;
    
    if (totalDuration <= 0) return 0.0;
    
    final progress = elapsedDuration / totalDuration;
    return progress.clamp(0.0, 1.0);
  }

  /// Gets the average weekly stars across all members.
  double get averageWeeklyStars {
    if (entries.isEmpty) return 0.0;
    final totalStars = entries.fold<int>(0, (sum, entry) => sum + entry.weeklyStars);
    return totalStars / entries.length;
  }

  /// Gets the total weekly stars across all members.
  int get totalWeeklyStars {
    return entries.fold<int>(0, (sum, entry) => sum + entry.weeklyStars);
  }

  /// Gets entries with rank improvements from last week.
  List<LeaderboardEntry> get improvedRanks {
    return entries.where((entry) => entry.rankChange == RankChange.up).toList();
  }

  /// Gets entries with rank declines from last week.
  List<LeaderboardEntry> get declinedRanks {
    return entries.where((entry) => entry.rankChange == RankChange.down).toList();
  }

  /// Checks if a user has the champion badge.
  bool isChampion(String userId) {
    final entry = getEntryForUser(userId);
    return entry?.hasChampionBadge ?? false;
  }

  /// Gets the week date range as a formatted string (e.g., "Jan 6 - Jan 12").
  String getWeekDateRange() {
    final weekStart = getWeekStart();
    final weekEnd = getWeekEnd();
    
    final monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final startMonth = monthNames[weekStart.month];
    final endMonth = monthNames[weekEnd.month];
    
    if (weekStart.month == weekEnd.month) {
      return '$startMonth ${weekStart.day} - ${weekEnd.day}';
    } else {
      return '$startMonth ${weekStart.day} - $endMonth ${weekEnd.day}';
    }
  }
}

/// Enum for leaderboard state.
enum LeaderboardState { initial, loading, loaded, error }
