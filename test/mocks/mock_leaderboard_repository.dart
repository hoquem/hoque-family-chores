import 'dart:async';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/points.dart';
import '../../core/error/exceptions.dart';

/// Mock implementation of LeaderboardRepository for testing
class MockLeaderboardRepository implements LeaderboardRepository {
  final List<User> _users = [];
  final Map<String, Map<String, dynamic>> _userStats = {};

  MockLeaderboardRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Create some mock users for leaderboard with varied stats
    final mockUsers = [
      User(
        id: UserId('user_1'),
        name: 'Amira',
        email: Email('amira@example.com'),
        photoUrl: null,
        familyId: FamilyId('family_1'),
        role: UserRole.child,
        points: Points(2847),
        joinedAt: DateTime.now().subtract(const Duration(days: 180)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: UserId('user_2'),
        name: 'Omar',
        email: Email('omar@example.com'),
        photoUrl: null,
        familyId: FamilyId('family_1'),
        role: UserRole.child,
        points: Points(2341),
        joinedAt: DateTime.now().subtract(const Duration(days: 175)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: UserId('user_3'),
        name: 'Sara',
        email: Email('sara@example.com'),
        photoUrl: null,
        familyId: FamilyId('family_1'),
        role: UserRole.child,
        points: Points(1987),
        joinedAt: DateTime.now().subtract(const Duration(days: 160)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: UserId('user_4'),
        name: 'Ahmed',
        email: Email('ahmed@example.com'),
        photoUrl: null,
        familyId: FamilyId('family_1'),
        role: UserRole.child,
        points: Points(1654),
        joinedAt: DateTime.now().subtract(const Duration(days: 140)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: UserId('user_5'),
        name: 'Layla',
        email: Email('layla@example.com'),
        photoUrl: null,
        familyId: FamilyId('family_1'),
        role: UserRole.child,
        points: Points(1203),
        joinedAt: DateTime.now().subtract(const Duration(days: 120)),
        updatedAt: DateTime.now(),
      ),
    ];

    _users.addAll(mockUsers);
    
    // Initialize weekly stats
    _userStats['user_1'] = {
      'starsEarnedThisWeek': 127,
      'totalStarsAllTime': 2847,
      'totalQuestsCompleted': 189,
      'longestStreak': 34,
      'currentStreak': 12,
      'lastWeekRank': 1,
      'hasChampionBadge': true,
    };
    
    _userStats['user_2'] = {
      'starsEarnedThisWeek': 98,
      'totalStarsAllTime': 2341,
      'totalQuestsCompleted': 156,
      'longestStreak': 28,
      'currentStreak': 8,
      'lastWeekRank': 3,
      'hasChampionBadge': false,
    };
    
    _userStats['user_3'] = {
      'starsEarnedThisWeek': 85,
      'totalStarsAllTime': 1987,
      'totalQuestsCompleted': 132,
      'longestStreak': 21,
      'currentStreak': 5,
      'lastWeekRank': 2,
      'hasChampionBadge': false,
    };
    
    _userStats['user_4'] = {
      'starsEarnedThisWeek': 62,
      'totalStarsAllTime': 1654,
      'totalQuestsCompleted': 110,
      'longestStreak': 18,
      'currentStreak': 3,
      'lastWeekRank': 4,
      'hasChampionBadge': false,
    };
    
    _userStats['user_5'] = {
      'starsEarnedThisWeek': 45,
      'totalStarsAllTime': 1203,
      'totalQuestsCompleted': 85,
      'longestStreak': 15,
      'currentStreak': 1,
      'lastWeekRank': 5,
      'hasChampionBadge': false,
    };
  }

  @override
  Future<List<User>> getLeaderboard(FamilyId familyId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      // Get users for the specific family and sort by points
      final familyUsers = _users
          .where((user) => user.familyId == familyId)
          .toList()
        ..sort((a, b) => b.points.toInt().compareTo(a.points.toInt()));
      
      return familyUsers;
    } catch (e) {
      throw ServerException('Failed to get leaderboard: $e', code: 'LEADERBOARD_FETCH_ERROR');
    }
  }

  @override
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard(FamilyId familyId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 150)); // Simulate network delay
      
      // Get users for the specific family
      final familyUsers = _users.where((user) => user.familyId == familyId).toList();
      
      // Build leaderboard entries
      final entries = familyUsers.map((user) {
        final stats = _userStats[user.id.value] ?? {};
        
        return LeaderboardEntry(
          userId: user.id,
          userName: user.name,
          userPhotoUrl: user.photoUrl,
          points: user.points,
          completedTasks: stats['totalQuestsCompleted'] as int? ?? 0,
          rank: 0, // Will be assigned after sorting
          weeklyStars: stats['starsEarnedThisWeek'] as int? ?? 0,
          allTimeStars: stats['totalStarsAllTime'] as int? ?? user.points.toInt(),
          questsCompleted: stats['totalQuestsCompleted'] as int? ?? 0,
          longestStreak: stats['longestStreak'] as int? ?? 0,
          currentStreak: stats['currentStreak'] as int? ?? 0,
          previousRank: stats['lastWeekRank'] as int?,
          hasChampionBadge: stats['hasChampionBadge'] as bool? ?? false,
        );
      }).toList();

      // Sort by weekly stars with tiebreaker rules
      entries.sort((a, b) {
        final starComparison = b.weeklyStars.compareTo(a.weeklyStars);
        if (starComparison != 0) return starComparison;
        
        final questComparison = b.questsCompleted.compareTo(a.questsCompleted);
        if (questComparison != 0) return questComparison;
        
        final streakComparison = b.longestStreak.compareTo(a.longestStreak);
        if (streakComparison != 0) return streakComparison;
        
        return a.userName.compareTo(b.userName);
      });

      // Assign ranks
      final rankedEntries = <LeaderboardEntry>[];
      for (var i = 0; i < entries.length; i++) {
        rankedEntries.add(entries[i].copyWith(rank: i + 1));
      }

      return rankedEntries;
    } catch (e) {
      throw ServerException('Failed to get weekly leaderboard: $e', code: 'LEADERBOARD_FETCH_ERROR');
    }
  }

  @override
  Future<List<LeaderboardEntry>> getAllTimeLeaderboard(FamilyId familyId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 150)); // Simulate network delay
      
      // Get users for the specific family
      final familyUsers = _users.where((user) => user.familyId == familyId).toList();
      
      // Build leaderboard entries
      final entries = familyUsers.map((user) {
        final stats = _userStats[user.id.value] ?? {};
        
        return LeaderboardEntry(
          userId: user.id,
          userName: user.name,
          userPhotoUrl: user.photoUrl,
          points: user.points,
          completedTasks: stats['totalQuestsCompleted'] as int? ?? 0,
          rank: 0, // Will be assigned after sorting
          weeklyStars: stats['starsEarnedThisWeek'] as int? ?? 0,
          allTimeStars: stats['totalStarsAllTime'] as int? ?? user.points.toInt(),
          questsCompleted: stats['totalQuestsCompleted'] as int? ?? 0,
          longestStreak: stats['longestStreak'] as int? ?? 0,
          currentStreak: stats['currentStreak'] as int? ?? 0,
          hasChampionBadge: stats['hasChampionBadge'] as bool? ?? false,
        );
      }).toList();

      // Sort by all-time stars descending
      entries.sort((a, b) => b.allTimeStars.compareTo(a.allTimeStars));

      // Assign ranks
      final rankedEntries = <LeaderboardEntry>[];
      for (var i = 0; i < entries.length; i++) {
        rankedEntries.add(entries[i].copyWith(rank: i + 1));
      }

      return rankedEntries;
    } catch (e) {
      throw ServerException('Failed to get all-time leaderboard: $e', code: 'LEADERBOARD_FETCH_ERROR');
    }
  }

  @override
  DateTime getCurrentWeekStart() {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // Monday = 1, Sunday = 7
    
    // Calculate days to subtract to get to Monday
    final daysToMonday = currentWeekday - 1;
    
    // Get Monday at 00:00:00
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysToMonday));
    
    return monday;
  }

  @override
  DateTime getCurrentWeekEnd() {
    final weekStart = getCurrentWeekStart();
    // Sunday at 23:59:59
    return weekStart.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
  }

  /// Helper method to update user points (for testing)
  void updateUserPoints(UserId userId, Points newPoints) {
    final index = _users.indexWhere((user) => user.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(
        points: newPoints,
        updatedAt: DateTime.now(),
      );
    }
  }
  
  /// Helper method to update weekly stars (for testing)
  void updateWeeklyStars(String userId, int stars) {
    if (_userStats.containsKey(userId)) {
      _userStats[userId]!['starsEarnedThisWeek'] = stars;
    }
  }
} 