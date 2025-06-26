import 'dart:async';
import 'package:hoque_family_chores/models/achievement.dart';
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/services/interfaces/gamification_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';

/// Mock implementation of the gamification service for testing
class MockGamificationService implements GamificationServiceInterface {
  final Map<String, List<Badge>> _userBadges = {};
  final Map<String, List<Achievement>> _userAchievements = {};
  final Map<String, List<Reward>> _userRewards = {};
  final Map<String, UserProfile> _userProfiles = {};

  @override
  Future<void> awardBadge({
    required String familyId,
    required String userId,
    required String badgeId,
  }) async {
    await ServiceUtils.handleServiceCall(
      operationName: 'awardBadge',
      context: {'userId': userId, 'badgeId': badgeId, 'familyId': familyId},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        final badge = Badge(
          id: badgeId,
          name: 'Test Badge',
          description: 'A test badge',
          iconName: 'emoji_events',
          requiredPoints: 100,
          type: BadgeType.taskCompletion,
          familyId: familyId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _userBadges.putIfAbsent(userId, () => []).add(badge);
        logger.i('Awarded badge $badgeId to user $userId');
      },
    );
  }

  @override
  Future<void> revokeBadge({
    required String familyId,
    required String userId,
    required String badgeId,
  }) async {
    await ServiceUtils.handleServiceCall(
      operationName: 'revokeBadge',
      context: {'userId': userId, 'badgeId': badgeId, 'familyId': familyId},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        _userBadges[userId]?.removeWhere((b) => b.id == badgeId);
        logger.i('Revoked badge $badgeId from user $userId');
      },
    );
  }

  @override
  Future<List<Badge>> getBadges({required String familyId}) async {
    return ServiceUtils.handleServiceCall(
      operationName: 'getBadges',
      context: {'familyId': familyId},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        return _userBadges.values.expand((badges) => badges).toList();
      },
    );
  }

  @override
  Future<void> createBadge({
    required String familyId,
    required Badge badge,
  }) async {
    await ServiceUtils.handleServiceCall(
      operationName: 'createBadge',
      context: {'familyId': familyId, 'badgeId': badge.id},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        logger.i('Created badge ${badge.id} for family $familyId');
      },
    );
  }

  @override
  Future<void> updateBadge({
    required String familyId,
    required String badgeId,
    required Badge badge,
  }) async {
    await ServiceUtils.handleServiceCall(
      operationName: 'updateBadge',
      context: {'familyId': familyId, 'badgeId': badgeId},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        logger.i('Updated badge $badgeId for family $familyId');
      },
    );
  }

  @override
  Future<void> deleteBadge({
    required String familyId,
    required String badgeId,
  }) async {
    await ServiceUtils.handleServiceCall(
      operationName: 'deleteBadge',
      context: {'familyId': familyId, 'badgeId': badgeId},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        logger.i('Deleted badge $badgeId from family $familyId');
      },
    );
  }

  @override
  Stream<List<Achievement>> streamUserAchievements({required String userId}) {
    return ServiceUtils.handleServiceStream(
      streamName: 'streamUserAchievements',
      context: {'userId': userId},
      stream: () => Stream.value(_userAchievements[userId] ?? []),
    );
  }

  @override
  Future<void> grantAchievement({
    required String userId,
    required Achievement achievement,
  }) async {
    await ServiceUtils.handleServiceCall(
      operationName: 'grantAchievement',
      context: {'userId': userId, 'achievementId': achievement.id},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        _userAchievements.putIfAbsent(userId, () => []).add(achievement);
        logger.i('Granted achievement ${achievement.id} to user $userId');
      },
    );
  }

  @override
  Future<List<Reward>> getRewards({required String familyId}) async {
    return ServiceUtils.handleServiceCall(
      operationName: 'getRewards',
      context: {'familyId': familyId},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        return _userRewards[familyId] ?? [];
      },
    );
  }

  @override
  Future<void> createReward({
    required String familyId,
    required Reward reward,
  }) async {
    await ServiceUtils.handleServiceCall(
      operationName: 'createReward',
      context: {'familyId': familyId, 'rewardId': reward.id},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        _userRewards.putIfAbsent(familyId, () => []).add(reward);
        logger.i('Created reward ${reward.id} for family $familyId');
      },
    );
  }

  @override
  Future<void> updateReward({
    required String familyId,
    required String rewardId,
    required Reward reward,
  }) async {
    await ServiceUtils.handleServiceCall(
      operationName: 'updateReward',
      context: {'familyId': familyId, 'rewardId': rewardId},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        final rewards = _userRewards[familyId] ?? [];
        final index = rewards.indexWhere((r) => r.id == rewardId);
        if (index != -1) {
          rewards[index] = reward;
          _userRewards[familyId] = rewards;
        }
        logger.i('Updated reward $rewardId for family $familyId');
      },
    );
  }

  @override
  Future<void> deleteReward({
    required String familyId,
    required String rewardId,
  }) async {
    await ServiceUtils.handleServiceCall(
      operationName: 'deleteReward',
      context: {'familyId': familyId, 'rewardId': rewardId},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        final rewards = _userRewards[familyId] ?? [];
        rewards.removeWhere((r) => r.id == rewardId);
        _userRewards[familyId] = rewards;
        logger.i('Deleted reward $rewardId from family $familyId');
      },
    );
  }

  @override
  Future<void> redeemReward({
    required String familyId,
    required String userId,
    required String rewardId,
  }) async {
    await ServiceUtils.handleServiceCall(
      operationName: 'redeemReward',
      context: {'familyId': familyId, 'userId': userId, 'rewardId': rewardId},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        logger.i(
          'Redeemed reward $rewardId for user $userId in family $familyId',
        );
      },
    );
  }

  @override
  Future<void> updateUserPoints({
    required String userId,
    required int points,
  }) async {
    await ServiceUtils.handleServiceCall(
      operationName: 'updateUserPoints',
      context: {'userId': userId, 'points': points},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        logger.i('Updated points for user $userId to $points');
      },
    );
  }

  @override
  Future<UserProfile?> getUserProfile({required String userId}) async {
    return ServiceUtils.handleServiceCall(
      operationName: 'getUserProfile',
      context: {'userId': userId},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        return _userProfiles[userId];
      },
    );
  }

  @override
  Stream<UserProfile?> streamUserProfile({required String userId}) {
    return ServiceUtils.handleServiceStream(
      streamName: 'streamUserProfile',
      context: {'userId': userId},
      stream: () => Stream.value(_userProfiles[userId]),
    );
  }

  @override
  Future<void> deleteUserProfile({required String userId}) async {
    await ServiceUtils.handleServiceCall(
      operationName: 'deleteUserProfile',
      context: {'userId': userId},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        _userProfiles.remove(userId);
        logger.i('Deleted profile for user $userId');
      },
    );
  }

  @override
  Future<void> createUserProfile({required UserProfile userProfile}) async {
    await ServiceUtils.handleServiceCall(
      operationName: 'createUserProfile',
      context: {'userId': userProfile.id},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        _userProfiles[userProfile.id] = userProfile;
        logger.i('Created profile for user ${userProfile.id}');
      },
    );
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    required UserProfile userProfile,
  }) async {
    await ServiceUtils.handleServiceCall(
      operationName: 'updateUserProfile',
      context: {'userId': userId},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        _userProfiles[userId] = userProfile;
        logger.i('Updated profile for user $userId');
      },
    );
  }

  @override
  Future<void> initializeUserData({
    required String userId,
    required String familyId,
  }) async {
    await ServiceUtils.handleServiceCall(
      operationName: 'initializeUserData',
      context: {'userId': userId, 'familyId': familyId},
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        logger.i('Initialized data for user $userId in family $familyId');
      },
    );
  }

  @override
  Stream<List<Badge>> streamUserBadges({required String userId}) {
    return ServiceUtils.handleServiceStream(
      streamName: 'streamUserBadges',
      context: {'userId': userId},
      stream: () => Stream.value(_userBadges[userId] ?? []),
    );
  }
}
