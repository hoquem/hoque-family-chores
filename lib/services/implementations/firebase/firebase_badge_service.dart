import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/services/interfaces/badge_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class FirebaseBadgeService implements BadgeServiceInterface {
  final FirebaseFirestore _firestore;

  FirebaseBadgeService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Badge>> streamUserBadges({required String userId}) {
    return ServiceUtils.handleServiceStream(
      stream:
          () => _firestore
              .collection('users')
              .doc(userId)
              .collection('badges')
              .snapshots()
              .map(
                (snapshot) =>
                    snapshot.docs
                        .map(
                          (doc) =>
                              Badge.fromJson({...?doc.data(), 'id': doc.id}),
                        )
                        .toList(),
              ),
      streamName: 'streamUserBadges',
      context: {'userId': userId},
    );
  }

  @override
  Future<void> awardBadge({
    required String familyId,
    required String userId,
    required String badgeId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('badges')
            .doc(badgeId)
            .set({'awardedAt': FieldValue.serverTimestamp()});
      },
      operationName: 'awardBadge',
      context: {'familyId': familyId, 'userId': userId, 'badgeId': badgeId},
    );
  }

  @override
  Future<void> revokeBadge({
    required String familyId,
    required String userId,
    required String badgeId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final batch = _firestore.batch();

        // Remove badge from user's badges collection
        final userBadgeRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('badges')
            .doc(badgeId);

        batch.delete(userBadgeRef);

        // Update user's badges array
        final userRef = _firestore.collection('users').doc(userId);
        batch.update(userRef, {
          'badges': FieldValue.arrayRemove([badgeId]),
        });

        await batch.commit();
      },
      operationName: 'revokeBadge',
      context: {'familyId': familyId, 'userId': userId, 'badgeId': badgeId},
    );
  }

  @override
  Future<void> createBadge({required String familyId, required Badge badge}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final docRef =
            _firestore
                .collection('families')
                .doc(familyId)
                .collection('badges')
                .doc();
        final badgeWithId = badge.copyWith(id: docRef.id);
        await docRef.set(badgeWithId.toJson());
      },
      operationName: 'createBadge',
      context: {'familyId': familyId, 'badgeId': badge.id},
    );
  }

  @override
  Future<void> updateBadge({
    required String familyId,
    required String badgeId,
    required Badge badge,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('families')
            .doc(familyId)
            .collection('badges')
            .doc(badgeId)
            .update(badge.toJson());
      },
      operationName: 'updateBadge',
      context: {'familyId': familyId, 'badgeId': badgeId},
    );
  }

  @override
  Future<void> deleteBadge({
    required String familyId,
    required String badgeId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('families')
            .doc(familyId)
            .collection('badges')
            .doc(badgeId)
            .delete();
      },
      operationName: 'deleteBadge',
      context: {'familyId': familyId, 'badgeId': badgeId},
    );
  }

  @override
  Future<List<Badge>> getBadges({required String familyId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final badgesSnapshot =
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('badges')
                .get();
        return badgesSnapshot.docs
            .map((doc) => Badge.fromJson({...?doc.data(), 'id': doc.id}))
            .toList();
      },
      operationName: 'getBadges',
      context: {'familyId': familyId},
    );
  }
}
