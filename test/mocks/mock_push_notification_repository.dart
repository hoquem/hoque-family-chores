import 'package:hoque_family_chores/domain/repositories/push_notification_repository.dart';
import 'package:hoque_family_chores/domain/entities/push_notification.dart';
import 'package:hoque_family_chores/utils/logger.dart';

/// Mock implementation of push notification repository for testing
class MockPushNotificationRepository implements PushNotificationRepository {
  final AppLogger _logger = AppLogger();
  final List<PushNotificationPayload> _sentNotifications = [];
  final List<PushNotificationPayload> _scheduledNotifications = [];
  bool _initialized = false;
  bool _permissionsGranted = true;
  String? _mockToken = 'mock_fcm_token_123456';

  /// Get list of sent notifications (for testing)
  List<PushNotificationPayload> get sentNotifications => List.unmodifiable(_sentNotifications);

  /// Get list of scheduled notifications (for testing)
  List<PushNotificationPayload> get scheduledNotifications =>
      List.unmodifiable(_scheduledNotifications);

  /// Reset mock state
  void reset() {
    _sentNotifications.clear();
    _scheduledNotifications.clear();
    _initialized = false;
    _permissionsGranted = true;
    _mockToken = 'mock_fcm_token_123456';
  }

  /// Set mock permissions
  void setPermissionsGranted(bool granted) {
    _permissionsGranted = granted;
  }

  @override
  Future<void> initialize() async {
    _logger.i('[MockFCM] Initializing mock push notifications...');
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate async
    _initialized = true;
    _logger.i('[MockFCM] Mock push notifications initialized');
  }

  @override
  Future<bool> requestPermissions() async {
    _logger.i('[MockFCM] Requesting mock permissions...');
    await Future.delayed(const Duration(milliseconds: 50));
    _logger.i('[MockFCM] Mock permissions: $_permissionsGranted');
    return _permissionsGranted;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    return _permissionsGranted;
  }

  @override
  Future<String?> getToken() async {
    _logger.i('[MockFCM] Getting mock token: $_mockToken');
    return _mockToken;
  }

  @override
  Future<void> sendNotification(PushNotificationPayload payload) async {
    if (!_initialized) {
      _logger.w('[MockFCM] Attempted to send notification before initialization');
      return;
    }

    if (!_permissionsGranted) {
      _logger.w('[MockFCM] Cannot send notification - permissions not granted');
      return;
    }

    _sentNotifications.add(payload);
    _logger.i('[MockFCM] Mock notification sent: ${payload.title}');
    _logger.i('[MockFCM]   Type: ${payload.type.name}');
    _logger.i('[MockFCM]   Body: ${payload.body}');
    _logger.i('[MockFCM]   Priority: ${payload.priority.name}');
    _logger.i('[MockFCM]   Deep link: ${payload.deepLink}');
  }

  @override
  Future<void> scheduleNotification(
    PushNotificationPayload payload,
    DateTime scheduledTime,
  ) async {
    if (!_initialized) {
      _logger.w('[MockFCM] Attempted to schedule notification before initialization');
      return;
    }

    if (!_permissionsGranted) {
      _logger.w('[MockFCM] Cannot schedule notification - permissions not granted');
      return;
    }

    final scheduledPayload = payload;
    _scheduledNotifications.add(scheduledPayload);
    _logger.i('[MockFCM] Mock notification scheduled for $scheduledTime: ${payload.title}');
    _logger.i('[MockFCM]   Type: ${payload.type.name}');
    _logger.i('[MockFCM]   Body: ${payload.body}');
  }

  @override
  Future<void> cancelNotification(int notificationId) async {
    _scheduledNotifications.removeWhere((n) => n.id == notificationId);
    _logger.i('[MockFCM] Mock notification cancelled: $notificationId');
  }

  @override
  Future<void> cancelAllNotifications() async {
    _scheduledNotifications.clear();
    _logger.i('[MockFCM] All mock notifications cancelled');
  }

  @override
  Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    final deepLink = data['deepLink'] as String?;
    _logger.i('[MockFCM] Mock handling notification tap');
    _logger.i('[MockFCM]   Deep link: $deepLink');
    _logger.i('[MockFCM]   Data: $data');
  }

  @override
  Future<void> sendTestNotification() async {
    final payload = PushNotificationPayload(
      id: DateTime.now().millisecondsSinceEpoch,
      type: PushNotificationType.morningReminder,
      title: 'Test Notification 🧪',
      body: 'If you see this, mock notifications are working!',
      priority: NotificationPriority.high,
      deepLink: 'choresapp://home',
      data: const {'test': true},
    );

    await sendNotification(payload);
  }
}
