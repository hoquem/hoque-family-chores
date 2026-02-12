import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/points.dart';
import '../../core/error/exceptions.dart';

/// Firebase implementation of LeaderboardRepository
class FirebaseLeaderboardRepository implements LeaderboardRepository {
  final FirebaseFirestore _firestore;

  FirebaseLeaderboardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<User>> getLeaderboard(FamilyId familyId) async {
    try {
      // Get all users in the family
      final snapshot = await _firestore
          .collection('users')
          .where('familyId', isEqualTo: familyId.value)
          .orderBy('points', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _mapFirestoreToUser(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get leaderboard: $e', code: 'LEADERBOARD_FETCH_ERROR');
    }
  }

  @override
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard(FamilyId familyId) async {
    try {
      // Get all users in the family with their stats
      final snapshot = await _firestore
          .collection('users')
          .where('familyId', isEqualTo: familyId.value)
          .get();

      final entries = snapshot.docs.map((doc) {
        final data = doc.data();
        final stats = data['stats'] as Map<String, dynamic>? ?? {};
        
        return LeaderboardEntry(
          userId: UserId(doc.id),
          userName: data['name'] as String? ?? '',
          userPhotoUrl: data['photoUrl'] as String?,
          points: Points(data['points'] as int? ?? 0),
          completedTasks: data['completedTasks'] as int? ?? 0,
          rank: 0, // Will be assigned after sorting
          weeklyStars: stats['starsEarnedThisWeek'] as int? ?? 0,
          allTimeStars: stats['totalStarsAllTime'] as int? ?? (data['points'] as int? ?? 0),
          questsCompleted: stats['totalQuestsCompleted'] as int? ?? 0,
          longestStreak: stats['longestStreak'] as int? ?? 0,
          currentStreak: stats['currentStreak'] as int? ?? 0,
          previousRank: stats['lastWeekRank'] as int?,
          hasChampionBadge: stats['hasChampionBadge'] as bool? ?? false,
        );
      }).toList();

      // Sort by weekly stars with tiebreaker rules:
      // 1. Most weekly stars
      // 2. Most quests completed this week
      // 3. Longest current streak
      // 4. Alphabetical by name
      entries.sort((a, b) {
        // Primary: weekly stars descending
        final starComparison = b.weeklyStars.compareTo(a.weeklyStars);
        if (starComparison != 0) return starComparison;
        
        // Tiebreaker 1: quests completed descending
        final questComparison = b.questsCompleted.compareTo(a.questsCompleted);
        if (questComparison != 0) return questComparison;
        
        // Tiebreaker 2: longest streak descending
        final streakComparison = b.longestStreak.compareTo(a.longestStreak);
        if (streakComparison != 0) return streakComparison;
        
        // Tiebreaker 3: alphabetical ascending
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
      // Get all users in the family with their all-time stats
      final snapshot = await _firestore
          .collection('users')
          .where('familyId', isEqualTo: familyId.value)
          .get();

      final entries = snapshot.docs.map((doc) {
        final data = doc.data();
        final stats = data['stats'] as Map<String, dynamic>? ?? {};
        
        return LeaderboardEntry(
          userId: UserId(doc.id),
          userName: data['name'] as String? ?? '',
          userPhotoUrl: data['photoUrl'] as String?,
          points: Points(data['points'] as int? ?? 0),
          completedTasks: data['completedTasks'] as int? ?? 0,
          rank: 0, // Will be assigned after sorting
          weeklyStars: stats['starsEarnedThisWeek'] as int? ?? 0,
          allTimeStars: stats['totalStarsAllTime'] as int? ?? (data['points'] as int? ?? 0),
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

  /// Maps Firestore document data to domain User entity
  User _mapFirestoreToUser(Map<String, dynamic> data, String id) {
    return User(
      id: UserId(id),
      name: data['name'] as String? ?? '',
      email: Email(data['email'] as String? ?? ''),
      photoUrl: data['photoUrl'] as String?,
      familyId: FamilyId(data['familyId'] as String? ?? ''),
      role: _mapStringToUserRole(data['role'] as String? ?? 'child'),
      points: Points(data['points'] as int? ?? 0),
      joinedAt: data['joinedAt'] is Timestamp
          ? (data['joinedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['joinedAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Maps string to UserRole enum
  UserRole _mapStringToUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'parent':
        return UserRole.parent;
      case 'child':
        return UserRole.child;
      case 'guardian':
        return UserRole.guardian;
      case 'other':
        return UserRole.other;
      default:
        return UserRole.child;
    }
  }
} 