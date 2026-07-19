import '../entities/redemption.dart';
import '../entities/reward.dart';
import '../value_objects/family_id.dart';
import '../value_objects/user_id.dart';

/// Rewards a family offers, and the claims made against them.
abstract class RewardRepository {
  /// Every reward this family offers.
  Stream<List<Reward>> streamRewards(FamilyId familyId);

  /// Creates a reward. Anyone in the family may.
  Future<Reward> createReward(Reward reward);

  /// Updates a reward's editable fields (title, cost, timeframe). Existing
  /// claims are untouched — they carry their own copy of the title and cost.
  Future<void> updateReward(Reward reward);

  /// Removes a reward from the list.
  ///
  /// Existing claims are untouched: they carry their own copy of the title and
  /// cost, so a promise already made survives the reward being withdrawn.
  Future<void> deleteReward(FamilyId familyId, String rewardId);

  /// Claims made by this family, newest first.
  Stream<List<Redemption>> streamRedemptions(FamilyId familyId);

  /// Records a claim. The caller has already taken the stars.
  Future<Redemption> createRedemption(Redemption redemption);

  /// Marks a claim fulfilled or refunded.
  Future<void> settleRedemption(
    FamilyId familyId,
    String redemptionId,
    RedemptionStatus outcome,
    DateTime settledAt,
  );

  /// Outstanding claims for one person — what the family still owes them.
  Future<List<Redemption>> outstandingFor(FamilyId familyId, UserId userId);
}
