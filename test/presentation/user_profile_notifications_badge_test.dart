import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/repositories/notification_repository.dart'
    as domain;
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/user_profile_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';

domain.Notification _notification(String id, {bool isRead = false}) =>
    domain.Notification(
      id: id,
      userId: _uid,
      title: 'Title $id',
      message: 'Message $id',
      isRead: isRead,
      createdAt: DateTime(2026, 9, 1),
    );

Future<void> _pumpProfile(
  WidgetTester tester, {
  required List<domain.Notification> seed,
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
      child: MaterialApp(theme: appLightTheme, home: UserProfileScreen()),
    ),
  );

  // The mocks delay with Future.delayed, which never fires in fake async.
  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(UserId(_uid));
    await users.updateUserProfile(profile!);
    for (final n in seed) {
      await notifications.createNotification(UserId(n.userId), n);
    }
  });
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

Finder _notificationsRowBadge() => find.descendant(
      of: find.widgetWithText(ListTile, 'Notifications'),
      matching: find.byType(Badge),
    );

void main() {
  testWidgets('Notifications row shows the unread count', (tester) async {
    await _pumpProfile(tester, seed: [
      _notification('n1'),
      _notification('n2'),
      _notification('n3', isRead: true),
    ]);

    expect(_notificationsRowBadge(), findsOneWidget);
    expect(
      find.descendant(of: _notificationsRowBadge(), matching: find.text('2')),
      findsOneWidget,
    );
  });

  testWidgets('Notifications row has no badge when all are read',
      (tester) async {
    await _pumpProfile(tester, seed: [_notification('n1', isRead: true)]);

    expect(find.widgetWithText(ListTile, 'Notifications'), findsOneWidget);
    expect(_notificationsRowBadge(), findsNothing);
  });
}
