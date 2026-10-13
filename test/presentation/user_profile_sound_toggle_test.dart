// The per-device "Sound effects" switch: on by default, and turning it off
// reaches soundEnabledProvider (which SoundService reads before playing).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/user_profile_screen.dart';
import 'package:hoque_family_chores/presentation/sound/sound_service.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';

Future<ProviderContainer> _pumpProfile(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final users = MockUserRepository();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => users),
      notificationRepositoryProvider
          .overrideWith((_) => MockNotificationRepository()),
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
  });
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
  return container;
}

void main() {
  testWidgets('Sound effects switch is on by default and turns sound off',
      (tester) async {
    final container = await _pumpProfile(tester);
    final tile = find.widgetWithText(SwitchListTile, 'Sound effects');
    await tester.scrollUntilVisible(tile, 100);
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);

    await tester.tap(tile);
    await tester.pump();
    expect(container.read(soundEnabledProvider), isFalse);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
  });
}
