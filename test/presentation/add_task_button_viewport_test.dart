// The Create Chore button must stay fully inside the *visible* screen: not
// under the iOS home indicator, not clipped at narrow widths, and reachable
// (not permanently hidden) once the keyboard is up.
//
// Bug report (iPhone 17 Pro, iOS 26.2, on the create-chore screen): "the
// create chore tap button is half off screen". The screen's ListView has a
// flat `padding: EdgeInsets.all(16.0)` with no SafeArea and no reference to
// MediaQuery.viewPadding, so nothing stops the last item -- the Create Chore
// button -- from being laid out underneath the home-indicator safe area.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/add_task_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';

/// [logicalSize]/[viewPadding]/[viewInsets] are all in logical pixels, like
/// the numbers in a bug report or a device spec sheet; this helper converts
/// to the physical pixels the test view API expects.
Future<void> _pumpAt(
  WidgetTester tester, {
  required Size logicalSize,
  double devicePixelRatio = 3.0,
  EdgeInsets viewPadding = EdgeInsets.zero,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = logicalSize * devicePixelRatio;
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.padding = FakeViewPadding(
    left: viewPadding.left * devicePixelRatio,
    top: viewPadding.top * devicePixelRatio,
    right: viewPadding.right * devicePixelRatio,
    bottom: viewPadding.bottom * devicePixelRatio,
  );
  tester.view.viewInsets = FakeViewPadding(
    bottom: viewInsets.bottom * devicePixelRatio,
  );
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetPadding();
    tester.view.resetViewInsets();
  });

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
      child: MaterialApp(theme: appLightTheme, home: const AddTaskScreen()),
    ),
  );

  // Sign in as a parent -- the role that renders the fullest version of this
  // form (Assign To dropdown, Repeat selector) and therefore the one most
  // likely to need scrolling on a real phone.
  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(UserId(_uid));
    await users
        .updateUserProfile(profile!.copyWith(familyId: FamilyId('family_1')));
  });
  await tester.pumpAndSettle();
}

/// Scrolls the Create Chore button into the built widget tree and into view.
///
/// The page's own [ListView] is the first [Scrollable] in a pre-order walk
/// of the tree; the multiline [TextFormField]s below it each wrap an
/// internal [Scrollable] of their own, which is why `scrollUntilVisible`'s
/// default `find.byType(Scrollable)` (which requires exactly one match) is
/// ambiguous here.
Future<void> _scrollToCreateButton(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.widgetWithText(ElevatedButton, 'Create Chore'),
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// The bottom-right corner of the Create Chore button, in the same global
/// (logical) coordinate space that [tester.view] describes the screen in.
Offset _createButtonBottomRight(WidgetTester tester) {
  final box = tester.renderObject<RenderBox>(
    find.widgetWithText(ElevatedButton, 'Create Chore'),
  );
  return box.localToGlobal(box.size.bottomRight(Offset.zero));
}

double _logicalHeight(WidgetTester tester) =>
    tester.view.physicalSize.height / tester.view.devicePixelRatio;

double _logicalWidth(WidgetTester tester) =>
    tester.view.physicalSize.width / tester.view.devicePixelRatio;

void main() {
  testWidgets(
      'Create Chore button stays above the home indicator on an iPhone 17 Pro',
      (tester) async {
    // iPhone 17 Pro logical size, 3x, with the home-indicator safe area the
    // bug report was filed against.
    await _pumpAt(
      tester,
      logicalSize: const Size(402, 874),
      devicePixelRatio: 3.0,
      viewPadding: const EdgeInsets.only(top: 62, bottom: 34),
    );

    await _scrollToCreateButton(tester);

    expect(tester.takeException(), isNull);

    final bottomRight = _createButtonBottomRight(tester);
    final safeBottom =
        _logicalHeight(tester) - (const EdgeInsets.only(bottom: 34).bottom);

    expect(
      bottomRight.dy,
      lessThanOrEqualTo(safeBottom),
      reason: 'Create Chore button sits under the home-indicator safe area',
    );
  });

  testWidgets('no layout overflow for the create-chore form on a small phone',
      (tester) async {
    await _pumpAt(
      tester,
      logicalSize: const Size(375, 667),
      devicePixelRatio: 2.0,
      viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
    );

    await _scrollToCreateButton(tester);

    expect(tester.takeException(), isNull);

    final bottomRight = _createButtonBottomRight(tester);
    expect(bottomRight.dx, lessThanOrEqualTo(_logicalWidth(tester)));
  });

  testWidgets('Create Chore button is reachable above the keyboard',
      (tester) async {
    await _pumpAt(
      tester,
      logicalSize: const Size(402, 874),
      devicePixelRatio: 3.0,
      viewPadding: const EdgeInsets.only(top: 62, bottom: 34),
      viewInsets: const EdgeInsets.only(bottom: 336),
    );

    await _scrollToCreateButton(tester);

    expect(tester.takeException(), isNull);

    final bottomRight = _createButtonBottomRight(tester);
    final visibleBottom = _logicalHeight(tester) - 336;

    expect(
      bottomRight.dy,
      lessThanOrEqualTo(visibleBottom),
      reason: 'Create Chore button sits under the on-screen keyboard',
    );
  });
}
