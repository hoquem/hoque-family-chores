import 'dart:async';
import '../value_objects/user_id.dart';

/// Domain entity representing a notification
class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;
  final String? actorId;
  final String? deepLink;
  final String? type;
  final String? entityId;

  const Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
    this.actorId,
    this.deepLink,
    this.type,
    this.entityId,
  });

  /// Creates a copy of this notification with updated fields
  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? imageUrl,
    bool? isRead,
    DateTime? createdAt,
    String? actorId,
    String? deepLink,
    String? type,
    String? entityId,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actorId: actorId ?? this.actorId,
      deepLink: deepLink ?? this.deepLink,
      type: type ?? this.type,
      entityId: entityId ?? this.entityId,
    );
  }

  /// Mark notification as read
  Notification markAsRead() {
    return copyWith(isRead: true);
  }

  /// Mark notification as unread
  Notification markAsUnread() {
    return copyWith(isRead: false);
  }
}

/// Abstract interface for notification data operations
abstract class NotificationRepository {
  /// Stream notifications for a user
  Stream<List<Notification>> streamNotifications(UserId userId);

  /// Get notifications for a user
  Future<List<Notification>> getNotifications(UserId userId);

  /// Create a new notification
  Future<void> createNotification(UserId userId, Notification notification);

  /// Update an existing notification
  Future<void> updateNotification(UserId userId, Notification notification);

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId);

  /// Mark notification as unread
  Future<void> markNotificationAsUnread(String notificationId);
} 