import 'dart:async';
import '../entities/reward.dart';
import '../value_objects/family_id.dart';
import '../value_objects/user_id.dart';
import '../../core/error/failures.dart';

/// Abstract interface for reward data operations
abstract class RewardRepository {
  /// Get all rewards for a family
  Future<List<Reward>> getRewards(FamilyId familyId);

  /// Create a new reward
  Future<void> createReward(FamilyId familyId, Reward reward);

  /// Update an existing reward
  Future<void> updateReward(FamilyId familyId, String rewardId, Reward reward);

  /// Delete a reward
  Future<void> deleteReward(FamilyId familyId, String rewardId);

  /// Redeem a reward
  Future<void> redeemReward(FamilyId familyId, UserId userId, String rewardId);
} 