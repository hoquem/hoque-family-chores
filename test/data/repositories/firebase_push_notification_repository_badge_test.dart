import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/repositories/firebase_push_notification_repository.dart';
import 'package:hoque_family_chores/data/services/notification_preferences_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class _MockNotificationPreferencesService extends Mock
    implements NotificationPreferencesService {}

class _MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class _FakeNotificationDetails extends Fake implements NotificationDetails {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeNotificationDetails());
  });

  late _MockFlutterLocalNotificationsPlugin localNotifications;
  late FirebasePushNotificationRepository repository;

  setUp(() {
    localNotifications = _MockFlutterLocalNotificationsPlugin();
    repository = FirebasePushNotificationRepository(
      firebaseMessaging: _MockFirebaseMessaging(),
      localNotifications: localNotifications,
      preferencesService: _MockNotificationPreferencesService(),
    );
    when(() => localNotifications.show(any(), any(), any(), any()))
        .thenAnswer((_) async {});
    when(() => localNotifications.cancel(any())).thenAnswer((_) async {});
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('updateBadgeCount', () {
    // The badge notification carries iOS details only. On Android the plugin
    // builds a notification channel from the missing Android details and
    // throws a NullPointerException (null importance), so it must not be sent.
    test('does not post a notification on Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await repository.updateBadgeCount(3);

      verifyNever(() => localNotifications.show(any(), any(), any(), any()));
    });

    test('posts and cancels the silent badge notification on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await repository.updateBadgeCount(3);

      final details = verify(
        () => localNotifications.show(any(), any(), any(), captureAny()),
      ).captured.single as NotificationDetails;
      expect(details.iOS?.badgeNumber, 3);
      verify(() => localNotifications.cancel(any())).called(1);
    });
  });
}
