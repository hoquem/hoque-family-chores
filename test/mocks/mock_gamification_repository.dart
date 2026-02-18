import 'dart:async';
import '../../domain/repositories/gamification_repository.dart';
import '../../domain/entities/badge.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/reward.dart';
import '../../domain/entities/user.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/points.dart';
import '../../domain/value_objects/email.dart';
import '../../core/error/exceptions.dart';

/// Mock implementation of GamificationRepository for testing
class MockGamificationRepository implements GamificationRepository {
  final List<Badge> _badges = [];
  final List<Achievement> _achievements = [];
  final List<Reward> _rewards = [];
  final List<User> _users = [];
  final Map<String, List<String>> _userBadges = {}; // userId -> badgeIds
  final Map<String, List<String>> _userAchievements = {}; // userId -> achievementIds
  final Map<String, List<String>> _userRedemptions = {}; // userId -> rewardIds
  final StreamController<List<Badge>> _userBadgesStreamController = StreamController<List<Badge>>.broadcast();
  final StreamController<List<Achievement>> _userAchievementsStreamController = StreamController<List<Achievement>>.broadcast();
  final StreamController<User?> _userStreamController = StreamController<User?>.broadcast();

  MockGamificationRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Initialize mock badges
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
    ];

    // Initialize mock achievements
    final mockAchievements = [
      Achievement(
        id: 'achievement_1',
        title: 'First Task',
        description: 'Complete your first task',
        points: Points(10),
        icon: 'first_task',
        type: BadgeType.taskCompletion,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        completedAt: DateTime.now().subtract(const Duration(days: 25)),
        completedBy: 'user_1',
      ),
      Achievement(
        id: 'achievement_2',
        title: 'Task Master',
        description: 'Complete 10 tasks',
        points: Points(50),
        icon: 'task_master',
        type: BadgeType.taskCompletion,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        completedAt: DateTime.now().subtract(const Duration(days: 20)),
        completedBy: 'user_1',
      ),
    ];

    // Initialize mock rewards
    final mockRewards = [
      Reward(
        id: 'reward_1',
        name: 'Extra Screen Time',
        description: '30 minutes of extra screen time',
        pointsCost: Points(50),
        iconEmoji: '📱',
        type: RewardType.privilege,
        familyId: FamilyId('family_1'),
        creatorId: 'user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        rarity: RewardRarity.common,
      ),
      Reward(
        id: 'reward_2',
        name: 'Choose Dinner',
        description: 'Pick what the family eats for dinner',
        pointsCost: Points(100),
        iconEmoji: '🍽️',
        type: RewardType.privilege,
        familyId: FamilyId('family_1'),
        creatorId: 'user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
        rarity: RewardRarity.uncommon,
      ),
    ];

    // Initialize mock users
    final mockUsers = [
      User(
        id: UserId('user_1'),
        name: 'John Doe',
        email: Email('john@example.com'),
        photoUrl: null,
        familyId: FamilyId('family_1'),
        role: UserRole.parent,
        points: Points(150),
        joinedAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: UserId('user_2'),
        name: 'Jane Smith',
        email: Email('jane@example.com'),
        photoUrl: null,
        familyId: FamilyId('family_1'),
        role: UserRole.child,
        points: Points(75),
        joinedAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
      ),
    ];

    _badges.addAll(mockBadges);
    _achievements.addAll(mockAchievements);
    _rewards.addAll(mockRewards);
    _users.addAll(mockUsers);

    // Initialize user data
    _userBadges['user_1'] = ['badge_1'];
    _userBadges['user_2'] = ['badge_1'];
    _userAchievements['user_1'] = ['achievement_1', 'achievement_2'];
    _userAchievements['user_2'] = ['achievement_1'];
    _userRedemptions['user_1'] = ['reward_1'];
    _userRedemptions['user_2'] = [];
  }

  // Badge operations
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

  // Achievement operations
  @override
  Stream<List<Achievement>> streamUserAchievements(UserId userId) {
    return _userAchievementsStreamController.stream
        .where((achievements) => achievements.isNotEmpty);
  }

  @override
  Future<void> grantAchievement(UserId userId, Achievement achievement) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      // Add achievement to user
      if (!_userAchievements.containsKey(userId.value)) {
        _userAchievements[userId.value] = [];
      }
      
      if (!_userAchievements[userId.value]!.contains(achievement.id)) {
        _userAchievements[userId.value]!.add(achievement.id);
        _userAchievementsStreamController.add(_getUserAchievements(userId));
      }
    } catch (e) {
      throw ServerException('Failed to grant achievement: $e', code: 'ACHIEVEMENT_GRANT_ERROR');
    }
  }

  // Reward operations
  @override
  Future<List<Reward>> getRewards(FamilyId familyId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      return _rewards.where((reward) => reward.familyId == familyId).toList();
    } catch (e) {
      throw ServerException('Failed to get rewards: $e', code: 'REWARD_FETCH_ERROR');
    }
  }

  @override
  Future<void> createReward(FamilyId familyId, Reward reward) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      // Check if reward already exists
      final existingReward = _rewards.where((r) => r.id == reward.id).firstOrNull;
      if (existingReward != null) {
        throw ValidationException('Reward already exists', code: 'REWARD_ALREADY_EXISTS');
      }
      
      _rewards.add(reward);
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to create reward: $e', code: 'REWARD_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateReward(FamilyId familyId, String rewardId, Reward reward) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _rewards.indexWhere((r) => r.id == rewardId);
      if (index != -1) {
        _rewards[index] = reward;
      } else {
        throw NotFoundException('Reward not found', code: 'REWARD_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to update reward: $e', code: 'REWARD_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteReward(FamilyId familyId, String rewardId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final initialLength = _rewards.length;
      _rewards.removeWhere((reward) => reward.id == rewardId);
      
      if (_rewards.length == initialLength) {
        throw NotFoundException('Reward not found', code: 'REWARD_NOT_FOUND');
      }
      
      // Remove reward from all user redemptions
      for (final userId in _userRedemptions.keys) {
        _userRedemptions[userId]!.remove(rewardId);
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to delete reward: $e', code: 'REWARD_DELETE_ERROR');
    }
  }

  @override
  Future<void> redeemReward(FamilyId familyId, UserId userId, String rewardId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      // Check if reward exists
      final reward = _rewards.where((r) => r.id == rewardId).firstOrNull;
      if (reward == null) {
        throw NotFoundException('Reward not found', code: 'REWARD_NOT_FOUND');
      }

      // Check if reward is available
      if (!reward.isAvailable) {
        throw ValidationException('Reward is not available', code: 'REWARD_NOT_AVAILABLE');
      }

      // Add redemption record
      if (!_userRedemptions.containsKey(userId.value)) {
        _userRedemptions[userId.value] = [];
      }
      
      if (!_userRedemptions[userId.value]!.contains(rewardId)) {
        _userRedemptions[userId.value]!.add(rewardId);
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to redeem reward: $e', code: 'REWARD_REDEEM_ERROR');
    }
  }

  // User profile operations
  @override
  Future<void> updateUserPoints(UserId userId, Points points) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(
          points: points,
          updatedAt: DateTime.now(),
        );
        _userStreamController.add(_users[index]);
      } else {
        throw NotFoundException('User not found', code: 'USER_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to update user points: $e', code: 'USER_POINTS_UPDATE_ERROR');
    }
  }

  @override
  Future<User?> getUserProfile(UserId userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      return _users.where((user) => user.id == userId).firstOrNull;
    } catch (e) {
      throw ServerException('Failed to get user profile: $e', code: 'USER_FETCH_ERROR');
    }
  }

  @override
  Stream<User?> streamUserProfile(UserId userId) {
    return _userStreamController.stream
        .where((user) => user?.id == userId);
  }

  @override
  Future<void> deleteUserProfile(UserId userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final initialLength = _users.length;
      _users.removeWhere((user) => user.id == userId);
      
      if (_users.length == initialLength) {
        throw NotFoundException('User not found', code: 'USER_NOT_FOUND');
      }
      
      _userStreamController.add(null);
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to delete user profile: $e', code: 'USER_DELETE_ERROR');
    }
  }

  @override
  Future<void> createUserProfile(User user) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      // Check if user already exists
      final existingUser = _users.where((u) => u.id == user.id).firstOrNull;
      if (existingUser != null) {
        throw ValidationException('User already exists', code: 'USER_ALREADY_EXISTS');
      }
      
      _users.add(user);
      _userStreamController.add(user);
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to create user profile: $e', code: 'USER_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateUserProfile(UserId userId, User user) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = user;
        _userStreamController.add(user);
      } else {
        throw NotFoundException('User not found', code: 'USER_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to update user profile: $e', code: 'USER_UPDATE_ERROR');
    }
  }

  @override
  Future<void> initializeUserData(UserId userId, FamilyId familyId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      // Initialize user with default values
      final user = User(
        id: userId,
        name: '',
        email: Email(''),
        photoUrl: null,
        familyId: familyId,
        role: UserRole.child,
        points: Points.zero,
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await createUserProfile(user);
    } catch (e) {
      throw ServerException('Failed to initialize user data: $e', code: 'USER_INIT_ERROR');
    }
  }

  // Helper methods
  List<Badge> _getUserBadges(UserId userId) {
    final badgeIds = _userBadges[userId.value] ?? [];
    return _badges.where((badge) => badgeIds.contains(badge.id)).toList();
  }

  List<Achievement> _getUserAchievements(UserId userId) {
    final achievementIds = _userAchievements[userId.value] ?? [];
    return _achievements.where((achievement) => achievementIds.contains(achievement.id)).toList();
  }

  /// Dispose the stream controllers
  void dispose() {
    _userBadgesStreamController.close();
    _userAchievementsStreamController.close();
    _userStreamController.close();
  }
} 