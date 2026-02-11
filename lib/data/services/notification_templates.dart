import '../../domain/entities/push_notification.dart';

/// Service for creating notification payloads with proper templates
class NotificationTemplates {
  /// Create morning reminder notification
  static PushNotificationPayload morningReminder({
    required int questCount,
    int? streakDays,
  }) {
    String body;
    if (streakDays != null && streakDays >= 3) {
      body = "Complete today's quests to keep your $streakDays-day streak alive";
    } else if (questCount == 1) {
      body = "You have 1 quest waiting";
    } else {
      body = "You have $questCount quests to complete today";
    }

    return PushNotificationPayload(
      id: _generateId(PushNotificationType.morningReminder),
      type: PushNotificationType.morningReminder,
      title: streakDays != null && streakDays >= 3
          ? "Don't break your streak! 🔥"
          : "Good morning! 🌅",
      body: body,
      priority: NotificationPriority.low,
      deepLink: 'choresapp://home',
      data: {
        'questCount': questCount,
        if (streakDays != null) 'streakDays': streakDays,
      },
    );
  }

  /// Create quest assignment notification
  static PushNotificationPayload questAssignment({
    required String questId,
    required String questName,
    DateTime? dueDate,
    bool isUrgent = false,
  }) {
    final title = isUrgent ? 'Urgent quest! 🚨' : 'New quest assigned 📋';
    final dueText = dueDate != null ? ' — due ${_formatDueDate(dueDate)}' : '';

    return PushNotificationPayload(
      id: _generateId(PushNotificationType.questAssignment, questId),
      type: PushNotificationType.questAssignment,
      title: title,
      body: '$questName$dueText',
      priority: isUrgent ? NotificationPriority.high : NotificationPriority.medium,
      deepLink: 'choresapp://quest/$questId',
      data: {
        'questId': questId,
        'questName': questName,
        'isUrgent': isUrgent,
      },
    );
  }

  /// Create quest reminder notification (1 hour before deadline)
  static PushNotificationPayload questReminder({
    required String questId,
    required String questName,
  }) {
    return PushNotificationPayload(
      id: _generateId(PushNotificationType.questReminder, questId),
      type: PushNotificationType.questReminder,
      title: 'Quest due in 1 hour ⏱️',
      body: '$questName — don\'t forget!',
      priority: NotificationPriority.medium,
      deepLink: 'choresapp://quest/$questId',
      data: {
        'questId': questId,
        'questName': questName,
      },
    );
  }

  /// Create overdue quest alert
  static PushNotificationPayload questOverdue({
    required String questId,
    required String questName,
    DateTime? dueTime,
    bool isMultiple = false,
    int? count,
  }) {
    String title;
    String body;

    if (isMultiple && count != null) {
      title = '$count quests overdue ⏰';
      body = questName; // Should be comma-separated list
    } else {
      title = 'Quest overdue ⏰';
      body = dueTime != null
          ? '$questName was due at ${_formatTime(dueTime)}. Complete it soon!'
          : '$questName is waiting! Don\'t break your streak 🔥';
    }

    return PushNotificationPayload(
      id: _generateId(PushNotificationType.questOverdue, questId),
      type: PushNotificationType.questOverdue,
      title: title,
      body: body,
      priority: NotificationPriority.medium,
      deepLink: 'choresapp://quest/$questId',
      data: {
        'questId': questId,
        'questName': questName,
        'isMultiple': isMultiple,
        if (count != null) 'count': count,
      },
    );
  }

  /// Create approval request notification (to parent)
  static PushNotificationPayload approvalRequest({
    required String questId,
    required String questName,
    required String childName,
    bool hasPhoto = false,
    bool isMultiple = false,
    int? count,
    bool isHighValue = false,
    int? xpValue,
  }) {
    String title;
    String body;

    if (isMultiple && count != null) {
      title = '$childName completed $count quests! ✨';
      body = questName; // Should be comma-separated list
    } else if (isHighValue && xpValue != null) {
      title = 'High-value quest needs approval 🌟';
      body = '$childName completed $questName (+$xpValue XP)';
    } else {
      title = 'Approval needed from $childName ✋';
      body = hasPhoto
          ? '$questName is ready for review 📸'
          : '$questName is ready for review';
    }

    return PushNotificationPayload(
      id: _generateId(PushNotificationType.approvalRequest, questId),
      type: PushNotificationType.approvalRequest,
      title: title,
      body: body,
      priority: NotificationPriority.high,
      deepLink: isMultiple ? 'choresapp://approvals' : 'choresapp://quest/$questId',
      data: {
        'questId': questId,
        'questName': questName,
        'childName': childName,
        'hasPhoto': hasPhoto,
        'isMultiple': isMultiple,
        if (count != null) 'count': count,
      },
    );
  }

