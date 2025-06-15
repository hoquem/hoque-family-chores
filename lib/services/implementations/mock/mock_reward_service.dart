import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/services/interfaces/reward_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class MockRewardService implements RewardServiceInterface {
  final List<Reward> _rewards = [];
  final Map<String, List<String>> _redeemedRewards = {};

  MockRewardService() {
    logger.i("MockRewardService initialized with empty rewards list.");
  }

  @override
  Stream<List<Reward>> streamRewards({required String familyId}) {
    return ServiceUtils.handleServiceStream(
      stream: () async* {
        await Future.delayed(const Duration(milliseconds: 300));
        yield _rewards;
      },
      streamName: 'streamRewards',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<List<Reward>> getRewards({required String familyId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        return _rewards;
      },
      operationName: 'getRewards',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<void> createReward({
    required String familyId,
    required Reward reward,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _rewards.add(reward);
      },
      operationName: 'createReward',
      context: {'familyId': familyId, 'rewardId': reward.id},
    );
  }

  @override
  Future<void> updateReward({
    required String familyId,
    required String rewardId,
    required Reward reward,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        final index = _rewards.indexWhere((r) => r.id == rewardId);
        if (index != -1) {
          _rewards[index] = reward;
        }
      },
      operationName: 'updateReward',
      context: {'familyId': familyId, 'rewardId': rewardId},
    );
  }

  @override
  Future<void> deleteReward({
    required String familyId,
    required String rewardId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _rewards.removeWhere((r) => r.id == rewardId);
        // Remove reward from all users' redeemed rewards
        for (final userId in _redeemedRewards.keys) {
          _redeemedRewards[userId]?.remove(rewardId);
        }
      },
      operationName: 'deleteReward',
      context: {'familyId': familyId, 'rewardId': rewardId},
    );
  }

  @override
  Future<void> redeemReward({
    required String familyId,
    required String rewardId,
    required String userId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!_redeemedRewards.containsKey(userId)) {
          _redeemedRewards[userId] = [];
        }
        if (!_redeemedRewards[userId]!.contains(rewardId)) {
          _redeemedRewards[userId]!.add(rewardId);
        }
      },
      operationName: 'redeemReward',
      context: {'familyId': familyId, 'rewardId': rewardId, 'userId': userId},
    );
  }
}
