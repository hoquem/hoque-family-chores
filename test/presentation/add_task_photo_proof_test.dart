// The "Requires photo proof" switch is the whole photo-proof feature's
// on/off toggle. It must default off (today's behaviour is unchanged unless a
// parent opts in) and must be tappable.
//
// Pumped at 320pt (iPhone SE) per this suite's convention — see
// add_task_effort_fits_test.dart for why a wide viewport is not trustworthy
// here.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/presentation/screens/add_task_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';

const Size _iphoneSe = Size(320, 568);

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => MockUserRepository()),
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
      child: MaterialApp(theme: appLightTheme, home: const AddTaskScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('photo proof switch exists and is off by default',
      (tester) async {
    await _pumpAt(tester, _iphoneSe);

    final finder = find.byKey(const Key('photo_proof_switch'));
    expect(finder, findsOneWidget);

    final tile = tester.widget<SwitchListTile>(finder);
    expect(tile.value, isFalse);
  });

  testWidgets('tapping the photo proof switch turns it on', (tester) async {
    await _pumpAt(tester, _iphoneSe);

    final finder = find.byKey(const Key('photo_proof_switch'));
    await tester.tap(finder);
    await tester.pumpAndSettle();

    final tile = tester.widget<SwitchListTile>(finder);
    expect(tile.value, isTrue);
  });
}
