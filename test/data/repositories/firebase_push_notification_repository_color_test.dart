import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:hoque_family_chores/data/repositories/firebase_push_notification_repository.dart';
import 'package:hoque_family_chores/data/services/notification_preferences_service.dart';
import 'package:hoque_family_chores/domain/entities/push_notification.dart';
import 'package:mocktail/mocktail.dart';

class _MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class _MockNotificationPreferencesService extends Mock
    implements NotificationPreferencesService {}

class _MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class _FakeTZDateTime extends Fake implements tz.TZDateTime {}

class _FakeNotificationDetails extends Fake implements NotificationDetails {}

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(_FakeTZDateTime());
    registerFallbackValue(_FakeNotificationDetails());
  });

  late _MockFlutterLocalNotificationsPlugin localNotifications;
  late _MockNotificationPreferencesService preferencesService;
  late _MockFirebaseMessaging firebaseMessaging;
  late FirebasePushNotificationRepository repository;

  setUp(() {
    localNotifications = _MockFlutterLocalNotificationsPlugin();
    preferencesService = _MockNotificationPreferencesService();
    firebaseMessaging = _MockFirebaseMessaging();
    repository = FirebasePushNotificationRepository(
      firebaseMessaging: firebaseMessaging,
      localNotifications: localNotifications,
      preferencesService: preferencesService,
    );

    when(() => preferencesService.getPreferences())
        .thenAnswer((_) async => NotificationPreferences());
  });

  group('FirebasePushNotificationRepository notification color', () {
    test('sendNotification uses the app marigold accent, not M3 purple',
        () async {
      when(() => localNotifications.show(
            any(),
            any(),
            any(),
            any(),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => {});

      final payload = PushNotificationPayload(
        id: 1,
        type: PushNotificationType.approvalRequest,
        title: 'Test',
        body: 'Body',
        deepLink: 'choresapp://home',
      );

      await repository.sendNotification(payload);

      final captured = verify(() => localNotifications.show(
            any(),
            any(),
            any(),
            captureAny(),
            payload: any(named: 'payload'),
          )).captured.single as NotificationDetails;

      expect(captured.android, isNotNull);
      expect(
        captured.android!.color,
        const Color(0xFFE08A1E),
        reason: 'Notifications must use the app marigold accent, '
            'not the Material 3 default purple',
      );
      expect(captured.android!.color, isNot(const Color(0xFF6750A4)));
    });

    test('scheduleNotification uses the app marigold accent, not M3 purple',
        () async {
      when(() => localNotifications.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => {});

      final payload = PushNotificationPayload(
        id: 2,
        type: PushNotificationType.approvalRequest,
        title: 'Scheduled',
        body: 'Body',
        deepLink: 'choresapp://home',
      );

      await repository.scheduleNotification(
        payload,
        DateTime.now().add(const Duration(hours: 1)),
      );

      final captured = verify(() => localNotifications.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            captureAny(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: any(named: 'payload'),
          )).captured.single as NotificationDetails;

      expect(captured.android, isNotNull);
      expect(
        captured.android!.color,
        const Color(0xFFE08A1E),
        reason: 'Scheduled notifications must use the app marigold accent, '
            'not the Material 3 default purple',
      );
    });
  });
}
