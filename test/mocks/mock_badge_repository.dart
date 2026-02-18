import 'dart:async';
import '../../domain/repositories/badge_repository.dart';
import '../../domain/entities/badge.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/points.dart';
import '../../core/error/exceptions.dart';

/// Mock implementation of BadgeRepository for testing
class MockBadgeRepository implements BadgeRepository {
  final List<Badge> _badges = [];
  final Map<String, List<String>> _userBadges = {}; // userId -> badgeIds
  final StreamController<List<Badge>> _userBadgesStreamController = StreamController<List<Badge>>.broadcast();

  MockBadgeRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Create some mock badges
    final mockBadges = [
      Badge(
        id: 'badge_1',
        name: 'Task Master',
        description: 'Complete 10 tasks',
        iconName: 'task_master',
        requiredPoints: Points(100),
        type: BadgeType.taskCompletion,
        familyId: FamilyId('family_1'),
        creatorId: 'user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        rarity: BadgeRarity.common,
      ),
      Badge(
        id: 'badge_2',
        name: 'Streak Champion',
        description: 'Complete tasks for 7 days in a row',
        iconName: 'streak_champion',
        requiredPoints: Points(200),
        type: BadgeType.streak,
        familyId: FamilyId('family_1'),
        creatorId: 'user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
        rarity: BadgeRarity.uncommon,
      ),
      Badge(
        id: 'badge_3',
        name: 'Point Collector',
        description: 'Earn 500 points',
        iconName: 'point_collector',
        requiredPoints: Points(500),
        type: BadgeType.points,
        familyId: FamilyId('family_1'),
        creatorId: 'user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
        rarity: BadgeRarity.rare,
      ),
    ];

    _badges.addAll(mockBadges);

    // Initialize user badges
    _userBadges['user_1'] = ['badge_1'];
    _userBadges['user_2'] = ['badge_1', 'badge_2'];
    _userBadges['user_3'] = ['badge_1'];
  }

  @override
  Stream<List<Badge>> streamUserBadges(UserId userId) {
    return _userBadgesStreamController.stream
        .where((badges) => badges.isNotEmpty);
  }

  @override
  Future<void> awardBadge(FamilyId familyId, UserId userId, String badgeId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      // Check if badge exists
      final badge = _badges.where((b) => b.id == badgeId).firstOrNull;
      if (badge == null) {
        throw NotFoundException('Badge not found', code: 'BADGE_NOT_FOUND');
      }

      // Add badge to user
      if (!_userBadges.containsKey(userId.value)) {
        _userBadges[userId.value] = [];
      }
      
      if (!_userBadges[userId.value]!.contains(badgeId)) {
        _userBadges[userId.value]!.add(badgeId);
        _userBadgesStreamController.add(_getUserBadges(userId));
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to award badge: $e', code: 'BADGE_AWARD_ERROR');
    }
  }

  @override
  Future<void> revokeBadge(FamilyId familyId, UserId userId, String badgeId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      if (_userBadges.containsKey(userId.value)) {
        _userBadges[userId.value]!.remove(badgeId);
        _userBadgesStreamController.add(_getUserBadges(userId));
      }
    } catch (e) {
      throw ServerException('Failed to revoke badge: $e', code: 'BADGE_REVOKE_ERROR');
    }
  }

  @override
  Future<List<Badge>> getBadges(FamilyId familyId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      return _badges.where((badge) => badge.familyId == familyId).toList();
    } catch (e) {
      throw ServerException('Failed to get badges: $e', code: 'BADGE_FETCH_ERROR');
    }
  }

  @override
  Future<void> createBadge(FamilyId familyId, Badge badge) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      // Check if badge already exists
      final existingBadge = _badges.where((b) => b.id == badge.id).firstOrNull;
      if (existingBadge != null) {
        throw ValidationException('Badge already exists', code: 'BADGE_ALREADY_EXISTS');
      }
      
      _badges.add(badge);
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to create badge: $e', code: 'BADGE_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateBadge(FamilyId familyId, String badgeId, Badge badge) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _badges.indexWhere((b) => b.id == badgeId);
      if (index != -1) {
        _badges[index] = badge;
      } else {
        throw NotFoundException('Badge not found', code: 'BADGE_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to update badge: $e', code: 'BADGE_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteBadge(FamilyId familyId, String badgeId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final initialLength = _badges.length;
      _badges.removeWhere((badge) => badge.id == badgeId);
      
      if (_badges.length == initialLength) {
        throw NotFoundException('Badge not found', code: 'BADGE_NOT_FOUND');
      }
      
      // Remove badge from all users
      for (final userId in _userBadges.keys) {
        _userBadges[userId]!.remove(badgeId);
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to delete badge: $e', code: 'BADGE_DELETE_ERROR');
    }
  }

  /// Helper method to get user badges
  List<Badge> _getUserBadges(UserId userId) {
    final badgeIds = _userBadges[userId.value] ?? [];
    return _badges.where((badge) => badgeIds.contains(badge.id)).toList();
  }

  /// Dispose the stream controller
  void dispose() {
    _userBadgesStreamController.close();
  }
} 