  /// Create approval result notification (to child)
  static PushNotificationPayload approvalResult({
    required String questId,
    required String questName,
    required bool approved,
    int? xpEarned,
    int? goldEarned,
    int? bonusXp,
    String? feedback,
  }) {
    String title;
    String body;

    if (approved) {
      if (bonusXp != null && bonusXp > 0) {
        title = 'Bonus earned! ⭐';
        body = '$questName approved with +$bonusXp bonus XP for quality!';
      } else if (xpEarned != null && goldEarned != null) {
        title = 'Quest approved! 🎉';
        body = '$questName earned you +$xpEarned XP and $goldEarned gold';
      } else {
        title = 'Quest approved! 🎉';
        body = questName;
      }
    } else {
      title = 'Quest needs rework 🔄';
      body = feedback != null ? '$questName — $feedback' : questName;
    }

    return PushNotificationPayload(
      id: _generateId(PushNotificationType.approvalResult, questId),
      type: PushNotificationType.approvalResult,
      title: title,
      body: body,
      priority: NotificationPriority.high,
      deepLink: 'choresapp://quest/$questId',
      data: {
        'questId': questId,
        'questName': questName,
        'approved': approved,
        if (xpEarned != null) 'xpEarned': xpEarned,
        if (goldEarned != null) 'goldEarned': goldEarned,
        if (bonusXp != null) 'bonusXp': bonusXp,
        if (feedback != null) 'feedback': feedback,
      },
    );
  }

  /// Create level up notification
  static PushNotificationPayload levelUp({
    required int level,
    String? unlockedReward,
  }) {
    final body = unlockedReward != null
        ? 'Unlocked: $unlockedReward. Keep up the great work!'
        : 'Keep up the great work!';

    return PushNotificationPayload(
      id: _generateId(PushNotificationType.levelUp),
      type: PushNotificationType.levelUp,
      title: 'Level Up! You\'re now Level $level! 🎊',
      body: body,
      priority: NotificationPriority.high,
      deepLink: 'choresapp://profile?celebrate=level_up',
      data: {
        'level': level,
        if (unlockedReward != null) 'unlockedReward': unlockedReward,
      },
    );
  }

  /// Create streak milestone notification
  static PushNotificationPayload streakMilestone({
    required int streakDays,
  }) {
    return PushNotificationPayload(
      id: _generateId(PushNotificationType.streakMilestone),
      type: PushNotificationType.streakMilestone,
      title: '$streakDays-day streak! 🔥',
      body: 'You\'ve completed quests $streakDays days in a row. Amazing!',
      priority: NotificationPriority.medium,
      deepLink: 'choresapp://profile?celebrate=streak',
      data: {
        'streakDays': streakDays,
      },
    );
  }

  /// Create family activity notification
  static PushNotificationPayload familyActivity({
    required String userId,
    required String userName,
    required int level,
  }) {
    return PushNotificationPayload(
      id: _generateId(PushNotificationType.familyActivity, userId),
      type: PushNotificationType.familyActivity,
      title: '$userName leveled up! 🎉',
      body: '$userName is now Level $level. Send them kudos!',
      priority: NotificationPriority.low,
      deepLink: 'choresapp://profile/$userId',
      data: {
        'userId': userId,
        'userName': userName,
        'level': level,
      },
    );
  }

  /// Create reward redemption request notification (to parent)
  static PushNotificationPayload rewardRedemption({
    required String rewardId,
    required String rewardName,
    required String childName,
    required int cost,
    required int currentBalance,
  }) {
    return PushNotificationPayload(
      id: _generateId(PushNotificationType.rewardRedemption, rewardId),
      type: PushNotificationType.rewardRedemption,
      title: 'Reward redemption request 🎁',
      body: '$childName wants to redeem $rewardName (costs $cost⭐) — approve?',
      priority: NotificationPriority.high,
      deepLink: 'choresapp://reward/$rewardId',
      data: {
        'rewardId': rewardId,
        'rewardName': rewardName,
        'childName': childName,
        'cost': cost,
        'currentBalance': currentBalance,
      },
    );
  }

  /// Generate deterministic notification ID
  static int _generateId(PushNotificationType type, [String? entityId]) {
    if (entityId != null) {
      return '$type-$entityId'.hashCode.abs();
    }
    return type.index + 1000;
  }

  /// Format due date
  static String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'today at ${_formatTime(date)}';
    } else if (targetDate == today.add(const Duration(days: 1))) {
      return 'tomorrow at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month} at ${_formatTime(date)}';
    }
  }

  /// Format time
  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
