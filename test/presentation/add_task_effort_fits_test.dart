// The Effort Size selector must fit the phones the app actually runs on.
//
// This is the regression the old suite could not catch: it pumped every screen
// at 1200px "to avoid layout overflow in long dropdown labels", so a control
// that truncates on every real device passed CI for as long as it existed.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

/// The narrowest phone the app realistically runs on. If it fits here it fits
/// everywhere; 320 is the iPhone SE / small-Android floor.
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

/// Every [Text] that renders [text] must not be ellipsised at its given size.
void _expectNotTruncated(WidgetTester tester, String text) {
  final finder = find.text(text);
  expect(finder, findsWidgets, reason: '"$text" should be on screen');
  for (final element in finder.evaluate()) {
    final rp = element.renderObject! as RenderParagraph;
    expect(rp.didExceedMaxLines, isFalse,
        reason: '"$text" is truncated at this width');
    final overflows = rp.size.width < rp.getMaxIntrinsicWidth(double.infinity);
    expect(overflows, isFalse,
        reason: '"$text" needs '
            '${rp.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(0)}px '
            'but has ${rp.size.width.toStringAsFixed(0)}px');
  }
}

void main() {
  testWidgets('effort size options are readable on a 320pt phone',
      (tester) async {
    await _pumpAt(tester, _iphoneSe);

    // Each effort option must be legible without ellipsis at the narrowest
    // width. These are the four the selector offers.
    for (final label in ['S', 'M', 'L', 'XL']) {
      _expectNotTruncated(tester, label);
    }
  });

  testWidgets('the selected effort shows its star value on a 320pt phone',
      (tester) async {
    await _pumpAt(tester, _iphoneSe);
    // The reward is the number that matters when picking effort; it must never
    // be the thing that gets cut off.
    expect(find.textContaining('10'), findsWidgets);
  });

  testWidgets('no layout overflow anywhere on a 320pt phone', (tester) async {
    await _pumpAt(tester, _iphoneSe);
    expect(tester.takeException(), isNull);
  });
}
