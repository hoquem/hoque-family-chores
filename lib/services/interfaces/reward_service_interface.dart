import 'package:hoque_family_chores/models/reward.dart';

abstract class RewardServiceInterface {
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
}
