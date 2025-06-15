import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/services/interfaces/user_profile_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class FirebaseUserProfileService implements UserProfileServiceInterface {
  final FirebaseFirestore _firestore;
  final _logger = AppLogger();

  FirebaseUserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserProfile?> streamUserProfile({required String userId}) {
    return ServiceUtils.handleServiceStream(
      stream:
          () => _firestore
              .collection('users')
              .doc(userId)
              .snapshots()
              .map(
                (doc) =>
                    doc.exists
                        ? UserProfile.fromJson({...doc.data()!, 'id': doc.id})
                        : null,
              ),
      streamName: 'streamUserProfile',
      context: {'userId': userId},
    );
  }

  @override
  Future<UserProfile?> getUserProfile({required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final doc = await _firestore.collection('users').doc(userId).get();
        return doc.exists
            ? UserProfile.fromJson({...doc.data()!, 'id': doc.id})
            : null;
      },
      operationName: 'getUserProfile',
      context: {'userId': userId},
    );
  }

  @override
  Future<void> createUserProfile({required UserProfile userProfile}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('users')
            .doc(userProfile.member.id)
            .set(userProfile.toJson());
      },
      operationName: 'createUserProfile',
      context: {'userId': userProfile.member.id},
    );
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    required UserProfile userProfile,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('users')
            .doc(userId)
            .update(userProfile.toJson());
      },
      operationName: 'updateUserProfile',
      context: {'userId': userId},
    );
  }

  @override
  Future<void> deleteUserProfile({required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore.collection('users').doc(userId).delete();
      },
      operationName: 'deleteUserProfile',
      context: {'userId': userId},
    );
  }

  @override
  Future<void> updateUserPoints({required String userId, required int points}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore.collection('users').doc(userId).update({
          'totalPoints': FieldValue.increment(points),
        });
      },
      operationName: 'updateUserPoints',
      context: {'userId': userId, 'points': points},
    );
  }
}
