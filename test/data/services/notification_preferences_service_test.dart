import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/services/notification_preferences_service.dart';
import 'package:hoque_family_chores/domain/entities/push_notification.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late NotificationPreferencesService service;

  setUp(() {
    service = NotificationPreferencesService();
  });

  group('NotificationPreferencesService', () {
    test('getPreferences returns default preferences when no data stored',
        () async {
      SharedPreferences.setMockInitialValues({});

      final prefs = await service.getPreferences();

      expect(prefs.morningRemindersEnabled, true);
      expect(prefs.questAssignmentsEnabled, true);
      expect(prefs.familyActivityEnabled, false); // Default OFF
      expect(prefs.quietHoursEnabled, false);
    });

    test('setTypeEnabled stores preference correctly', () async {
      SharedPreferences.setMockInitialValues({});

      await service.setTypeEnabled(
        PushNotificationType.morningReminder,
        false,
      );

      final prefs = await service.getPreferences();
      expect(prefs.morningRemindersEnabled, false);
    });

    test('setMorningReminderTime stores time correctly', () async {
      SharedPreferences.setMockInitialValues({});

      final time = DateTime(2024, 1, 1, 9, 30);
      await service.setMorningReminderTime(time);

      final prefs = await service.getPreferences();
      expect(prefs.morningReminderTime.hour, 9);
      expect(prefs.morningReminderTime.minute, 30);
    });

    test('setQuietHoursEnabled stores setting correctly', () async {
      SharedPreferences.setMockInitialValues({});

      await service.setQuietHoursEnabled(true);

      final prefs = await service.getPreferences();
      expect(prefs.quietHoursEnabled, true);
    });

    test('quiet hours times are stored and retrieved correctly', () async {
      SharedPreferences.setMockInitialValues({});

      final startTime = DateTime(2024, 1, 1, 22, 0);
      final endTime = DateTime(2024, 1, 1, 8, 0);

      await service.setQuietHoursStart(startTime);
      await service.setQuietHoursEnd(endTime);

      final prefs = await service.getPreferences();
      expect(prefs.quietHoursStart.hour, 22);
      expect(prefs.quietHoursStart.minute, 0);
      expect(prefs.quietHoursEnd.hour, 8);
      expect(prefs.quietHoursEnd.minute, 0);
    });

    test('isTypeEnabled checks preferences correctly', () async {
      SharedPreferences.setMockInitialValues({
        'notification_morning_reminders': false,
      });

      final enabled = await service.isTypeEnabled(
        PushNotificationType.morningReminder,
      );

      expect(enabled, false);
    });
  });
}
