import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/repositories/notification_repository.dart' as domain;
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/notifications_screen.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';

domain.Notification _notification(String id, String title,
        {bool isRead = false}) =>
    domain.Notification(
      id: id,
      userId: _uid,
      title: title,
      message: 'message for $title',
      isRead: isRead,
      createdAt: DateTime(2026, 7, 1),
    );

Future<(ProviderContainer, MockNotificationRepository)> _pumpScreen(
  WidgetTester tester, {
  List<domain.Notification> seed = const [],
}) async {
  final users = MockUserRepository();
  final auth = MockAuthRepository();
  final notifications = MockNotificationRepository();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => auth),
      userRepositoryProvider.overrideWith((_) => users),
      notificationRepositoryProvider.overrideWith((_) => notifications),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: appLightTheme, home: NotificationsScreen()),
    ),
  );

  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    // Push the profile through the (broadcast) stream so auth state sees it.
    final profile = await users.getUserProfile(UserId(_uid));
    await users.updateUserProfile(profile!);
    for (final n in seed) {
      await notifications.createNotification(UserId(n.userId), n);
    }
  });
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
  return (container, notifications);
}

void main() {
  testWidgets('shows the signed-in user\'s notifications', (tester) async {
    await _pumpScreen(tester, seed: [
      _notification('n1', 'Task approved'),
      _notification('n2', 'Badge earned', isRead: true),
    ]);

    expect(find.text('Task approved'), findsOneWidget);
    expect(find.text('Badge earned'), findsOneWidget);
  });

  testWidgets('tapping an unread notification marks it read', (tester) async {
    final (_, repo) = await _pumpScreen(tester, seed: [
      _notification('n1', 'Task approved'),
    ]);

    await tester.tap(find.text('Task approved'));
    await tester.pump(const Duration(milliseconds: 300));

    final list = await tester.runAsync(
        () => repo.getNotifications(UserId(_uid)));
    expect(list!.single.isRead, isTrue);
  });

  testWidgets('empty state when there are no notifications', (tester) async {
    await _pumpScreen(tester);

    expect(find.textContaining('No notifications'), findsOneWidget);
  });
}
