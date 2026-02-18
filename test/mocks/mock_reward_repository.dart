import 'dart:async';
import '../../domain/repositories/reward_repository.dart';
import '../../domain/entities/reward.dart';
import '../../domain/entities/reward_redemption.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/points.dart';
import '../../core/error/exceptions.dart';

/// Mock implementation of RewardRepository for testing
class MockRewardRepository implements RewardRepository {
  final List<Reward> _rewards = [];
  final List<RewardRedemption> _redemptions = [];
  final _rewardsController = StreamController<List<Reward>>.broadcast();
  final _redemptionsController = StreamController<List<RewardRedemption>>.broadcast();

  MockRewardRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Create some mock rewards
    final mockRewards = [
      Reward(
        id: 'reward_1',
        name: 'Extra Screen Time',
        description: '30 minutes of extra screen time',
        pointsCost: Points(200),
        iconEmoji: '📱',
        type: RewardType.privilege,
        familyId: FamilyId('family_1'),
        creatorId: 'user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        rarity: RewardRarity.common,
        isActive: true,
        isFeatured: true,
      ),
      Reward(
        id: 'reward_2',
        name: 'Choose Dinner',
        description: 'Pick what the family eats for dinner',
        pointsCost: Points(300),
        iconEmoji: '🍽️',
        type: RewardType.privilege,
        familyId: FamilyId('family_1'),
        creatorId: 'user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
        rarity: RewardRarity.uncommon,
        isActive: true,
      ),
      Reward(
        id: 'reward_3',
        name: 'Pizza Night',
        description: 'Family pizza night with your choice of toppings',
        pointsCost: Points(500),
        iconEmoji: '🍕',
        type: RewardType.privilege,
        familyId: FamilyId('family_1'),
        creatorId: 'user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
        rarity: RewardRarity.rare,
        isActive: true,
        isFeatured: true,
      ),
      Reward(
        id: 'reward_4',
        name: 'Streak Freeze',
        description: 'Protect your streak! Auto-activates if you miss a day',
        pointsCost: Points(200),
        iconEmoji: '🧊',
        type: RewardType.digital,
        familyId: FamilyId('family_1'),
        creatorId: 'user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
        rarity: RewardRarity.uncommon,
        isActive: true,
        isFeatured: true,
      ),
    ];

