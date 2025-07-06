import 'dart:async';
import '../entities/badge.dart';
import '../entities/achievement.dart';
import '../entities/reward.dart';
import '../entities/user.dart';
import '../value_objects/family_id.dart';
import '../value_objects/user_id.dart';
import '../value_objects/points.dart';
import '../../core/error/failures.dart';

/// Abstract interface for gamification data operations
abstract class GamificationRepository {
  /// Badge operations
  Stream<List<Badge>> streamUserBadges(UserId userId);
  Future<void> awardBadge(FamilyId familyId, UserId userId, String badgeId);
  Future<void> revokeBadge(FamilyId familyId, UserId userId, String badgeId);
  Future<List<Badge>> getBadges(FamilyId familyId);
  Future<void> createBadge(FamilyId familyId, Badge badge);
  Future<void> updateBadge(FamilyId familyId, String badgeId, Badge badge);
  Future<void> deleteBadge(FamilyId familyId, String badgeId);

  /// Achievement operations
  Stream<List<Achievement>> streamUserAchievements(UserId userId);
  Future<void> grantAchievement(UserId userId, Achievement achievement);

  /// Reward operations
  Future<List<Reward>> getRewards(FamilyId familyId);
  Future<void> createReward(FamilyId familyId, Reward reward);
  Future<void> updateReward(FamilyId familyId, String rewardId, Reward reward);
  Future<void> deleteReward(FamilyId familyId, String rewardId);
  Future<void> redeemReward(FamilyId familyId, UserId userId, String rewardId);

  /// User profile operations
  Future<void> updateUserPoints(UserId userId, Points points);
  Future<User?> getUserProfile(UserId userId);
  Stream<User?> streamUserProfile(UserId userId);
  Future<void> deleteUserProfile(UserId userId);
  Future<void> createUserProfile(User user);
  Future<void> updateUserProfile(UserId userId, User user);

  /// Initialize user data
  Future<void> initializeUserData(UserId userId, FamilyId familyId);
} 