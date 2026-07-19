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

  /// Claims a reward: deducts the stars and records the redemption, server-side
  /// (Cloud Function), so it can never spend stars the claimant doesn't have.
  /// Returns the new redemption's id.
  Future<String> claimReward(FamilyId familyId, String rewardId);

  /// Settles a claim (fulfilled or refunded) server-side. A refund returns the
  /// stars. Only the claimant may settle their own claim.
  Future<void> settleRedemption(
    FamilyId familyId,
    String redemptionId, {
    required bool happened,
  });

  /// Outstanding claims for one person — what the family still owes them.
  Future<List<Redemption>> outstandingFor(FamilyId familyId, UserId userId);
}
