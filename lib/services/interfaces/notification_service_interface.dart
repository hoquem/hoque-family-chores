import 'package:hoque_family_chores/models/notification.dart'
    as app_notification;

abstract class NotificationServiceInterface {
  Stream<List<app_notification.Notification>> streamNotifications({
    required String userId,
  });
  Future<void> markNotificationAsRead({required String notificationId});
}
