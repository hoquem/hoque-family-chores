import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/services/notification_templates.dart';

/// The app's user-facing vocabulary is "chore" (see the Chores tab, and the
/// Chore/Task glossary entry in ENGINEERING.md); these
/// templates are push-notification copy, so they must match. Identifiers
/// (questId, deep links, data keys) are payload contracts and stay as-is.
void main() {
  group('NotificationTemplates say "chore", not "quest" or "task"', () {
    test('morning reminder bodies', () {
      expect(NotificationTemplates.morningReminder(questCount: 1).body,
          'You have 1 chore waiting');
      expect(NotificationTemplates.morningReminder(questCount: 3).body,
          'You have 3 chores to complete today');
      expect(
        NotificationTemplates.morningReminder(questCount: 2, streakDays: 5)
            .body,
        "Complete today's chores to keep your 5-day streak alive",
      );
    });

    test('assignment titles', () {
      expect(
        NotificationTemplates.questAssignment(
                questId: 'q1', questName: 'Dishes')
            .title,
        'New chore assigned 📋',
      );
      expect(
        NotificationTemplates.questAssignment(
                questId: 'q1', questName: 'Dishes', isUrgent: true)
            .title,
        'Urgent chore! 🚨',
      );
    });

    test('reminder and overdue titles', () {
      expect(
        NotificationTemplates.questReminder(questId: 'q1', questName: 'Dishes')
            .title,
        'Chore due in 1 hour ⏱️',
      );
      expect(
        NotificationTemplates.questOverdue(questId: 'q1', questName: 'Dishes')
            .title,
        'Chore overdue ⏰',
      );
      expect(
        NotificationTemplates.questOverdue(
                questId: 'q1',
                questName: 'Dishes, Trash',
                isMultiple: true,
                count: 2)
            .title,
        '2 chores overdue ⏰',
      );
    });

    test('approval flow titles', () {
      expect(
        NotificationTemplates.approvalRequest(
                questId: 'q1',
                questName: 'Dishes, Trash',
                childName: 'Jane',
                isMultiple: true,
                count: 2)
            .title,
        'Jane completed 2 chores! ✨',
      );
      expect(
        NotificationTemplates.approvalRequest(
                questId: 'q1',
                questName: 'Dishes',
                childName: 'Jane',
                isHighValue: true,
                xpValue: 50)
            .title,
        'High-value chore needs approval 🌟',
      );
      expect(
        NotificationTemplates.approvalResult(
                questId: 'q1', questName: 'Dishes', approved: true)
            .title,
        'Chore approved! 🎉',
      );
      expect(
        NotificationTemplates.approvalResult(
                questId: 'q1', questName: 'Dishes', approved: false)
            .title,
        'Chore needs rework 🔄',
      );
    });

    test('streak milestone body', () {
      expect(
        NotificationTemplates.streakMilestone(streakDays: 7).body,
        "You've completed chores 7 days in a row. Amazing!",
      );
    });
  });
}
