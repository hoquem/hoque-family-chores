import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/reward_repository.dart';
import '../../domain/entities/reward.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/points.dart';
import '../../core/error/exceptions.dart';

/// Firebase implementation of RewardRepository
class FirebaseRewardRepository implements RewardRepository {
  final FirebaseFirestore _firestore;

  FirebaseRewardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Reward>> getRewards(FamilyId familyId) async {
    try {
      final snapshot = await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('rewards')
          .get();

      return snapshot.docs
          .map((doc) => _mapFirestoreToReward(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get rewards: $e', code: 'REWARD_FETCH_ERROR');
    }
  }

  @override
  Future<void> createReward(FamilyId familyId, Reward reward) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('rewards')
          .doc(reward.id)
          .set(_mapRewardToFirestore(reward));
    } catch (e) {
      throw ServerException('Failed to create reward: $e', code: 'REWARD_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateReward(FamilyId familyId, String rewardId, Reward reward) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('rewards')
          .doc(rewardId)
          .update(_mapRewardToFirestore(reward));
    } catch (e) {
      throw ServerException('Failed to update reward: $e', code: 'REWARD_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteReward(FamilyId familyId, String rewardId) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('rewards')
          .doc(rewardId)
          .delete();
    } catch (e) {
      throw ServerException('Failed to delete reward: $e', code: 'REWARD_DELETE_ERROR');
    }
  }

  @override
  Future<void> redeemReward(FamilyId familyId, UserId userId, String rewardId) async {
    try {
      // Get the reward to validate it exists and check cost
      final rewardDoc = await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('rewards')
          .doc(rewardId)
          .get();

      if (!rewardDoc.exists) {
        throw NotFoundException('Reward not found', code: 'REWARD_NOT_FOUND');
      }

      final reward = _mapFirestoreToReward(rewardDoc.data()!, rewardId);

      // Check if reward is available
      if (!reward.isAvailable) {
        throw ValidationException('Reward is not available', code: 'REWARD_NOT_AVAILABLE');
      }

      // Create redemption record
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('redemptions')
          .add({
        'rewardId': rewardId,
        'userId': userId.value,
        'redeemedAt': FieldValue.serverTimestamp(),
        'pointsCost': reward.pointsCost.toInt(),
      });
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to redeem reward: $e', code: 'REWARD_REDEEM_ERROR');
    }
  }

  /// Maps Firestore document data to domain Reward entity
  Reward _mapFirestoreToReward(Map<String, dynamic> data, String id) {
    return Reward(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      pointsCost: Points(data['pointsCost'] as int? ?? 0),
      iconName: data['iconName'] as String? ?? '',
      type: _mapStringToRewardType(data['type'] as String? ?? 'digital'),
      familyId: FamilyId(data['familyId'] as String? ?? ''),
      creatorId: data['creatorId'] as String?,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      rarity: _mapStringToRewardRarity(data['rarity'] as String? ?? 'common'),
    );
  }

  /// Maps domain Reward entity to Firestore document data
  Map<String, dynamic> _mapRewardToFirestore(Reward reward) {
    return {
      'name': reward.name,
      'description': reward.description,
      'pointsCost': reward.pointsCost.toInt(),
      'iconName': reward.iconName,
      'type': reward.type.name,
      'familyId': reward.familyId.value,
      'creatorId': reward.creatorId,
      'createdAt': reward.createdAt,
      'updatedAt': reward.updatedAt,
      'rarity': reward.rarity.name,
    };
  }

  /// Maps string to RewardType enum
  RewardType _mapStringToRewardType(String type) {
    switch (type.toLowerCase()) {
      case 'digital':
        return RewardType.digital;
      case 'physical':
        return RewardType.physical;
      case 'privilege':
        return RewardType.privilege;
      default:
        return RewardType.digital;
    }
  }

  /// Maps string to RewardRarity enum
  RewardRarity _mapStringToRewardRarity(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return RewardRarity.common;
      case 'uncommon':
        return RewardRarity.uncommon;
      case 'rare':
        return RewardRarity.rare;
      case 'epic':
        return RewardRarity.epic;
      case 'legendary':
        return RewardRarity.legendary;
      default:
        return RewardRarity.common;
    }
  }
} 