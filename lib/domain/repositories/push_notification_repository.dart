import '../entities/push_notification.dart';

/// Repository interface for push notifications
abstract class PushNotificationRepository {
  /// Initialize push notification service
  Future<void> initialize();

  /// Request notification permissions
  Future<bool> requestPermissions();

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled();

  /// Get FCM token
  Future<String?> getToken();

  /// Send a push notification
  Future<void> sendNotification(PushNotificationPayload payload);

  /// Schedule a push notification
  Future<void> scheduleNotification(
    PushNotificationPayload payload,
    DateTime scheduledTime,
  );

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int notificationId);

  /// Cancel all notifications
  Future<void> cancelAllNotifications();

  /// Handle notification tap (deep link)
  Future<void> handleNotificationTap(Map<String, dynamic> data);

  /// Send test notification
  Future<void> sendTestNotification();
}
