import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/services/interfaces/user_profile_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';

/// Service for handling Firebase Firestore user profile operations
class FirebaseUserProfileService implements UserProfileServiceInterface {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<UserProfile?> streamUserProfile({required String userId}) {
    return ServiceUtils.handleServiceStream(
      stream:
          () => _firestore
              .collection('users')
              .doc(userId)
              .snapshots()
              .map(
                (doc) {
                  if (!doc.exists) return null;
                  
                  final data = doc.data();
                  if (data == null) {
                    logger.w('[FirebaseUserProfileService] Document exists but data is null for user: $userId');
                    return null;
                  }
                  
                  try {
                    return UserProfile.fromJson({...data, 'id': doc.id});
                  } catch (e, s) {
                    logger.e('[FirebaseUserProfileService] Error parsing user profile for user $userId: $e', error: e, stackTrace: s);
                    return null;
                  }
                },
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
        
        if (!doc.exists) {
          logger.d('[FirebaseUserProfileService] User profile document does not exist for user: $userId');
          return null;
        }
        
        final data = doc.data();
        if (data == null) {
          logger.w('[FirebaseUserProfileService] Document exists but data is null for user: $userId');
          return null;
        }
        
        try {
          return UserProfile.fromJson({...data, 'id': doc.id});
        } catch (e, s) {
          logger.e('[FirebaseUserProfileService] Error parsing user profile for user $userId: $e', error: e, stackTrace: s);
          return null;
        }
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
          'points': FieldValue.increment(points),
        });
      },
      operationName: 'updateUserPoints',
      context: {'userId': userId, 'points': points},
    );
  }
}
