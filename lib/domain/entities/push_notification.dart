import 'package:equatable/equatable.dart';

/// Enum for notification types
enum PushNotificationType {
  morningReminder,
  questAssignment,
  questReminder,
  questOverdue,
  approvalRequest,
  approvalResult,
  levelUp,
  streakMilestone,
  familyActivity,
  rewardRedemption,
}

/// Enum for notification priority
enum NotificationPriority {
  low,
  medium,
  high;

  /// Convert to Android importance level
  int toAndroidImportance() {
    switch (this) {
      case low:
        return 2; // IMPORTANCE_LOW
      case medium:
        return 3; // IMPORTANCE_DEFAULT
      case high:
        return 4; // IMPORTANCE_HIGH
    }
  }

  /// Convert to Android priority
  int toAndroidPriority() {
    switch (this) {
      case low:
        return -1; // PRIORITY_LOW
      case medium:
        return 0; // PRIORITY_DEFAULT
      case high:
        return 1; // PRIORITY_HIGH
    }
  }
}

/// Domain entity for push notification payloads
class PushNotificationPayload extends Equatable {
  final int id;
  final PushNotificationType type;
  final String title;
  final String body;
  final String? icon;
  final NotificationPriority priority;
  final String deepLink;
  final Map<String, dynamic> data;
  final DateTime? scheduledTime;

  const PushNotificationPayload({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.icon,
    this.priority = NotificationPriority.medium,
    required this.deepLink,
    this.data = const {},
    this.scheduledTime,
  });

  /// Get notification channel ID based on priority
  String getChannelId() {
    switch (priority) {
      case NotificationPriority.high:
        return 'high_priority';
      case NotificationPriority.medium:
        return 'medium_priority';
      case NotificationPriority.low:
        return 'low_priority';
    }
  }

  /// Get notification group key
  String getGroupKey() {
    switch (type) {
      case PushNotificationType.morningReminder:
      case PushNotificationType.questAssignment:
      case PushNotificationType.questReminder:
      case PushNotificationType.questOverdue:
        return 'quests';
      case PushNotificationType.approvalRequest:
      case PushNotificationType.approvalResult:
        return 'approvals';
      case PushNotificationType.levelUp:
      case PushNotificationType.streakMilestone:
        return 'achievements';
      case PushNotificationType.familyActivity:
      case PushNotificationType.rewardRedemption:
        return 'family';
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        body,
        icon,
        priority,
        deepLink,
        data,
        scheduledTime,
      ];
}

/// Notification preferences
class NotificationPreferences extends Equatable {
  final bool morningRemindersEnabled;
  final bool questAssignmentsEnabled;
  final bool deadlineRemindersEnabled;
  final bool overdueAlertsEnabled;
  final bool approvalRequestsEnabled;
  final bool approvalResultsEnabled;
  final bool levelUpsEnabled;
  final bool streakMilestonesEnabled;
  final bool familyActivityEnabled;
  final bool rewardRedemptionEnabled;
  final DateTime morningReminderTime;
  final bool quietHoursEnabled;
  final DateTime quietHoursStart;
  final DateTime quietHoursEnd;

  NotificationPreferences({
    this.morningRemindersEnabled = true,
    this.questAssignmentsEnabled = true,
    this.deadlineRemindersEnabled = true,
    this.overdueAlertsEnabled = true,
    this.approvalRequestsEnabled = true,
    this.approvalResultsEnabled = true,
    this.levelUpsEnabled = true,
    this.streakMilestonesEnabled = true,
    this.familyActivityEnabled = false,
    this.rewardRedemptionEnabled = true,
    DateTime? morningReminderTime,
    this.quietHoursEnabled = false,
    DateTime? quietHoursStart,
    DateTime? quietHoursEnd,
  })  : morningReminderTime = morningReminderTime ?? _createDefaultTime(8, 0),
        quietHoursStart = quietHoursStart ?? _createDefaultTime(22, 0),
        quietHoursEnd = quietHoursEnd ?? _createDefaultTime(8, 0);

  static DateTime _createDefaultTime(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// Check if notification type is enabled
  bool isTypeEnabled(PushNotificationType type) {
    switch (type) {
      case PushNotificationType.morningReminder:
        return morningRemindersEnabled;
      case PushNotificationType.questAssignment:
        return questAssignmentsEnabled;
      case PushNotificationType.questReminder:
        return deadlineRemindersEnabled;
      case PushNotificationType.questOverdue:
        return overdueAlertsEnabled;
      case PushNotificationType.approvalRequest:
        return approvalRequestsEnabled;
      case PushNotificationType.approvalResult:
        return approvalResultsEnabled;
      case PushNotificationType.levelUp:
        return levelUpsEnabled;
      case PushNotificationType.streakMilestone:
        return streakMilestonesEnabled;
      case PushNotificationType.familyActivity:
        return familyActivityEnabled;
      case PushNotificationType.rewardRedemption:
        return rewardRedemptionEnabled;
    }
  }

  /// Check if current time is in quiet hours
  bool isInQuietHours([DateTime? time]) {
    if (!quietHoursEnabled) return false;

    final now = time ?? DateTime.now();
    final currentTime = now.hour * 60 + now.minute;
    final startTime = quietHoursStart.hour * 60 + quietHoursStart.minute;
    final endTime = quietHoursEnd.hour * 60 + quietHoursEnd.minute;

    if (startTime < endTime) {
      // Normal case: 22:00 to 08:00 next day doesn't cross midnight in this check
      // This case handles same-day ranges like 10:00 to 18:00
      return currentTime >= startTime && currentTime < endTime;
    } else {
      // Crosses midnight: 22:00 to 08:00
      return currentTime >= startTime || currentTime < endTime;
    }
  }

  @override
  List<Object?> get props => [
        morningRemindersEnabled,
        questAssignmentsEnabled,
        deadlineRemindersEnabled,
        overdueAlertsEnabled,
        approvalRequestsEnabled,
        approvalResultsEnabled,
        levelUpsEnabled,
        streakMilestonesEnabled,
        familyActivityEnabled,
        rewardRedemptionEnabled,
        morningReminderTime,
        quietHoursEnabled,
        quietHoursStart,
        quietHoursEnd,
      ];
}
