import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../domain/entities/badge.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/reward.dart';
import '../../domain/entities/user.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/points.dart';
import '../../domain/value_objects/email.dart';
import '../../core/error/exceptions.dart';

/// Firebase implementation of GamificationRepository
class FirebaseGamificationRepository implements GamificationRepository {
  final FirebaseFirestore _firestore;

  FirebaseGamificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Badge operations
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

  // Achievement operations
  @override
  Stream<List<Achievement>> streamUserAchievements(UserId userId) {
    return _firestore
        .collection('users')
        .doc(userId.value)
        .collection('achievements')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapFirestoreToAchievement(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> grantAchievement(UserId userId, Achievement achievement) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId.value)
          .collection('achievements')
          .doc(achievement.id)
          .set(_mapAchievementToFirestore(achievement));
    } catch (e) {
      throw ServerException('Failed to grant achievement: $e', code: 'ACHIEVEMENT_GRANT_ERROR');
    }
  }

  // Reward operations
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

  // User profile operations
  @override
  Future<void> updateUserPoints(UserId userId, Points points) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId.value)
          .update({'points': points.toInt()});
    } catch (e) {
      throw ServerException('Failed to update user points: $e', code: 'USER_POINTS_UPDATE_ERROR');
    }
  }

  @override
  Future<User?> getUserProfile(UserId userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId.value).get();

      if (!doc.exists) return null;

      return _mapFirestoreToUser(doc.data()!, doc.id);
    } catch (e) {
      throw ServerException('Failed to get user profile: $e', code: 'USER_FETCH_ERROR');
    }
  }

  @override
  Stream<User?> streamUserProfile(UserId userId) {
    return _firestore
        .collection('users')
        .doc(userId.value)
        .snapshots()
        .map((doc) => doc.exists ? _mapFirestoreToUser(doc.data()!, doc.id) : null);
  }

  @override
  Future<void> deleteUserProfile(UserId userId) async {
    try {
      await _firestore.collection('users').doc(userId.value).delete();
    } catch (e) {
      throw ServerException('Failed to delete user profile: $e', code: 'USER_DELETE_ERROR');
    }
  }

  @override
  Future<void> createUserProfile(User user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id.value)
          .set(_mapUserToFirestore(user));
    } catch (e) {
      throw ServerException('Failed to create user profile: $e', code: 'USER_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateUserProfile(UserId userId, User user) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId.value)
          .update(_mapUserToFirestore(user));
    } catch (e) {
      throw ServerException('Failed to update user profile: $e', code: 'USER_UPDATE_ERROR');
    }
  }

  @override
  Future<void> initializeUserData(UserId userId, FamilyId familyId) async {
    try {
      // Initialize user with default values
      final user = User(
        id: userId,
        name: '',
        email: Email(''),
        photoUrl: null,
        familyId: familyId,
        role: UserRole.child,
        points: Points.zero,
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await createUserProfile(user);
    } catch (e) {
      throw ServerException('Failed to initialize user data: $e', code: 'USER_INIT_ERROR');
    }
  }

  // Mapping methods
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

  Achievement _mapFirestoreToAchievement(Map<String, dynamic> data, String id) {
    return Achievement(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      points: Points(data['points'] as int? ?? 0),
      icon: data['icon'] as String? ?? '',
      type: _mapStringToBadgeType(data['type'] as String? ?? 'taskCompletion'),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      completedAt: data['completedAt'] is Timestamp
          ? (data['completedAt'] as Timestamp).toDate()
          : data['completedAt'] != null
              ? DateTime.tryParse(data['completedAt'].toString())
              : null,
      completedBy: data['completedBy'] as String?,
    );
  }

  Map<String, dynamic> _mapAchievementToFirestore(Achievement achievement) {
    return {
      'title': achievement.title,
      'description': achievement.description,
      'points': achievement.points.toInt(),
      'icon': achievement.icon,
      'type': achievement.type.name,
      'createdAt': achievement.createdAt,
      'completedAt': achievement.completedAt,
      'completedBy': achievement.completedBy,
    };
  }

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

  User _mapFirestoreToUser(Map<String, dynamic> data, String id) {
    return User(
      id: UserId(id),
      name: data['name'] as String? ?? '',
      email: Email(data['email'] as String? ?? ''),
      photoUrl: data['photoUrl'] as String?,
      familyId: FamilyId(data['familyId'] as String? ?? ''),
      role: _mapStringToUserRole(data['role'] as String? ?? 'child'),
      points: Points(data['points'] as int? ?? 0),
      joinedAt: data['joinedAt'] is Timestamp
          ? (data['joinedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['joinedAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _mapUserToFirestore(User user) {
    return {
      'name': user.name,
      'email': user.email.value,
      'photoUrl': user.photoUrl,
      'familyId': user.familyId.value,
      'role': user.role.name,
      'points': user.points.toInt(),
      'joinedAt': user.joinedAt,
      'updatedAt': user.updatedAt,
    };
  }

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

  UserRole _mapStringToUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'parent':
        return UserRole.parent;
      case 'child':
        return UserRole.child;
      case 'guardian':
        return UserRole.guardian;
      case 'other':
        return UserRole.other;
      default:
        return UserRole.child;
    }
  }
} 