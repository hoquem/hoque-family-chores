import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/push_notification.dart';

void main() {
  group('NotificationPreferences', () {
    test('isTypeEnabled returns correct value for each type', () {
      final prefs = NotificationPreferences(
        morningRemindersEnabled: true,
        questAssignmentsEnabled: false,
        levelUpsEnabled: true,
      );

      expect(
        prefs.isTypeEnabled(PushNotificationType.morningReminder),
        true,
      );
      expect(
        prefs.isTypeEnabled(PushNotificationType.questAssignment),
        false,
      );
      expect(
        prefs.isTypeEnabled(PushNotificationType.levelUp),
        true,
      );
    });

    test('isInQuietHours returns false when quiet hours disabled', () {
      final prefs = NotificationPreferences(quietHoursEnabled: false);

      final result = prefs.isInQuietHours();
      expect(result, false);
    });

    test('isInQuietHours detects time within quiet hours', () {
      final prefs = NotificationPreferences(
        quietHoursEnabled: true,
        quietHoursStart: DateTime(2024, 1, 1, 22, 0), // 10 PM
        quietHoursEnd: DateTime(2024, 1, 1, 8, 0), // 8 AM
      );

      // Test time at 11 PM (within quiet hours)
      final elevenPm = DateTime(2024, 1, 1, 23, 0);
      expect(prefs.isInQuietHours(elevenPm), true);

      // Test time at 3 AM (within quiet hours - crosses midnight)
      final threeAm = DateTime(2024, 1, 2, 3, 0);
      expect(prefs.isInQuietHours(threeAm), true);

      // Test time at 10 AM (outside quiet hours)
      final tenAm = DateTime(2024, 1, 1, 10, 0);
      expect(prefs.isInQuietHours(tenAm), false);
    });

    test('isInQuietHours handles same-day quiet hours', () {
      final prefs = NotificationPreferences(
        quietHoursEnabled: true,
        quietHoursStart: DateTime(2024, 1, 1, 12, 0), // 12 PM
        quietHoursEnd: DateTime(2024, 1, 1, 18, 0), // 6 PM
      );

      // Test time at 2 PM (within quiet hours)
      final twoPm = DateTime(2024, 1, 1, 14, 0);
      expect(prefs.isInQuietHours(twoPm), true);

      // Test time at 10 AM (before quiet hours)
      final tenAm = DateTime(2024, 1, 1, 10, 0);
      expect(prefs.isInQuietHours(tenAm), false);

      // Test time at 8 PM (after quiet hours)
      final eightPm = DateTime(2024, 1, 1, 20, 0);
      expect(prefs.isInQuietHours(eightPm), false);
    });
  });

  group('PushNotificationPayload', () {
    test('getChannelId returns correct channel for priority', () {
      final highPriority = PushNotificationPayload(
        id: 1,
        type: PushNotificationType.approvalRequest,
        title: 'Test',
        body: 'Test',
        priority: NotificationPriority.high,
        deepLink: 'choresapp://home',
      );

      expect(highPriority.getChannelId(), 'high_priority');

      final lowPriority = PushNotificationPayload(
        id: 2,
        type: PushNotificationType.morningReminder,
        title: 'Test',
        body: 'Test',
        priority: NotificationPriority.low,
        deepLink: 'choresapp://home',
      );

      expect(lowPriority.getChannelId(), 'low_priority');
    });

    test('getGroupKey returns correct group for type', () {
      final questNotification = PushNotificationPayload(
        id: 1,
        type: PushNotificationType.questAssignment,
        title: 'Test',
        body: 'Test',
        deepLink: 'choresapp://home',
      );

      expect(questNotification.getGroupKey(), 'quests');

      final approvalNotification = PushNotificationPayload(
        id: 2,
        type: PushNotificationType.approvalRequest,
        title: 'Test',
        body: 'Test',
        deepLink: 'choresapp://home',
      );

      expect(approvalNotification.getGroupKey(), 'approvals');

      final achievementNotification = PushNotificationPayload(
        id: 3,
        type: PushNotificationType.levelUp,
        title: 'Test',
        body: 'Test',
        deepLink: 'choresapp://home',
      );

      expect(achievementNotification.getGroupKey(), 'achievements');
    });
  });

  group('NotificationPriority', () {
    test('toAndroidImportance returns correct values', () {
      expect(NotificationPriority.low.toAndroidImportance(), 2);
      expect(NotificationPriority.medium.toAndroidImportance(), 3);
      expect(NotificationPriority.high.toAndroidImportance(), 4);
    });

    test('toAndroidPriority returns correct values', () {
      expect(NotificationPriority.low.toAndroidPriority(), -1);
      expect(NotificationPriority.medium.toAndroidPriority(), 0);
      expect(NotificationPriority.high.toAndroidPriority(), 1);
    });
  });
}