    _rewards.addAll(mockRewards);
  }

  @override
  Future<List<Reward>> getRewards(FamilyId familyId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _rewards.where((reward) => reward.familyId == familyId).toList();
  }

  @override
  Future<List<Reward>> getActiveRewards(FamilyId familyId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _rewards
        .where((reward) => reward.familyId == familyId && reward.isActive)
        .toList();
  }

  @override
  Future<Reward?> getReward(FamilyId familyId, String rewardId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _rewards.firstWhere(
        (reward) => reward.id == rewardId && reward.familyId == familyId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createReward(FamilyId familyId, Reward reward) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final existingReward = _rewards.where((r) => r.id == reward.id).firstOrNull;
    if (existingReward != null) {
      throw ValidationException('Reward already exists', code: 'REWARD_ALREADY_EXISTS');
    }

    _rewards.add(reward);
    _notifyRewardsChanged(familyId);
  }

  @override
  Future<void> updateReward(FamilyId familyId, String rewardId, Reward reward) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final index = _rewards.indexWhere((r) => r.id == rewardId);
    if (index != -1) {
      _rewards[index] = reward;
      _notifyRewardsChanged(familyId);
    } else {
      throw NotFoundException('Reward not found', code: 'REWARD_NOT_FOUND');
    }
  }

  @override
  Future<void> deleteReward(FamilyId familyId, String rewardId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final index = _rewards.indexWhere((r) => r.id == rewardId);
    if (index != -1) {
      // Soft delete: mark as inactive
      _rewards[index] = _rewards[index].copyWith(isActive: false);
      _notifyRewardsChanged(familyId);
    } else {
      throw NotFoundException('Reward not found', code: 'REWARD_NOT_FOUND');
    }
  }

  @override
  Future<RewardRedemption> requestRedemption(
    FamilyId familyId,
    UserId userId,
    String rewardId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final reward = await getReward(familyId, rewardId);
    if (reward == null) {
      throw NotFoundException('Reward not found', code: 'REWARD_NOT_FOUND');
    }

    if (!reward.isAvailable) {
      throw ValidationException('Reward is not available', code: 'REWARD_NOT_AVAILABLE');
    }

    // Check for existing pending redemption
    final existingPending = _redemptions.where(
      (r) =>
          r.rewardId == rewardId &&
          r.userId == userId &&
          r.status == RedemptionStatus.pending,
    );
    if (existingPending.isNotEmpty) {
      throw ValidationException(
        'You already have a pending request for this reward',
        code: 'REDEMPTION_ALREADY_PENDING',
      );
    }

    final redemption = RewardRedemption(
      id: 'redemption_${DateTime.now().millisecondsSinceEpoch}',
      rewardId: rewardId,
      rewardName: reward.name,
      rewardIconEmoji: reward.iconEmoji,
      starCost: reward.costAsInt,
      userId: userId,
      familyId: familyId,
      status: RedemptionStatus.pending,
      requestedAt: DateTime.now(),
    );

    _redemptions.add(redemption);
    _notifyRedemptionsChanged(familyId);
    return redemption;
  }

  @override
  Future<List<RewardRedemption>> getPendingRedemptions(FamilyId familyId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _redemptions
        .where((r) => r.familyId == familyId && r.status == RedemptionStatus.pending)
        .toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  @override
  Future<List<RewardRedemption>> getUserRedemptions(
    FamilyId familyId,
    UserId userId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _redemptions
        .where((r) => r.familyId == familyId && r.userId == userId)
        .toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  @override
  Future<List<RewardRedemption>> getAllRedemptions(FamilyId familyId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _redemptions.where((r) => r.familyId == familyId).toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  @override
  Future<void> approveRedemption(
    FamilyId familyId,
    String redemptionId,
    UserId approverUserId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final index = _redemptions.indexWhere((r) => r.id == redemptionId);
    if (index == -1) {
      throw NotFoundException('Redemption not found', code: 'REDEMPTION_NOT_FOUND');
    }

    final redemption = _redemptions[index];
    if (redemption.status != RedemptionStatus.pending) {
      throw ValidationException(
        'Redemption is not pending',
        code: 'REDEMPTION_NOT_PENDING',
      );
    }

    _redemptions[index] = redemption.copyWith(
      status: RedemptionStatus.approved,
      processedAt: DateTime.now(),
      processedByUserId: approverUserId.value,
    );

    _notifyRedemptionsChanged(familyId);
  }

  @override
  Future<void> rejectRedemption(
    FamilyId familyId,
    String redemptionId,
    UserId approverUserId,
    String? reason,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final index = _redemptions.indexWhere((r) => r.id == redemptionId);
    if (index == -1) {
      throw NotFoundException('Redemption not found', code: 'REDEMPTION_NOT_FOUND');
    }

    final redemption = _redemptions[index];
    if (redemption.status != RedemptionStatus.pending) {
      throw ValidationException(
        'Redemption is not pending',
        code: 'REDEMPTION_NOT_PENDING',
      );
    }

    _redemptions[index] = redemption.copyWith(
      status: RedemptionStatus.rejected,
      processedAt: DateTime.now(),
      processedByUserId: approverUserId.value,
      rejectionReason: reason,
    );

    _notifyRedemptionsChanged(familyId);
  }

  @override
  Stream<List<Reward>> watchRewards(FamilyId familyId) {
    // Emit initial data
    getActiveRewards(familyId).then((rewards) {
      if (!_rewardsController.isClosed) {
        _rewardsController.add(rewards);
      }
    });
    return _rewardsController.stream;
  }

  @override
  Stream<List<RewardRedemption>> watchPendingRedemptions(FamilyId familyId) {
    // Emit initial data
    getPendingRedemptions(familyId).then((redemptions) {
      if (!_redemptionsController.isClosed) {
        _redemptionsController.add(redemptions);
      }
    });
    return _redemptionsController.stream;
  }

  void _notifyRewardsChanged(FamilyId familyId) {
    getActiveRewards(familyId).then((rewards) {
      if (!_rewardsController.isClosed) {
        _rewardsController.add(rewards);
      }
    });
  }

  void _notifyRedemptionsChanged(FamilyId familyId) {
    getPendingRedemptions(familyId).then((redemptions) {
      if (!_redemptionsController.isClosed) {
        _redemptionsController.add(redemptions);
      }
    });
  }

  void dispose() {
    _rewardsController.close();
    _redemptionsController.close();
  }
}
