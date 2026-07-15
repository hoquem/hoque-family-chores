import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/main_screen.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';

Future<void> _pumpMainScreenSignedIn(WidgetTester tester) async {
  final users = MockUserRepository();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => users),
      familyRepositoryProvider.overrideWith((_) => MockFamilyRepository()),
      taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
      notificationRepositoryProvider
          .overrideWith((_) => MockNotificationRepository()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: MainScreen()),
    ),
  );

  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(UserId(_uid));
    await users
        .updateUserProfile(profile!.copyWith(familyId: FamilyId('family_1')));
  });
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Finds the AppBar title text on the currently visible tab.
Finder _appBarTitle(String title) => find.descendant(
      of: find.byType(AppBar),
      matching: find.text(title),
    );

void main() {
  testWidgets(
      'every tab shows an AppBar whose title matches its nav label, '
      'so no screen content sits under the status bar/notch', (tester) async {
    await _pumpMainScreenSignedIn(tester);

    // Home is the initial tab. Its content must live below an AppBar —
    // an AppBar is what keeps the title out of the notch.
    expect(_appBarTitle('Home'), findsOneWidget,
        reason: 'the Home tab needs an AppBar so its title clears the notch');

    for (final tab in ['Tasks', 'Family', 'Profile']) {
      await tester.tap(find.text(tab).last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_appBarTitle(tab), findsOneWidget,
          reason: 'the $tab tab title must match its nav label');
    }
  });
}
