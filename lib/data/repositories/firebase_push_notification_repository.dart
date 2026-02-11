import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../domain/repositories/push_notification_repository.dart';
import '../../domain/entities/push_notification.dart';
import '../../utils/logger.dart';
import '../services/notification_preferences_service.dart';

/// Firebase implementation of push notification repository
class FirebasePushNotificationRepository implements PushNotificationRepository {
  final FirebaseMessaging _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final NotificationPreferencesService _preferencesService;
  final AppLogger _logger = AppLogger();

  FirebasePushNotificationRepository({
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    NotificationPreferencesService? preferencesService,
  })  : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin(),
        _preferencesService =
            preferencesService ?? NotificationPreferencesService();

  @override
  Future<void> initialize() async {
    try {
      _logger.i('[FCM] Initializing push notifications...');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Create notification channels (Android)
      await _createNotificationChannels();

      // Request permissions
      await requestPermissions();

      // Get and log FCM token
      final token = await getToken();
      _logger.i('[FCM] Device token: $token');

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _logger.i('[FCM] Token refreshed: $newToken');
        // TODO: Send token to backend
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps (background/terminated)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

      // Handle notification tap when app is terminated
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _logger.i('[FCM] App opened from terminated state via notification');
        _handleNotificationOpen(initialMessage);
      }

      _logger.i('[FCM] Push notifications initialized successfully');
    } catch (e, stackTrace) {
      _logger.e(
        '[FCM] Failed to initialize push notifications',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // High priority channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'high_priority',
        'Important Updates',
        description: 'Approvals and time-sensitive notifications',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
    );

    // Medium priority channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'medium_priority',
        'Quest Notifications',
        description: 'Quest assignments and reminders',
        importance: Importance.defaultImportance,
        enableVibration: true,
        playSound: true,
      ),
    );

    // Low priority channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'low_priority',
        'Achievements & Updates',
        description: 'Levels, streaks, and family activity',
        importance: Importance.low,
        enableVibration: false,
        playSound: false,
      ),
    );

    _logger.i('[FCM] Notification channels created');
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final enabled = settings.authorizationStatus == AuthorizationStatus.authorized;
      _logger.i('[FCM] Notification permissions: $enabled');
      return enabled;
    } catch (e, stackTrace) {
      _logger.e(
        '[FCM] Failed to request permissions',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e, stackTrace) {
      _logger.e(
        '[FCM] Failed to check notification status',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e, stackTrace) {
      _logger.e(
        '[FCM] Failed to get token',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> sendNotification(PushNotificationPayload payload) async {
    try {
      // Check if notification type is enabled
      final prefs = await _preferencesService.getPreferences();
      if (!prefs.isTypeEnabled(payload.type)) {
        _logger.i('[FCM] Notification type ${payload.type.name} is disabled');
        return;
      }

      // Check quiet hours
      if (prefs.isInQuietHours() && payload.priority != NotificationPriority.high) {
        _logger.i('[FCM] Notification delayed due to quiet hours');
        // Calculate when quiet hours end and schedule
        final nextDelivery = _calculateQuietHoursEnd(prefs);
        await scheduleNotification(payload, nextDelivery);
        return;
      }

      // Show notification
      await _showLocalNotification(payload);
    } catch (e, stackTrace) {
      _logger.e(
        '[FCM] Failed to send notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> scheduleNotification(
    PushNotificationPayload payload,
    DateTime scheduledTime,
  ) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        payload.getChannelId(),
        _getChannelName(payload.getChannelId()),
        channelDescription: _getChannelDescription(payload.getChannelId()),
        importance: Importance.values[payload.priority.toAndroidImportance()],
        priority: Priority.values[payload.priority.toAndroidPriority() + 2],
        icon: payload.icon ?? '@mipmap/ic_launcher',
        color: const Color(0xFF6750A4),
        groupKey: payload.getGroupKey(),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: payload.getGroupKey(),
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        payload.id,
        payload.title,
        payload.body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: json.encode(payload.data),
      );

      _logger.i(
        '[FCM] Notification scheduled for $scheduledTime: ${payload.title}',
      );
    } catch (e, stackTrace) {
      _logger.e(
        '[FCM] Failed to schedule notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _localNotifications.cancel(notificationId);
      _logger.i('[FCM] Cancelled notification: $notificationId');
    } catch (e, stackTrace) {
      _logger.e(
        '[FCM] Failed to cancel notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      _logger.i('[FCM] Cancelled all notifications');
    } catch (e, stackTrace) {
      _logger.e(
        '[FCM] Failed to cancel all notifications',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    try {
      final deepLink = data['deepLink'] as String?;
      if (deepLink != null) {
        _logger.i('[FCM] Handling deep link: $deepLink');
        // TODO: Implement deep link navigation
      }
    } catch (e, stackTrace) {
      _logger.e(
        '[FCM] Failed to handle notification tap',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> sendTestNotification() async {
    final payload = PushNotificationPayload(
      id: DateTime.now().millisecondsSinceEpoch,
      type: PushNotificationType.morningReminder,
      title: 'Test Notification 🧪',
      body: 'If you see this, notifications are working!',
      priority: NotificationPriority.high,
      deepLink: 'choresapp://home',
      data: {'test': true},
    );

    await sendNotification(payload);
  }

  /// Show local notification
  Future<void> _showLocalNotification(PushNotificationPayload payload) async {
    final androidDetails = AndroidNotificationDetails(
      payload.getChannelId(),
      _getChannelName(payload.getChannelId()),
      channelDescription: _getChannelDescription(payload.getChannelId()),
      importance: Importance.values[payload.priority.toAndroidImportance()],
      priority: Priority.values[payload.priority.toAndroidPriority() + 2],
      icon: payload.icon ?? '@mipmap/ic_launcher',
      color: const Color(0xFF6750A4),
      groupKey: payload.getGroupKey(),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: payload.getGroupKey(),
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      payload.id,
      payload.title,
      payload.body,
      details,
      payload: json.encode(payload.data),
    );

    _logger.i('[FCM] Notification shown: ${payload.title}');
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('[FCM] Foreground message received: ${message.notification?.title}');
    // Show as in-app notification or local notification
    if (message.notification != null) {
      final payload = PushNotificationPayload(
        id: DateTime.now().millisecondsSinceEpoch,
        type: _parseNotificationType(message.data),
        title: message.notification!.title ?? '',
        body: message.notification!.body ?? '',
        priority: _parsePriority(message.data),
        deepLink: message.data['deepLink'] ?? 'choresapp://home',
        data: message.data,
      );

      sendNotification(payload);
    }
  }

  /// Handle notification opened
  void _handleNotificationOpen(RemoteMessage message) {
    _logger.i('[FCM] Notification opened: ${message.notification?.title}');
    handleNotificationTap(message.data);
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!) as Map<String, dynamic>;
        handleNotificationTap(data);
      } catch (e, stackTrace) {
        _logger.e(
          '[FCM] Failed to parse notification payload',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Calculate when quiet hours end
  DateTime _calculateQuietHoursEnd(NotificationPreferences prefs) {
    final now = DateTime.now();
    final endHour = prefs.quietHoursEnd.hour;
    final endMinute = prefs.quietHoursEnd.minute;

    var nextDelivery = DateTime(
      now.year,
      now.month,
      now.day,
      endHour,
      endMinute,
    );

    // If end time is earlier than now, it's tomorrow
    if (nextDelivery.isBefore(now)) {
      nextDelivery = nextDelivery.add(const Duration(days: 1));
    }

    return nextDelivery;
  }

  /// Parse notification type from data
  PushNotificationType _parseNotificationType(Map<String, dynamic> data) {
    final typeString = data['type'] as String?;
    if (typeString == null) return PushNotificationType.morningReminder;

    try {
      return PushNotificationType.values.firstWhere(
        (type) => type.name == typeString,
        orElse: () => PushNotificationType.morningReminder,
      );
    } catch (e) {
      return PushNotificationType.morningReminder;
    }
  }

  /// Parse priority from data
  NotificationPriority _parsePriority(Map<String, dynamic> data) {
    final priorityString = data['priority'] as String?;
    if (priorityString == null) return NotificationPriority.medium;

    try {
      return NotificationPriority.values.firstWhere(
        (priority) => priority.name == priorityString,
        orElse: () => NotificationPriority.medium,
      );
    } catch (e) {
      return NotificationPriority.medium;
    }
  }

  /// Get channel name
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'high_priority':
        return 'Important Updates';
      case 'medium_priority':
        return 'Quest Notifications';
      case 'low_priority':
        return 'Achievements & Updates';
      default:
        return 'Notifications';
    }
  }

  /// Get channel description
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'high_priority':
        return 'Approvals and time-sensitive notifications';
      case 'medium_priority':
        return 'Quest assignments and reminders';
      case 'low_priority':
        return 'Levels, streaks, and family activity';
      default:
        return 'App notifications';
    }
  }
}
