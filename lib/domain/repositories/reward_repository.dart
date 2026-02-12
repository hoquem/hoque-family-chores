import 'dart:async';
import '../entities/reward.dart';
import '../entities/reward_redemption.dart';
import '../value_objects/family_id.dart';
import '../value_objects/user_id.dart';

/// Abstract interface for reward data operations
abstract class RewardRepository {
  /// Get all rewards for a family
  Future<List<Reward>> getRewards(FamilyId familyId);

  /// Get active rewards only
  Future<List<Reward>> getActiveRewards(FamilyId familyId);

  /// Get a single reward by ID
  Future<Reward?> getReward(FamilyId familyId, String rewardId);

  /// Create a new reward
  Future<void> createReward(FamilyId familyId, Reward reward);

  /// Update an existing reward
  Future<void> updateReward(FamilyId familyId, String rewardId, Reward reward);

  /// Delete a reward (soft delete)
  Future<void> deleteReward(FamilyId familyId, String rewardId);

  /// Request a reward redemption
  Future<RewardRedemption> requestRedemption(
    FamilyId familyId,
    UserId userId,
    String rewardId,
  );

  /// Get pending redemptions for a family
  Future<List<RewardRedemption>> getPendingRedemptions(FamilyId familyId);

  /// Get redemption history for a user
  Future<List<RewardRedemption>> getUserRedemptions(FamilyId familyId, UserId userId);

  /// Get all redemptions for a family
  Future<List<RewardRedemption>> getAllRedemptions(FamilyId familyId);

  /// Approve a redemption request
  Future<void> approveRedemption(
    FamilyId familyId,
    String redemptionId,
    UserId approverUserId,
  );

  /// Reject a redemption request
  Future<void> rejectRedemption(
    FamilyId familyId,
    String redemptionId,
    UserId approverUserId,
    String? reason,
  );

  /// Stream of active rewards
  Stream<List<Reward>> watchRewards(FamilyId familyId);

  /// Stream of pending redemptions
  Stream<List<RewardRedemption>> watchPendingRedemptions(FamilyId familyId);
} 