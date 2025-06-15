import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/achievement.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/models/user_profile.dart';

abstract class GamificationServiceInterface {
  // Badge related methods
  Stream<List<Badge>> streamUserBadges({required String userId});
  Future<void> awardBadge({
    required String familyId,
    required String userId,
    required String badgeId,
  });
  Future<void> revokeBadge({
    required String familyId,
    required String userId,
    required String badgeId,
  });
  Future<List<Badge>> getBadges({required String familyId});
  Future<void> createBadge({required String familyId, required Badge badge});
  Future<void> updateBadge({
    required String familyId,
    required String badgeId,
    required Badge badge,
  });
  Future<void> deleteBadge({required String familyId, required String badgeId});

  // Achievement related methods
  Stream<List<Achievement>> streamUserAchievements({required String userId});
  Future<void> grantAchievement({
    required String userId,
    required Achievement achievement,
  });

  // Reward methods
  Future<List<Reward>> getRewards({required String familyId});
  Future<void> createReward({required String familyId, required Reward reward});
  Future<void> updateReward({
    required String familyId,
    required String rewardId,
    required Reward reward,
  });
  Future<void> deleteReward({
    required String familyId,
    required String rewardId,
  });
  Future<void> redeemReward({
    required String familyId,
    required String userId,
    required String rewardId,
  });

  // User Profile methods
  Future<void> updateUserPoints({required String userId, required int points});
  Future<UserProfile?> getUserProfile({required String userId});
  Stream<UserProfile?> streamUserProfile({required String userId});
  Future<void> deleteUserProfile({required String userId});
  Future<void> createUserProfile({required UserProfile userProfile});
  Future<void> updateUserProfile({
    required String userId,
    required UserProfile userProfile,
  });

  // Initialization methods
  Future<void> initializeUserData({
    required String userId,
    required String familyId,
  });
}
