import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/badge_repository.dart';
import '../../domain/entities/badge.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/points.dart';
import '../../core/error/exceptions.dart';

/// Firebase implementation of BadgeRepository
class FirebaseBadgeRepository implements BadgeRepository {
  final FirebaseFirestore _firestore;

  FirebaseBadgeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Badge>> streamUserBadges(UserId userId) {
    return _firestore
        .collection('users')
        .doc(userId.value)
        .collection('badges')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapFirestoreToBadge(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> awardBadge(FamilyId familyId, UserId userId, String badgeId) async {
    try {
      // Get the badge details
      final badgeDoc = await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('badges')
          .doc(badgeId)
          .get();

      if (!badgeDoc.exists) {
        throw NotFoundException('Badge not found', code: 'BADGE_NOT_FOUND');
      }

      // Add badge to user's collection
      await _firestore
          .collection('users')
          .doc(userId.value)
          .collection('badges')
          .doc(badgeId)
          .set({
        'awardedAt': FieldValue.serverTimestamp(),
        'familyId': familyId.value,
      });
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to award badge: $e', code: 'BADGE_AWARD_ERROR');
    }
  }

  @override
  Future<void> revokeBadge(FamilyId familyId, UserId userId, String badgeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId.value)
          .collection('badges')
          .doc(badgeId)
          .delete();
    } catch (e) {
      throw ServerException('Failed to revoke badge: $e', code: 'BADGE_REVOKE_ERROR');
    }
  }

  @override
  Future<List<Badge>> getBadges(FamilyId familyId) async {
    try {
      final snapshot = await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('badges')
          .get();

      return snapshot.docs
          .map((doc) => _mapFirestoreToBadge(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get badges: $e', code: 'BADGE_FETCH_ERROR');
    }
  }

  @override
  Future<void> createBadge(FamilyId familyId, Badge badge) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('badges')
          .doc(badge.id)
          .set(_mapBadgeToFirestore(badge));
    } catch (e) {
      throw ServerException('Failed to create badge: $e', code: 'BADGE_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateBadge(FamilyId familyId, String badgeId, Badge badge) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('badges')
          .doc(badgeId)
          .update(_mapBadgeToFirestore(badge));
    } catch (e) {
      throw ServerException('Failed to update badge: $e', code: 'BADGE_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteBadge(FamilyId familyId, String badgeId) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('badges')
          .doc(badgeId)
          .delete();
    } catch (e) {
      throw ServerException('Failed to delete badge: $e', code: 'BADGE_DELETE_ERROR');
    }
  }

  /// Maps Firestore document data to domain Badge entity
  Badge _mapFirestoreToBadge(Map<String, dynamic> data, String id) {
    return Badge(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      iconName: data['iconName'] as String? ?? '',
      requiredPoints: Points(data['requiredPoints'] as int? ?? 0),
      type: _mapStringToBadgeType(data['type'] as String? ?? 'taskCompletion'),
      familyId: FamilyId(data['familyId'] as String? ?? ''),
      creatorId: data['creatorId'] as String?,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      rarity: _mapStringToBadgeRarity(data['rarity'] as String? ?? 'common'),
    );
  }

  /// Maps domain Badge entity to Firestore document data
  Map<String, dynamic> _mapBadgeToFirestore(Badge badge) {
    return {
      'name': badge.name,
      'description': badge.description,
      'iconName': badge.iconName,
      'requiredPoints': badge.requiredPoints.toInt(),
      'type': badge.type.name,
      'familyId': badge.familyId.value,
      'creatorId': badge.creatorId,
      'createdAt': badge.createdAt,
      'updatedAt': badge.updatedAt,
      'rarity': badge.rarity.name,
    };
  }

  /// Maps string to BadgeType enum
  BadgeType _mapStringToBadgeType(String type) {
    switch (type.toLowerCase()) {
      case 'taskcompletion':
        return BadgeType.taskCompletion;
      case 'streak':
        return BadgeType.streak;
      case 'points':
        return BadgeType.points;
      case 'special':
        return BadgeType.special;
      case 'custom':
        return BadgeType.custom;
      case 'achievement':
        return BadgeType.achievement;
      case 'milestone':
        return BadgeType.milestone;
      default:
        return BadgeType.taskCompletion;
    }
  }

  /// Maps string to BadgeRarity enum
  BadgeRarity _mapStringToBadgeRarity(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return BadgeRarity.common;
      case 'uncommon':
        return BadgeRarity.uncommon;
      case 'rare':
        return BadgeRarity.rare;
      case 'epic':
        return BadgeRarity.epic;
      case 'legendary':
        return BadgeRarity.legendary;
      default:
        return BadgeRarity.common;
    }
  }
} 