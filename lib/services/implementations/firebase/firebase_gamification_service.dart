import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/achievement.dart';
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/services/interfaces/gamification_service_interface.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class FirebaseGamificationService implements GamificationServiceInterface {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _logger = AppLogger();

  // Define references to your Firestore collections
  final CollectionReference _achievementsCollection;
  final CollectionReference _badgesCollection;
  final CollectionReference _rewardsCollection;
  final CollectionReference _userProfilesCollection;

  FirebaseGamificationService()
    : _achievementsCollection = FirebaseFirestore.instance.collection(
        'achievements',
      ),
      _badgesCollection = FirebaseFirestore.instance.collection('badges'),
      _rewardsCollection = FirebaseFirestore.instance.collection('rewards'),
      _userProfilesCollection = FirebaseFirestore.instance.collection(
        'user_profiles',
      );

  @override
  Stream<List<Badge>> streamUserBadges({required String userId}) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('badges')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Badge.fromJson({...doc.data(), 'id': doc.id}))
                  .toList(),
        );
  }

  @override
  Future<void> awardBadge({
    required String familyId,
    required String userId,
    required String badgeId,
  }) async {
    try {
      final badgeDoc = await _badgesCollection.doc(badgeId).get();
      if (!badgeDoc.exists) {
        throw Exception('Badge not found');
      }

      await _db
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc(badgeId)
          .set(badgeDoc.data() as Map<String, dynamic>);

      _logger.i('Badge $badgeId awarded to user $userId');
    } catch (e) {
      _logger.e('Error awarding badge: $e');
      rethrow;
    }
  }

  @override
  Future<void> revokeBadge({
    required String familyId,
    required String userId,
    required String badgeId,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc(badgeId)
          .delete();

      _logger.i('Badge $badgeId revoked from user $userId');
    } catch (e) {
      _logger.e('Error revoking badge: $e');
      rethrow;
    }
  }

  @override
  Future<List<Badge>> getBadges({required String familyId}) async {
    try {
      final snapshot = await _badgesCollection.get();
      if (snapshot.docs.isEmpty) {
        return [];
      }
      return snapshot.docs
          .map(
            (doc) => Badge.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      _logger.e('Error fetching badges: $e');
      rethrow;
    }
  }

  @override
  Future<void> createBadge({
    required String familyId,
    required Badge badge,
  }) async {
    try {
      await _badgesCollection.doc(badge.id).set(badge.toJson());
      _logger.i('Badge ${badge.id} created');
    } catch (e) {
      _logger.e('Error creating badge', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateBadge({
    required String familyId,
    required String badgeId,
    required Badge badge,
  }) async {
    try {
      await _badgesCollection.doc(badgeId).update(badge.toJson());
      _logger.i('Badge $badgeId updated');
    } catch (e) {
      _logger.e('Error updating badge', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deleteBadge({
    required String familyId,
    required String badgeId,
  }) async {
    try {
      await _badgesCollection.doc(badgeId).delete();
      _logger.i('Badge $badgeId deleted');
    } catch (e) {
      _logger.e('Error deleting badge: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Achievement>> streamUserAchievements({required String userId}) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        Achievement.fromJson({...doc.data(), 'id': doc.id}),
                  )
                  .toList(),
        );
  }

  @override
  Future<void> grantAchievement({
    required String userId,
    required Achievement achievement,
  }) async {
    try {
      await _achievementsCollection
          .doc(userId)
          .collection('achievements')
          .doc(achievement.id)
          .set(achievement.toJson());

      _logger.i('Achievement ${achievement.id} granted to user $userId');
    } catch (e) {
      _logger.e('Error granting achievement', error: e);
      rethrow;
    }
  }

  @override
  Future<List<Reward>> getRewards({required String familyId}) async {
    try {
      final snapshot =
          await _rewardsCollection.where('familyId', isEqualTo: familyId).get();
      if (snapshot.docs.isEmpty) {
        return [];
      }
      return snapshot.docs
          .map(
            (doc) => Reward.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e, s) {
      _logger.e('Error fetching rewards: $e', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> createReward({
    required String familyId,
    required Reward reward,
  }) async {
    try {
      await _rewardsCollection.doc(reward.id).set(reward.toJson());
      _logger.i('Reward ${reward.id} created');
    } catch (e, s) {
      _logger.e('Error creating reward: $e', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> updateReward({
    required String familyId,
    required String rewardId,
    required Reward reward,
  }) async {
    try {
      await _rewardsCollection.doc(rewardId).update(reward.toJson());
      _logger.i('Reward $rewardId updated');
    } catch (e, s) {
      _logger.e('Error updating reward: $e', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> deleteReward({
    required String familyId,
    required String rewardId,
  }) async {
    try {
      await _rewardsCollection.doc(rewardId).delete();
      _logger.i('Reward $rewardId deleted');
    } catch (e, s) {
      _logger.e('Error deleting reward: $e', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> redeemReward({
    required String familyId,
    required String userId,
    required String rewardId,
  }) async {
    try {
      final rewardDoc = await _rewardsCollection.doc(rewardId).get();
      if (!rewardDoc.exists) {
        throw Exception('Reward not found');
      }

      final reward = Reward.fromJson({
        ...rewardDoc.data() as Map<String, dynamic>,
        'id': rewardDoc.id,
      });

      final userProfile = await getUserProfile(userId: userId);
      if (userProfile.totalPoints < reward.pointsCost) {
        throw Exception('Not enough points to redeem reward');
      }

      // Update user points
      await _userProfilesCollection.doc(userId).update({
        'totalPoints': userProfile.totalPoints - reward.pointsCost,
      });

      // Record redemption
      await _db
          .collection('users')
          .doc(userId)
          .collection('redeemed_rewards')
          .doc(rewardId)
          .set({
            'rewardId': rewardId,
            'redeemedAt': FieldValue.serverTimestamp(),
            'pointsCost': reward.pointsCost,
          });

      _logger.i('Reward $rewardId redeemed by user $userId');
    } catch (e, s) {
      _logger.e('Error redeeming reward: $e', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> updateUserPoints({
    required String userId,
    required int points,
  }) async {
    try {
      await _db.collection('users').doc(userId).update({
        'totalPoints': points,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.i('User $userId points updated to $points');
    } catch (e) {
      _logger.e('Error updating user points: $e');
      rethrow;
    }
  }

  @override
  Future<UserProfile> getUserProfile({required String userId}) async {
    try {
      final doc = await _userProfilesCollection.doc(userId).get();
      if (!doc.exists) {
        throw Exception('User profile not found');
      }
      return UserProfile.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
    } catch (e, s) {
      _logger.e('Error getting user profile: $e', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Stream<UserProfile?> streamUserProfile({required String userId}) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map(
          (doc) =>
              doc.exists
                  ? UserProfile.fromJson({
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  })
                  : null,
        );
  }

  @override
  Future<void> deleteUserProfile({required String userId}) async {
    try {
      await _db.collection('users').doc(userId).delete();
      _logger.i('User profile $userId deleted');
    } catch (e) {
      _logger.e('Error deleting user profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> createUserProfile({required UserProfile userProfile}) async {
    try {
      await _db
          .collection('users')
          .doc(userProfile.member.id)
          .set(userProfile.toJson());
      _logger.i('User profile ${userProfile.member.id} created');
    } catch (e) {
      _logger.e('Error creating user profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    required UserProfile userProfile,
  }) async {
    try {
      await _userProfilesCollection.doc(userId).update(userProfile.toJson());
      _logger.i('User profile $userId updated');
    } catch (e, s) {
      _logger.e('Error updating user profile: $e', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> initializeUserData({
    required String userId,
    required String familyId,
  }) async {
    try {
      final now = DateTime.now();
      final userProfile = UserProfile(
        member: FamilyMember(
          id: userId,
          userId: userId,
          name: 'New User',
          role: FamilyRole.child,
          familyId: familyId,
          points: 0,
          joinedAt: now,
          updatedAt: now,
        ),
        totalPoints: 0,
        currentLevel: 1,
        pointsToNextLevel: 100,
        completedTasks: 0,
        currentStreak: 0,
        longestStreak: 0,
        badges: [],
        achievements: [],
        createdAt: now,
      );

      await _userProfilesCollection.doc(userId).set(userProfile.toJson());
      _logger.i(
        'User profile initialized for user $userId in family $familyId',
      );
    } catch (e, s) {
      _logger.e('Error initializing user data: $e', error: e, stackTrace: s);
      rethrow;
    }
  }
}
