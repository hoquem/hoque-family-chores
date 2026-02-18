import 'dart:async';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/value_objects/user_id.dart';
import '../../core/error/exceptions.dart';

/// Mock implementation of NotificationRepository for testing
class MockNotificationRepository implements NotificationRepository {
  final List<Notification> _notifications = [];
  final StreamController<List<Notification>> _notificationsStreamController = StreamController<List<Notification>>.broadcast();

  MockNotificationRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Create some mock notifications
    final mockNotifications = [
      Notification(
        id: 'notification_1',
        userId: 'user_1',
        title: 'Task Completed!',
        message: 'Great job completing "Clean the kitchen"!',
        imageUrl: null,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Notification(
        id: 'notification_2',
        userId: 'user_1',
        title: 'New Badge Earned',
        message: 'Congratulations! You earned the "Task Master" badge.',
        imageUrl: null,
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Notification(
        id: 'notification_3',
        userId: 'user_2',
        title: 'Task Assigned',
        message: 'You have been assigned "Do laundry"',
        imageUrl: null,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];

    _notifications.addAll(mockNotifications);
    _notificationsStreamController.add(List.from(_notifications));
  }

  @override
  Stream<List<Notification>> streamNotifications(UserId userId) {
    return _notificationsStreamController.stream
        .map((notifications) => notifications.where((n) => n.userId == userId.value).toList());
  }

  @override
  Future<List<Notification>> getNotifications(UserId userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      return _notifications.where((notification) => notification.userId == userId.value).toList();
    } catch (e) {
      throw ServerException('Failed to get notifications: $e', code: 'NOTIFICATION_FETCH_ERROR');
    }
  }

  @override
  Future<void> createNotification(UserId userId, Notification notification) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      // Check if notification already exists
      final existingNotification = _notifications.where((n) => n.id == notification.id).firstOrNull;
      if (existingNotification != null) {
        throw ValidationException('Notification already exists', code: 'NOTIFICATION_ALREADY_EXISTS');
      }
      
      _notifications.add(notification);
      _notificationsStreamController.add(List.from(_notifications));
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to create notification: $e', code: 'NOTIFICATION_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateNotification(UserId userId, Notification notification) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification;
        _notificationsStreamController.add(List.from(_notifications));
      } else {
        throw NotFoundException('Notification not found', code: 'NOTIFICATION_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to update notification: $e', code: 'NOTIFICATION_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final initialLength = _notifications.length;
      _notifications.removeWhere((notification) => notification.id == notificationId);
      
      if (_notifications.length == initialLength) {
        throw NotFoundException('Notification not found', code: 'NOTIFICATION_NOT_FOUND');
      }
      
      _notificationsStreamController.add(List.from(_notifications));
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to delete notification: $e', code: 'NOTIFICATION_DELETE_ERROR');
    }
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].markAsRead();
        _notificationsStreamController.add(List.from(_notifications));
      } else {
        throw NotFoundException('Notification not found', code: 'NOTIFICATION_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to mark notification as read: $e', code: 'NOTIFICATION_MARK_READ_ERROR');
    }
  }

  @override
  Future<void> markNotificationAsUnread(String notificationId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].markAsUnread();
        _notificationsStreamController.add(List.from(_notifications));
      } else {
        throw NotFoundException('Notification not found', code: 'NOTIFICATION_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to mark notification as unread: $e', code: 'NOTIFICATION_MARK_UNREAD_ERROR');
    }
  }

  /// Dispose the stream controller
  void dispose() {
    _notificationsStreamController.close();
  }
} 