import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/notification.dart';
import 'package:hoque_family_chores/services/interfaces/notification_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';

/// Service for handling Firebase Firestore notification operations
class FirebaseNotificationService implements NotificationServiceInterface {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Notification>> streamNotifications({required String userId}) {
    return ServiceUtils.handleServiceStream(
      stream:
          () => _firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .orderBy('createdAt', descending: true)
              .snapshots()
              .map(
                (snapshot) =>
                    snapshot.docs
                        .map(
                          (doc) => Notification.fromJson({
                            ...doc.data(),
                            'id': doc.id,
                          }),
                        )
                        .toList(),
              ),
      streamName: 'streamNotifications',
      context: {'userId': userId},
    );
  }

  Future<List<Notification>> getNotifications({required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final snapshot =
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('notifications')
                .orderBy('createdAt', descending: true)
                .get();
        return snapshot.docs
            .map((doc) => Notification.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
      },
      operationName: 'getNotifications',
      context: {'userId': userId},
    );
  }

  Future<void> createNotification({
    required String userId,
    required Notification notification,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final docRef =
            _firestore
                .collection('users')
                .doc(userId)
                .collection('notifications')
                .doc();
        final notificationWithId = notification.copyWith(id: docRef.id);
        await docRef.set(notificationWithId.toJson());
      },
      operationName: 'createNotification',
      context: {'userId': userId, 'notificationId': notification.id},
    );
  }

  Future<void> updateNotification({
    required String userId,
    required Notification notification,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notification.id)
            .update(notification.toJson());
      },
      operationName: 'updateNotification',
      context: {'userId': userId, 'notificationId': notification.id},
    );
  }

  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationId)
            .delete();
      },
      operationName: 'deleteNotification',
      context: {'userId': userId, 'notificationId': notificationId},
    );
  }

  @override
  Future<void> markNotificationAsRead({required String notificationId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final querySnapshot =
            await _firestore
                .collectionGroup('notifications')
                .where(FieldPath.documentId, isEqualTo: notificationId)
                .get();

        if (querySnapshot.docs.isEmpty) {
          throw Exception('Notification not found');
        }

        await querySnapshot.docs.first.reference.update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      },
      operationName: 'markNotificationAsRead',
      context: {'notificationId': notificationId},
    );
  }

  Future<void> markAllAsRead({required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final batch = _firestore.batch();
        final snapshot =
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('notifications')
                .where('isRead', isEqualTo: false)
                .get();

        for (final doc in snapshot.docs) {
          batch.update(doc.reference, {'isRead': true});
        }

        await batch.commit();
      },
      operationName: 'markAllAsRead',
      context: {'userId': userId},
    );
  }
}
