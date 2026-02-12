import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/push_notification.dart';
import '../../utils/logger.dart';

/// Service for managing notification preferences in SharedPreferences
class NotificationPreferencesService {
  static const String _prefix = 'notification_';
  static const String _morningRemindersKey = '${_prefix}morning_reminders';
  static const String _questAssignmentsKey = '${_prefix}quest_assignments';
  static const String _deadlineRemindersKey = '${_prefix}deadline_reminders';
  static const String _overdueAlertsKey = '${_prefix}overdue_alerts';
  static const String _approvalRequestsKey = '${_prefix}approval_requests';
  static const String _approvalResultsKey = '${_prefix}approval_results';
  static const String _levelUpsKey = '${_prefix}level_ups';
  static const String _streakMilestonesKey = '${_prefix}streak_milestones';
  static const String _familyActivityKey = '${_prefix}family_activity';
  static const String _rewardRedemptionKey = '${_prefix}reward_redemption';
  static const String _morningReminderTimeKey = '${_prefix}morning_time';
  static const String _quietHoursEnabledKey = '${_prefix}quiet_enabled';
  static const String _quietHoursStartKey = '${_prefix}quiet_start';
  static const String _quietHoursEndKey = '${_prefix}quiet_end';

  final AppLogger _logger = AppLogger();

  /// Get all notification preferences
  Future<NotificationPreferences> getPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return NotificationPreferences(
        morningRemindersEnabled:
            prefs.getBool(_morningRemindersKey) ?? true,
        questAssignmentsEnabled:
            prefs.getBool(_questAssignmentsKey) ?? true,
        deadlineRemindersEnabled:
            prefs.getBool(_deadlineRemindersKey) ?? true,
        overdueAlertsEnabled:
            prefs.getBool(_overdueAlertsKey) ?? true,
        approvalRequestsEnabled:
            prefs.getBool(_approvalRequestsKey) ?? true,
        approvalResultsEnabled:
            prefs.getBool(_approvalResultsKey) ?? true,
        levelUpsEnabled:
            prefs.getBool(_levelUpsKey) ?? true,
        streakMilestonesEnabled:
            prefs.getBool(_streakMilestonesKey) ?? true,
        familyActivityEnabled:
            prefs.getBool(_familyActivityKey) ?? false,
        rewardRedemptionEnabled:
            prefs.getBool(_rewardRedemptionKey) ?? true,
        morningReminderTime:
            _getTimeFromPrefs(prefs, _morningReminderTimeKey, 8, 0),
        quietHoursEnabled:
            prefs.getBool(_quietHoursEnabledKey) ?? false,
        quietHoursStart:
            _getTimeFromPrefs(prefs, _quietHoursStartKey, 22, 0),
        quietHoursEnd:
            _getTimeFromPrefs(prefs, _quietHoursEndKey, 8, 0),
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to load notification preferences',
        error: e,
        stackTrace: stackTrace,
      );
      return NotificationPreferences();
    }
  }

  /// Check if a specific notification type is enabled
  Future<bool> isTypeEnabled(PushNotificationType type) async {
    final prefs = await getPreferences();
    return prefs.isTypeEnabled(type);
  }

  /// Set notification type enabled/disabled
  Future<void> setTypeEnabled(PushNotificationType type, bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKeyForType(type);
      await prefs.setBool(key, enabled);
      _logger.i('Notification type ${type.name} set to $enabled');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to set notification type',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Set morning reminder time
  Future<void> setMorningReminderTime(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_morningReminderTimeKey, time.hour * 60 + time.minute);
      _logger.i('Morning reminder time set to ${time.hour}:${time.minute}');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to set morning reminder time',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Set quiet hours enabled/disabled
  Future<void> setQuietHoursEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_quietHoursEnabledKey, enabled);
      _logger.i('Quiet hours set to $enabled');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to set quiet hours',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Set quiet hours start time
  Future<void> setQuietHoursStart(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_quietHoursStartKey, time.hour * 60 + time.minute);
      _logger.i('Quiet hours start set to ${time.hour}:${time.minute}');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to set quiet hours start',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Set quiet hours end time
  Future<void> setQuietHoursEnd(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_quietHoursEndKey, time.hour * 60 + time.minute);
      _logger.i('Quiet hours end set to ${time.hour}:${time.minute}');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to set quiet hours end',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get DateTime from SharedPreferences (stored as minutes since midnight)
  DateTime _getTimeFromPrefs(
    SharedPreferences prefs,
    String key,
    int defaultHour,
    int defaultMinute,
  ) {
    final minutes = prefs.getInt(key);
    if (minutes == null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, defaultHour, defaultMinute);
    }

    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// Get SharedPreferences key for notification type
  String _getKeyForType(PushNotificationType type) {
    switch (type) {
      case PushNotificationType.morningReminder:
        return _morningRemindersKey;
      case PushNotificationType.questAssignment:
        return _questAssignmentsKey;
      case PushNotificationType.questReminder:
        return _deadlineRemindersKey;
      case PushNotificationType.questOverdue:
        return _overdueAlertsKey;
      case PushNotificationType.approvalRequest:
        return _approvalRequestsKey;
      case PushNotificationType.approvalResult:
        return _approvalResultsKey;
      case PushNotificationType.levelUp:
        return _levelUpsKey;
      case PushNotificationType.streakMilestone:
        return _streakMilestonesKey;
      case PushNotificationType.familyActivity:
        return _familyActivityKey;
      case PushNotificationType.rewardRedemption:
        return _rewardRedemptionKey;
    }
  }
}
