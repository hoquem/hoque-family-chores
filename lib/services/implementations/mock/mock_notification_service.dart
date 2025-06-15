import 'package:hoque_family_chores/models/notification.dart';
import 'package:hoque_family_chores/services/interfaces/notification_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class MockNotificationService implements NotificationServiceInterface {
  final List<Notification> _notifications = [];
  final _logger = AppLogger();

  MockNotificationService() {
    _logger.i(
      "MockNotificationService initialized with empty notifications list.",
    );
  }

  @override
  Stream<List<Notification>> streamNotifications({required String userId}) {
    return ServiceUtils.handleServiceStream(
      stream: () async* {
        await Future.delayed(const Duration(milliseconds: 300));
        yield _notifications.where((n) => n.userId == userId).toList();
      },
      streamName: 'streamNotifications',
      context: {'userId': userId},
    );
  }

  @override
  Future<List<Notification>> getNotifications({required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        return _notifications.where((n) => n.userId == userId).toList();
      },
      operationName: 'getNotifications',
      context: {'userId': userId},
    );
  }

  @override
  Future<void> createNotification({
    required String userId,
    required Notification notification,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _notifications.add(notification);
      },
      operationName: 'createNotification',
      context: {'userId': userId, 'notificationId': notification.id},
    );
  }

  @override
  Future<void> updateNotification({
    required String userId,
    required Notification notification,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification;
        }
      },
      operationName: 'updateNotification',
      context: {'userId': userId, 'notificationId': notification.id},
    );
  }

  @override
  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _notifications.removeWhere((n) => n.id == notificationId);
      },
      operationName: 'deleteNotification',
      context: {'userId': userId, 'notificationId': notificationId},
    );
  }

  @override
  Future<void> markNotificationAsRead({required String notificationId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      },
      operationName: 'markNotificationAsRead',
      context: {'notificationId': notificationId},
    );
  }

  @override
  Future<void> markAllAsRead({required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        for (var i = 0; i < _notifications.length; i++) {
          if (_notifications[i].userId == userId && !_notifications[i].isRead) {
            _notifications[i] = _notifications[i].copyWith(isRead: true);
          }
        }
      },
      operationName: 'markAllAsRead',
      context: {'userId': userId},
    );
  }
}
