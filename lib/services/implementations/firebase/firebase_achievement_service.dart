import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/achievement.dart';
import 'package:hoque_family_chores/services/interfaces/achievement_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';

class FirebaseAchievementService implements AchievementServiceInterface {
  final FirebaseFirestore _firestore;

  FirebaseAchievementService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Achievement>> streamUserAchievements({required String userId}) {
    return ServiceUtils.handleServiceStream(
      stream:
          () => _firestore
              .collection('users')
              .doc(userId)
              .collection('achievements')
              .snapshots()
              .map(
                (snapshot) =>
                    snapshot.docs
                        .map(
                          (doc) => Achievement.fromJson({
                            ...doc.data(),
                            'id': doc.id,
                          }),
                        )
                        .toList(),
              ),
      streamName: 'streamUserAchievements',
      context: {'userId': userId},
    );
  }

  @override
  Future<void> createAchievement({
    required String familyId,
    required Achievement achievement,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('families')
            .doc(familyId)
            .collection('achievements')
            .doc(achievement.id)
            .set(achievement.toJson());
      },
      operationName: 'createAchievement',
      context: {'familyId': familyId, 'achievementId': achievement.id},
    );
  }

  @override
  Future<void> updateAchievement({
    required String familyId,
    required String achievementId,
    required Achievement achievement,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('families')
            .doc(familyId)
            .collection('achievements')
            .doc(achievementId)
            .update(achievement.toJson());
      },
      operationName: 'updateAchievement',
      context: {'familyId': familyId, 'achievementId': achievementId},
    );
  }

  @override
  Future<void> deleteAchievement({
    required String familyId,
    required String achievementId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('families')
            .doc(familyId)
            .collection('achievements')
            .doc(achievementId)
            .delete();
      },
      operationName: 'deleteAchievement',
      context: {'familyId': familyId, 'achievementId': achievementId},
    );
  }

  @override
  Future<void> grantAchievement({
    required String userId,
    required Achievement achievement,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .doc(achievement.id)
            .set(achievement.toJson());
      },
      operationName: 'grantAchievement',
      context: {'userId': userId, 'achievementId': achievement.id},
    );
  }

  @override
  Future<void> revokeAchievement({
    required String familyId,
    required String userId,
    required String achievementId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final batch = _firestore.batch();

        // Remove achievement from user's achievements collection
        final userAchievementRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .doc(achievementId);

        batch.delete(userAchievementRef);

        // Update user's achievements array
        final userRef = _firestore.collection('users').doc(userId);
        batch.update(userRef, {
          'achievements': FieldValue.arrayRemove([achievementId]),
        });

        await batch.commit();
      },
      operationName: 'revokeAchievement',
      context: {
        'familyId': familyId,
        'userId': userId,
        'achievementId': achievementId,
      },
    );
  }
}
