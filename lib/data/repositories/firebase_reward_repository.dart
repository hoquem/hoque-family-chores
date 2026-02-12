import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/reward_repository.dart';
import '../../domain/entities/reward.dart';
import '../../domain/entities/reward_redemption.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/points.dart';
import '../../core/error/exceptions.dart';

/// Firebase implementation of RewardRepository
class FirebaseRewardRepository implements RewardRepository {
  final FirebaseFirestore _firestore;

  FirebaseRewardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _rewardsCollection(FamilyId familyId) {
    return _firestore
        .collection('families')
        .doc(familyId.value)
        .collection('rewards');
  }

  CollectionReference _redemptionsCollection(FamilyId familyId) {
    return _firestore
        .collection('families')
        .doc(familyId.value)
        .collection('redemptions');
  }

  @override
  Future<List<Reward>> getRewards(FamilyId familyId) async {
    try {
      final snapshot = await _rewardsCollection(familyId).get();
      return snapshot.docs
          .map((doc) => _mapFirestoreToReward(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get rewards: $e', code: 'REWARD_FETCH_ERROR');
    }
  }

  @override
  Future<List<Reward>> getActiveRewards(FamilyId familyId) async {
    try {
      final snapshot = await _rewardsCollection(familyId)
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => _mapFirestoreToReward(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get active rewards: $e', code: 'REWARD_FETCH_ERROR');
    }
  }

  @override
  Future<Reward?> getReward(FamilyId familyId, String rewardId) async {
    try {
      final doc = await _rewardsCollection(familyId).doc(rewardId).get();
      if (!doc.exists) return null;
      return _mapFirestoreToReward(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw ServerException('Failed to get reward: $e', code: 'REWARD_FETCH_ERROR');
    }
  }

  @override
  Future<void> createReward(FamilyId familyId, Reward reward) async {
    try {
      await _rewardsCollection(familyId)
          .doc(reward.id)
          .set(_mapRewardToFirestore(reward));
    } catch (e) {
      throw ServerException('Failed to create reward: $e', code: 'REWARD_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateReward(FamilyId familyId, String rewardId, Reward reward) async {
    try {
      await _rewardsCollection(familyId)
          .doc(rewardId)
          .update(_mapRewardToFirestore(reward));
    } catch (e) {
      throw ServerException('Failed to update reward: $e', code: 'REWARD_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteReward(FamilyId familyId, String rewardId) async {
    try {
      // Soft delete: mark as inactive
      await _rewardsCollection(familyId).doc(rewardId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to delete reward: $e', code: 'REWARD_DELETE_ERROR');
    }
  }

  @override
  Future<RewardRedemption> requestRedemption(
    FamilyId familyId,
    UserId userId,
    String rewardId,
  ) async {
    try {
      // Use transaction to ensure atomicity
      return await _firestore.runTransaction((transaction) async {
        // Get the reward
        final rewardDoc = await transaction.get(
          _rewardsCollection(familyId).doc(rewardId),
        );

        if (!rewardDoc.exists) {
          throw NotFoundException('Reward not found', code: 'REWARD_NOT_FOUND');
        }

        final reward = _mapFirestoreToReward(
          rewardDoc.data() as Map<String, dynamic>,
          rewardId,
        );

        if (!reward.isAvailable) {
          throw ValidationException(
            'Reward is not available',
            code: 'REWARD_NOT_AVAILABLE',
          );
        }

        // Check for existing pending redemption
        final pendingSnapshot = await _redemptionsCollection(familyId)
            .where('rewardId', isEqualTo: rewardId)
            .where('userId', isEqualTo: userId.value)
            .where('status', isEqualTo: 'pending')
            .get();

        if (pendingSnapshot.docs.isNotEmpty) {
          throw ValidationException(
            'You already have a pending request for this reward',
            code: 'REDEMPTION_ALREADY_PENDING',
          );
        }

        // Create redemption record
        final redemptionRef = _redemptionsCollection(familyId).doc();
        final redemption = RewardRedemption(
          id: redemptionRef.id,
          rewardId: rewardId,
          rewardName: reward.name,
          rewardIconEmoji: reward.iconEmoji,
          starCost: reward.costAsInt,
          userId: userId,
          familyId: familyId,
          status: RedemptionStatus.pending,
          requestedAt: DateTime.now(),
        );

        transaction.set(redemptionRef, _mapRedemptionToFirestore(redemption));

        // Update stock if applicable
        if (reward.stock != null) {
          transaction.update(
            _rewardsCollection(familyId).doc(rewardId),
            {'stock': FieldValue.increment(-1)},
          );
        }

        return redemption;
      });
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to request redemption: $e', code: 'REDEMPTION_REQUEST_ERROR');
    }
  }

  @override
  Future<List<RewardRedemption>> getPendingRedemptions(FamilyId familyId) async {
    try {
      final snapshot = await _redemptionsCollection(familyId)
          .where('status', isEqualTo: 'pending')
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _mapFirestoreToRedemption(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw ServerException(
        'Failed to get pending redemptions: $e',
        code: 'REDEMPTION_FETCH_ERROR',
      );
    }
  }

  @override
  Future<List<RewardRedemption>> getUserRedemptions(
    FamilyId familyId,
    UserId userId,
  ) async {
    try {
      final snapshot = await _redemptionsCollection(familyId)
          .where('userId', isEqualTo: userId.value)
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _mapFirestoreToRedemption(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw ServerException(
        'Failed to get user redemptions: $e',
        code: 'REDEMPTION_FETCH_ERROR',
      );
    }
  }

  @override
  Future<List<RewardRedemption>> getAllRedemptions(FamilyId familyId) async {
    try {
      final snapshot = await _redemptionsCollection(familyId)
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _mapFirestoreToRedemption(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw ServerException(
        'Failed to get all redemptions: $e',
        code: 'REDEMPTION_FETCH_ERROR',
      );
    }
  }

  @override
  Future<void> approveRedemption(
    FamilyId familyId,
    String redemptionId,
    UserId approverUserId,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final redemptionDoc = await transaction.get(
          _redemptionsCollection(familyId).doc(redemptionId),
        );

        if (!redemptionDoc.exists) {
          throw NotFoundException('Redemption not found', code: 'REDEMPTION_NOT_FOUND');
        }

        final data = redemptionDoc.data() as Map<String, dynamic>;
        if (data['status'] != 'pending') {
          throw ValidationException(
            'Redemption is not pending',
            code: 'REDEMPTION_NOT_PENDING',
          );
        }

        transaction.update(
          _redemptionsCollection(familyId).doc(redemptionId),
          {
            'status': 'approved',
            'processedAt': FieldValue.serverTimestamp(),
            'processedByUserId': approverUserId.value,
          },
        );
      });
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to approve redemption: $e', code: 'REDEMPTION_APPROVE_ERROR');
    }
  }

  @override
  Future<void> rejectRedemption(
    FamilyId familyId,
    String redemptionId,
    UserId approverUserId,
    String? reason,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final redemptionDoc = await transaction.get(
          _redemptionsCollection(familyId).doc(redemptionId),
        );

        if (!redemptionDoc.exists) {
          throw NotFoundException('Redemption not found', code: 'REDEMPTION_NOT_FOUND');
        }

        final data = redemptionDoc.data() as Map<String, dynamic>;
        if (data['status'] != 'pending') {
          throw ValidationException(
            'Redemption is not pending',
            code: 'REDEMPTION_NOT_PENDING',
          );
        }

        final rewardId = data['rewardId'] as String;
        final rewardDoc = await transaction.get(
          _rewardsCollection(familyId).doc(rewardId),
        );

        // Restore stock if applicable
        if (rewardDoc.exists) {
          final rewardData = rewardDoc.data() as Map<String, dynamic>;
          if (rewardData['stock'] != null) {
            transaction.update(
              _rewardsCollection(familyId).doc(rewardId),
              {'stock': FieldValue.increment(1)},
            );
          }
        }

        transaction.update(
          _redemptionsCollection(familyId).doc(redemptionId),
          {
            'status': 'rejected',
            'processedAt': FieldValue.serverTimestamp(),
            'processedByUserId': approverUserId.value,
            if (reason != null) 'rejectionReason': reason,
          },
        );
      });
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to reject redemption: $e', code: 'REDEMPTION_REJECT_ERROR');
    }
  }

  @override
  Stream<List<Reward>> watchRewards(FamilyId familyId) {
    return _rewardsCollection(familyId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapFirestoreToReward(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  @override
  Stream<List<RewardRedemption>> watchPendingRedemptions(FamilyId familyId) {
    return _redemptionsCollection(familyId)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapFirestoreToRedemption(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Maps Firestore document data to domain Reward entity
  Reward _mapFirestoreToReward(Map<String, dynamic> data, String id) {
    return Reward(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      pointsCost: Points(data['pointsCost'] as int? ?? 0),
      iconEmoji: data['iconEmoji'] as String? ?? '🎁',
      type: _mapStringToRewardType(data['type'] as String? ?? 'digital'),
      familyId: FamilyId(data['familyId'] as String? ?? ''),
      creatorId: data['creatorId'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      rarity: _mapStringToRewardRarity(data['rarity'] as String? ?? 'common'),
      isActive: data['isActive'] as bool? ?? true,
      stock: data['stock'] as int?,
      isFeatured: data['isFeatured'] as bool? ?? false,
    );
  }

  /// Maps domain Reward entity to Firestore document data
  Map<String, dynamic> _mapRewardToFirestore(Reward reward) {
    return {
      'name': reward.name,
      'description': reward.description,
      'pointsCost': reward.pointsCost.toInt(),
      'iconEmoji': reward.iconEmoji,
      'type': reward.type.name,
      'familyId': reward.familyId.value,
      'creatorId': reward.creatorId,
      'createdAt': Timestamp.fromDate(reward.createdAt),
      'updatedAt': Timestamp.fromDate(reward.updatedAt),
      'rarity': reward.rarity.name,
      'isActive': reward.isActive,
      if (reward.stock != null) 'stock': reward.stock,
      'isFeatured': reward.isFeatured,
    };
  }

  /// Maps Firestore document data to domain RewardRedemption entity
  RewardRedemption _mapFirestoreToRedemption(Map<String, dynamic> data, String id) {
    return RewardRedemption(
      id: id,
      rewardId: data['rewardId'] as String,
      rewardName: data['rewardName'] as String,
      rewardIconEmoji: data['rewardIconEmoji'] as String? ?? '🎁',
      starCost: data['starCost'] as int,
      userId: UserId(data['userId'] as String),
      familyId: FamilyId(data['familyId'] as String),
      status: _mapStringToRedemptionStatus(data['status'] as String),
      requestedAt: _parseTimestamp(data['requestedAt']),
      processedAt: data['processedAt'] != null ? _parseTimestamp(data['processedAt']) : null,
      processedByUserId: data['processedByUserId'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  /// Maps domain RewardRedemption entity to Firestore document data
  Map<String, dynamic> _mapRedemptionToFirestore(RewardRedemption redemption) {
    return {
      'rewardId': redemption.rewardId,
      'rewardName': redemption.rewardName,
      'rewardIconEmoji': redemption.rewardIconEmoji,
      'starCost': redemption.starCost,
      'userId': redemption.userId.value,
      'familyId': redemption.familyId.value,
      'status': redemption.status.name,
      'requestedAt': Timestamp.fromDate(redemption.requestedAt),
      if (redemption.processedAt != null)
        'processedAt': Timestamp.fromDate(redemption.processedAt!),
      if (redemption.processedByUserId != null)
        'processedByUserId': redemption.processedByUserId,
      if (redemption.rejectionReason != null) 'rejectionReason': redemption.rejectionReason,
    };
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    return DateTime.now();
  }

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

  RedemptionStatus _mapStringToRedemptionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return RedemptionStatus.pending;
      case 'approved':
        return RedemptionStatus.approved;
      case 'rejected':
        return RedemptionStatus.rejected;
      default:
        return RedemptionStatus.pending;
    }
  }
}
