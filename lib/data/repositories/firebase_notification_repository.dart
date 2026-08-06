import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/value_objects/user_id.dart';
// Hides the project's own FirebaseException: this file catches Firestore's,
// to tell a missing document apart from a permission or network failure.
import '../../core/error/exceptions.dart' hide FirebaseException;

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

  /// The document for one notification. Notifications are per-user, so the
  /// owner is part of the address — there is no way to reach one without it,
  /// and no reason to look for it anywhere else.
  DocumentReference<Map<String, dynamic>> _doc(
          UserId userId, String notificationId) =>
      _firestore
          .collection('users')
          .doc(userId.value)
          .collection('notifications')
          .doc(notificationId);

  @override
  Future<void> deleteNotification(UserId userId, String notificationId) async {
    try {
      await _doc(userId, notificationId).delete();
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to delete notification: $e',
          code: 'NOTIFICATION_DELETE_ERROR');
    }
  }

  @override
  Future<void> markNotificationAsRead(
          UserId userId, String notificationId) async =>
      _setRead(userId, notificationId, true);

  @override
  Future<void> markNotificationAsUnread(
          UserId userId, String notificationId) async =>
      _setRead(userId, notificationId, false);

  Future<void> _setRead(
      UserId userId, String notificationId, bool isRead) async {
    try {
      await _doc(userId, notificationId).update({'isRead': isRead});
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw NotFoundException('Notification not found',
            code: 'NOTIFICATION_NOT_FOUND');
      }
      throw ServerException('Failed to mark notification as read: $e',
          code: 'NOTIFICATION_MARK_READ_ERROR');
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to mark notification as read: $e',
          code: 'NOTIFICATION_MARK_READ_ERROR');
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
      actorId: data['actorId'] as String?,
      deepLink: data['deepLink'] as String?,
      type: data['type'] as String?,
      entityId: data['entityId'] as String?,
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
      if (notification.actorId != null) 'actorId': notification.actorId,
      if (notification.deepLink != null) 'deepLink': notification.deepLink,
      if (notification.type != null) 'type': notification.type,
      if (notification.entityId != null) 'entityId': notification.entityId,
    };
  }
} 