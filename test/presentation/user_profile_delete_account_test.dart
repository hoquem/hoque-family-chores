import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/user_profile_screen.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';

/// Builds the profile screen with a signed-in user whose profile has been
/// delivered through the user stream.
Future<ProviderContainer> _pumpSignedInProfile(
  WidgetTester tester, {
  required MockAuthRepository auth,
  required MockUserRepository users,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => auth),
      userRepositoryProvider.overrideWith((_) => users),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: UserProfileScreen()),
    ),
  );

  // The mocks simulate latency with Future.delayed, whose timers never fire
  // inside the widget test's fake-async zone — run the setup in real async.
  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(UserId(_uid));
    await users.updateUserProfile(profile!);
  });
  await tester.pump(const Duration(milliseconds: 200));
  expect(container.read(authNotifierProvider).user, isNotNull,
      reason: 'test setup: profile stream must have delivered the user');
  await tester.pump();

  return container;
}

void main() {
  testWidgets('delete flow: confirm dialog -> account deleted',
      (tester) async {
    final users = MockUserRepository();
    final auth = MockAuthRepository();
    final container =
        await _pumpSignedInProfile(tester, auth: auth, users: users);

    await tester.dragUntilVisible(
      find.text('Delete Account'),
      find.byType(ListView),
      const Offset(0, -100),
    );
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    // Confirmation dialog with destructive wording.
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('cannot be undone'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(auth.deleteUserCalled, isTrue);
    expect(container.read(authNotifierProvider).status,
        AuthStatus.unauthenticated);
  });

  testWidgets('delete flow: cancel does nothing', (tester) async {
    final users = MockUserRepository();
    final auth = MockAuthRepository();
    final container =
        await _pumpSignedInProfile(tester, auth: auth, users: users);

    await tester.dragUntilVisible(
      find.text('Delete Account'),
      find.byType(ListView),
      const Offset(0, -100),
    );
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(auth.deleteUserCalled, isFalse);
    expect(container.read(authNotifierProvider).status,
        AuthStatus.authenticated);
  });

  testWidgets('delete flow: failure shows the error in a SnackBar',
      (tester) async {
    final users = MockUserRepository();
    final auth = MockAuthRepository(
      deleteUserError: const AuthException(
        'needs recent login',
        code: 'REQUIRES_RECENT_LOGIN',
      ),
    );
    final container =
        await _pumpSignedInProfile(tester, auth: auth, users: users);

    await tester.dragUntilVisible(
      find.text('Delete Account'),
      find.byType(ListView),
      const Offset(0, -100),
    );
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(container.read(authNotifierProvider).status,
        AuthStatus.authenticated,
        reason: 'the session must survive a failed deletion');
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('recent sign-in'), findsOneWidget);
  });
}
