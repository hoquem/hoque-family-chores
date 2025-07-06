import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/value_objects/user_id.dart';
import '../../core/error/exceptions.dart';

/// Firebase implementation of NotificationRepository
class FirebaseNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore;

  FirebaseNotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Notification>> streamNotifications(UserId userId) {
    return _firestore
        .collection('users')
        .doc(userId.value)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapFirestoreToNotification(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<List<Notification>> getNotifications(UserId userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId.value)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _mapFirestoreToNotification(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get notifications: $e', code: 'NOTIFICATION_FETCH_ERROR');
    }
  }

  @override
  Future<void> createNotification(UserId userId, Notification notification) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId.value)
          .collection('notifications')
          .doc(notification.id)
          .set(_mapNotificationToFirestore(notification));
    } catch (e) {
      throw ServerException('Failed to create notification: $e', code: 'NOTIFICATION_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateNotification(UserId userId, Notification notification) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId.value)
          .collection('notifications')
          .doc(notification.id)
          .update(_mapNotificationToFirestore(notification));
    } catch (e) {
      throw ServerException('Failed to update notification: $e', code: 'NOTIFICATION_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      // Find the notification first to get its user ID
      final usersSnapshot = await _firestore.collection('users').get();

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final notificationDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationId)
            .get();

        if (notificationDoc.exists) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .doc(notificationId)
              .delete();
          return;
        }
      }
      throw NotFoundException('Notification not found', code: 'NOTIFICATION_NOT_FOUND');
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to delete notification: $e', code: 'NOTIFICATION_DELETE_ERROR');
    }
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      // Find the notification first to get its user ID
      final usersSnapshot = await _firestore.collection('users').get();

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final notificationDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationId)
            .get();

        if (notificationDoc.exists) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .doc(notificationId)
              .update({'isRead': true});
          return;
        }
      }
      throw NotFoundException('Notification not found', code: 'NOTIFICATION_NOT_FOUND');
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to mark notification as read: $e', code: 'NOTIFICATION_MARK_READ_ERROR');
    }
  }

  @override
  Future<void> markNotificationAsUnread(String notificationId) async {
    try {
      // Find the notification first to get its user ID
      final usersSnapshot = await _firestore.collection('users').get();

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final notificationDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationId)
            .get();

        if (notificationDoc.exists) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .doc(notificationId)
              .update({'isRead': false});
          return;
        }
      }
      throw NotFoundException('Notification not found', code: 'NOTIFICATION_NOT_FOUND');
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to mark notification as unread: $e', code: 'NOTIFICATION_MARK_UNREAD_ERROR');
    }
  }

  /// Maps Firestore document data to domain Notification entity
  Notification _mapFirestoreToNotification(Map<String, dynamic> data, String id) {
    return Notification(
      id: id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Maps domain Notification entity to Firestore document data
  Map<String, dynamic> _mapNotificationToFirestore(Notification notification) {
    return {
      'userId': notification.userId,
      'title': notification.title,
      'message': notification.message,
      'imageUrl': notification.imageUrl,
      'isRead': notification.isRead,
      'createdAt': notification.createdAt,
    };
  }
} 