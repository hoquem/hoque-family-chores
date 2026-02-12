import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/entities/reward_redemption.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'rewards_notifier.g.dart';

/// Manages rewards list state
@riverpod
class RewardsNotifier extends _$RewardsNotifier {
  final _logger = AppLogger();

  @override
  Future<List<Reward>> build(FamilyId familyId) async {
    _logger.d('RewardsNotifier: Building for family $familyId');
    
    try {
      final repository = ref.watch(rewardRepositoryProvider);
      return await repository.getActiveRewards(familyId);
    } catch (e) {
      _logger.e('RewardsNotifier: Error loading rewards', error: e);
      throw Exception('Failed to load rewards: $e');
    }
  }

  Future<void> refresh() async {
    _logger.d('RewardsNotifier: Refreshing rewards');
    ref.invalidateSelf();
  }

  Future<void> createReward(Reward reward) async {
    try {
      final repository = ref.watch(rewardRepositoryProvider);
      await repository.createReward(reward.familyId, reward);
      await refresh();
    } catch (e) {
      _logger.e('RewardsNotifier: Error creating reward', error: e);
      rethrow;
    }
  }

  Future<void> updateReward(String rewardId, Reward reward) async {
    try {
      final repository = ref.watch(rewardRepositoryProvider);
      await repository.updateReward(reward.familyId, rewardId, reward);
      await refresh();
    } catch (e) {
      _logger.e('RewardsNotifier: Error updating reward', error: e);
      rethrow;
    }
  }

  Future<void> deleteReward(FamilyId familyId, String rewardId) async {
    try {
      final repository = ref.watch(rewardRepositoryProvider);
      await repository.deleteReward(familyId, rewardId);
      await refresh();
    } catch (e) {
      _logger.e('RewardsNotifier: Error deleting reward', error: e);
      rethrow;
    }
  }
}

/// Manages pending redemptions state
@riverpod
class PendingRedemptionsNotifier extends _$PendingRedemptionsNotifier {
  final _logger = AppLogger();

  @override
  Future<List<RewardRedemption>> build(FamilyId familyId) async {
    _logger.d('PendingRedemptionsNotifier: Building for family $familyId');
    
    try {
      final repository = ref.watch(rewardRepositoryProvider);
      return await repository.getPendingRedemptions(familyId);
    } catch (e) {
      _logger.e('PendingRedemptionsNotifier: Error loading redemptions', error: e);
      throw Exception('Failed to load pending redemptions: $e');
    }
  }

  Future<void> refresh() async {
    _logger.d('PendingRedemptionsNotifier: Refreshing');
    ref.invalidateSelf();
  }

  Future<void> approveRedemption(String redemptionId, UserId approverUserId) async {
    try {
      final repository = ref.watch(rewardRepositoryProvider);
      final familyId = state.value?.first.familyId;
      if (familyId == null) return;
      
      await repository.approveRedemption(familyId, redemptionId, approverUserId);
      await refresh();
    } catch (e) {
      _logger.e('PendingRedemptionsNotifier: Error approving redemption', error: e);
      rethrow;
    }
  }

  Future<void> rejectRedemption(
    String redemptionId,
    UserId approverUserId,
    String? reason,
  ) async {
    try {
      final repository = ref.watch(rewardRepositoryProvider);
      final familyId = state.value?.first.familyId;
      if (familyId == null) return;
      
      await repository.rejectRedemption(familyId, redemptionId, approverUserId, reason);
      await refresh();
    } catch (e) {
      _logger.e('PendingRedemptionsNotifier: Error rejecting redemption', error: e);
      rethrow;
    }
  }
}

/// Manages user redemption history
@riverpod
class UserRedemptionsNotifier extends _$UserRedemptionsNotifier {
  final _logger = AppLogger();

  @override
  Future<List<RewardRedemption>> build(FamilyId familyId, UserId userId) async {
    _logger.d('UserRedemptionsNotifier: Building for user $userId');
    
    try {
      final repository = ref.watch(rewardRepositoryProvider);
      return await repository.getUserRedemptions(familyId, userId);
    } catch (e) {
      _logger.e('UserRedemptionsNotifier: Error loading user redemptions', error: e);
      throw Exception('Failed to load redemption history: $e');
    }
  }

  Future<void> refresh() async {
    _logger.d('UserRedemptionsNotifier: Refreshing');
    ref.invalidateSelf();
  }
}

/// Provider for requesting a reward redemption
@riverpod
Future<RewardRedemption> requestRedemption(
  RequestRedemptionRef ref,
  FamilyId familyId,
  UserId userId,
  String rewardId,
) async {
  final repository = ref.watch(rewardRepositoryProvider);
  return await repository.requestRedemption(familyId, userId, rewardId);
}
