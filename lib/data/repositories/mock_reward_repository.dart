import 'dart:async';
import '../../domain/repositories/reward_repository.dart';
import '../../domain/entities/reward.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/points.dart';
import '../../core/error/exceptions.dart';

/// Mock implementation of RewardRepository for testing
class MockRewardRepository implements RewardRepository {
  final List<Reward> _rewards = [];
  final Map<String, List<String>> _userRedemptions = {}; // userId -> rewardIds

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
        pointsCost: Points(50),
        iconName: 'screen_time',
        type: RewardType.privilege,
        familyId: FamilyId('family_1'),
        creatorId: 'user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        rarity: RewardRarity.common,
      ),
      Reward(
        id: 'reward_2',
        name: 'Choose Dinner',
        description: 'Pick what the family eats for dinner',
        pointsCost: Points(100),
        iconName: 'dinner_choice',
        type: RewardType.privilege,
        familyId: FamilyId('family_1'),
        creatorId: 'user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
        rarity: RewardRarity.uncommon,
      ),
      Reward(
        id: 'reward_3',
        name: 'New Toy',
        description: 'A small toy of your choice',
        pointsCost: Points(200),
        iconName: 'toy',
        type: RewardType.physical,
        familyId: FamilyId('family_1'),
        creatorId: 'user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
        rarity: RewardRarity.rare,
      ),
    ];

    _rewards.addAll(mockRewards);

    // Initialize user redemptions
    _userRedemptions['user_1'] = ['reward_1'];
    _userRedemptions['user_2'] = ['reward_1', 'reward_2'];
    _userRedemptions['user_3'] = [];
  }

  @override
  Future<List<Reward>> getRewards(FamilyId familyId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      return _rewards.where((reward) => reward.familyId == familyId).toList();
    } catch (e) {
      throw ServerException('Failed to get rewards: $e', code: 'REWARD_FETCH_ERROR');
    }
  }

  @override
  Future<void> createReward(FamilyId familyId, Reward reward) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      // Check if reward already exists
      final existingReward = _rewards.where((r) => r.id == reward.id).firstOrNull;
      if (existingReward != null) {
        throw ValidationException('Reward already exists', code: 'REWARD_ALREADY_EXISTS');
      }
      
      _rewards.add(reward);
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to create reward: $e', code: 'REWARD_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateReward(FamilyId familyId, String rewardId, Reward reward) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _rewards.indexWhere((r) => r.id == rewardId);
      if (index != -1) {
        _rewards[index] = reward;
      } else {
        throw NotFoundException('Reward not found', code: 'REWARD_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to update reward: $e', code: 'REWARD_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteReward(FamilyId familyId, String rewardId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final initialLength = _rewards.length;
      _rewards.removeWhere((reward) => reward.id == rewardId);
      
      if (_rewards.length == initialLength) {
        throw NotFoundException('Reward not found', code: 'REWARD_NOT_FOUND');
      }
      
      // Remove reward from all user redemptions
      for (final userId in _userRedemptions.keys) {
        _userRedemptions[userId]!.remove(rewardId);
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to delete reward: $e', code: 'REWARD_DELETE_ERROR');
    }
  }

  @override
  Future<void> redeemReward(FamilyId familyId, UserId userId, String rewardId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      // Check if reward exists
      final reward = _rewards.where((r) => r.id == rewardId).firstOrNull;
      if (reward == null) {
        throw NotFoundException('Reward not found', code: 'REWARD_NOT_FOUND');
      }

      // Check if reward is available
      if (!reward.isAvailable) {
        throw ValidationException('Reward is not available', code: 'REWARD_NOT_AVAILABLE');
      }

      // Add redemption record
      if (!_userRedemptions.containsKey(userId.value)) {
        _userRedemptions[userId.value] = [];
      }
      
      if (!_userRedemptions[userId.value]!.contains(rewardId)) {
        _userRedemptions[userId.value]!.add(rewardId);
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to redeem reward: $e', code: 'REWARD_REDEEM_ERROR');
    }
  }

  /// Helper method to get user redemptions
  List<Reward> getUserRedemptions(UserId userId) {
    final rewardIds = _userRedemptions[userId.value] ?? [];
    return _rewards.where((reward) => rewardIds.contains(reward.id)).toList();
  }
} 