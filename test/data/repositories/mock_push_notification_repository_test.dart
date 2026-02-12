import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/repositories/mock_push_notification_repository.dart';
import 'package:hoque_family_chores/domain/entities/push_notification.dart';

void main() {
  late MockPushNotificationRepository repository;

  setUp(() {
    repository = MockPushNotificationRepository();
  });

  tearDown(() {
    repository.reset();
  });

  group('MockPushNotificationRepository', () {
    test('initialize sets initialized flag', () async {
      await repository.initialize();

      // Verify by trying to send a notification
      final payload = PushNotificationPayload(
        id: 1,
        type: PushNotificationType.morningReminder,
        title: 'Test',
        body: 'Test body',
        deepLink: 'choresapp://home',
      );

      await repository.sendNotification(payload);
      expect(repository.sentNotifications, hasLength(1));
    });

    test('requestPermissions returns mock permissions status', () async {
      repository.setPermissionsGranted(true);
      final granted = await repository.requestPermissions();
      expect(granted, true);

      repository.setPermissionsGranted(false);
      final denied = await repository.requestPermissions();
      expect(denied, false);
    });

    test('getToken returns mock token', () async {
      final token = await repository.getToken();
      expect(token, 'mock_fcm_token_123456');
    });

    test('sendNotification adds to sentNotifications list', () async {
      await repository.initialize();

      final payload = PushNotificationPayload(
        id: 1,
        type: PushNotificationType.morningReminder,
        title: 'Morning Reminder',
        body: 'You have 3 quests today',
        deepLink: 'choresapp://home',
      );

      await repository.sendNotification(payload);

      expect(repository.sentNotifications, hasLength(1));
      expect(repository.sentNotifications.first.title, 'Morning Reminder');
      expect(repository.sentNotifications.first.type,
          PushNotificationType.morningReminder);
    });

    test('sendNotification respects permissions', () async {
      await repository.initialize();
      repository.setPermissionsGranted(false);

      final payload = PushNotificationPayload(
        id: 1,
        type: PushNotificationType.morningReminder,
        title: 'Test',
        body: 'Test',
        deepLink: 'choresapp://home',
      );

      await repository.sendNotification(payload);

      expect(repository.sentNotifications, isEmpty);
    });

    test('scheduleNotification adds to scheduledNotifications list', () async {
      await repository.initialize();

      final payload = PushNotificationPayload(
        id: 2,
        type: PushNotificationType.questReminder,
        title: 'Quest Reminder',
        body: 'Quest due in 1 hour',
        deepLink: 'choresapp://quest/123',
      );

      final scheduledTime = DateTime.now().add(const Duration(hours: 1));
      await repository.scheduleNotification(payload, scheduledTime);

      expect(repository.scheduledNotifications, hasLength(1));
      expect(repository.scheduledNotifications.first.title, 'Quest Reminder');
    });

    test('cancelNotification removes scheduled notification', () async {
      await repository.initialize();

      final payload = PushNotificationPayload(
        id: 3,
        type: PushNotificationType.questReminder,
        title: 'Quest Reminder',
        body: 'Test',
        deepLink: 'choresapp://home',
      );

      await repository.scheduleNotification(
        payload,
        DateTime.now().add(const Duration(hours: 1)),
      );
      expect(repository.scheduledNotifications, hasLength(1));

      await repository.cancelNotification(3);
      expect(repository.scheduledNotifications, isEmpty);
    });

    test('cancelAllNotifications clears all scheduled notifications', () async {
      await repository.initialize();

      for (int i = 0; i < 3; i++) {
        final payload = PushNotificationPayload(
          id: i,
          type: PushNotificationType.questReminder,
          title: 'Reminder $i',
          body: 'Test',
          deepLink: 'choresapp://home',
        );
        await repository.scheduleNotification(
          payload,
          DateTime.now().add(Duration(hours: i + 1)),
        );
      }

      expect(repository.scheduledNotifications, hasLength(3));

      await repository.cancelAllNotifications();
      expect(repository.scheduledNotifications, isEmpty);
    });

    test('sendTestNotification sends test notification', () async {
      await repository.initialize();

      await repository.sendTestNotification();

      expect(repository.sentNotifications, hasLength(1));
      expect(repository.sentNotifications.first.title, contains('Test'));
      expect(repository.sentNotifications.first.data['test'], true);
    });

    test('reset clears all state', () async {
      await repository.initialize();

      await repository.sendTestNotification();
      expect(repository.sentNotifications, hasLength(1));

      repository.reset();

      expect(repository.sentNotifications, isEmpty);
      expect(repository.scheduledNotifications, isEmpty);
    });
  });
}
