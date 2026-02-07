import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/notification.dart';

Notification _makeNotification({bool isRead = false}) {
  return Notification(
    id: 'n1',
    userId: 'u1',
    title: 'Task Completed',
    message: 'Someone finished a task',
    isRead: isRead,
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('Notification', () {
    test('markAsRead', () {
      final n = _makeNotification(isRead: false);
      expect(n.markAsRead().isRead, true);
    });

    test('markAsUnread', () {
      final n = _makeNotification(isRead: true);
      expect(n.markAsUnread().isRead, false);
    });

    test('copyWith', () {
      final n = _makeNotification();
      final copy = n.copyWith(title: 'New');
      expect(copy.title, 'New');
      expect(copy.id, n.id);
    });

    test('equality', () {
      expect(_makeNotification(), equals(_makeNotification()));
    });
  });
}
