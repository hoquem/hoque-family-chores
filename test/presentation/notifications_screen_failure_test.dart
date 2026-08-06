// A notification that fails to mark read must say so.
//
// It used to fail in total silence: the tap called the use case without
// awaiting it and discarded the returned Either, so a PERMISSION_DENIED from
// Firestore reached nobody. The dot stayed amber, the badge stayed at 1, and
// the only trace was a line in the device log. That is the failure mode
// ENGINEERING.md's "fail loudly" rule exists to prevent.
// Flutter's own Notification (the widget-tree kind) collides with the domain
// entity; the screen under test disambiguates the same way.
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/repositories/notification_repository.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/notifications_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';

/// Holds one unread notification for the signed-in user, and marks it read
/// normally. The success half of the pair below.
class _SeededNotificationRepository extends MockNotificationRepository {
  _SeededNotificationRepository() {
    createNotification(
      UserId(_uid),
      Notification(
        id: 'n1',
        userId: _uid,
        title: 'Mum is on it!',
        message: "Mum claimed 'Clean the middle bathroom'",
        isRead: false,
        createdAt: DateTime(2026, 8, 2),
      ),
    );
  }
}

/// Same, but refuses to mark it read — standing in for the Firestore
/// permission error that caused this bug.
class _RefusingNotificationRepository extends MockNotificationRepository {
  _RefusingNotificationRepository() {
    createNotification(
      UserId(_uid),
      Notification(
        id: 'n1',
        userId: _uid,
        title: 'Mum is on it!',
        message: "Mum claimed 'Clean the middle bathroom'",
        isRead: false,
        createdAt: DateTime(2026, 8, 2),
      ),
    );
  }

  @override
  Future<void> markNotificationAsRead(UserId userId, String notificationId) {
    throw PermissionException('Missing or insufficient permissions',
        code: 'PERMISSION_DENIED');
  }
}

Future<void> _pumpNotifications(
  WidgetTester tester, {
  required NotificationRepository repository,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final users = MockUserRepository();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => users),
      familyRepositoryProvider.overrideWith((_) => MockFamilyRepository()),
      taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
      notificationRepositoryProvider
          .overrideWith((_) => repository),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: appLightTheme,
        home: const NotificationsScreen(),
      ),
    ),
  );

  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(UserId(_uid));
    await users.updateUserProfile(profile!.copyWith(familyId: FamilyId('family_1')));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('a notification that cannot be marked read says so',
      (tester) async {
    await _pumpNotifications(tester,
        repository: _RefusingNotificationRepository());
    expect(find.text('Mum is on it!'), findsOneWidget,
        reason: 'the unread notification should be on screen to tap');

    await tester.tap(find.text('Mum is on it!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining("Couldn't mark that as read"), findsOneWidget,
        reason: 'a silent failure leaves the user tapping a dot that never '
            'clears, with no idea why');
  });

  // The other half: without this, "always show an error" would pass the test
  // above and be just as wrong.
  testWidgets('a notification that marks read cleanly says nothing',
      (tester) async {
    await _pumpNotifications(tester,
        repository: _SeededNotificationRepository());

    await tester.tap(find.text('Mum is on it!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining("Couldn't"), findsNothing);
  });
}
