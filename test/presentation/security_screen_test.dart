import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/presentation/screens/security_screen.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_user_repository.dart';

Future<MockAuthRepository> _pump(
  WidgetTester tester, {
  required List<String> providerIds,
}) async {
  final auth = MockAuthRepository(
    currentUser: FakeFirebaseUser(uid: 'u1', email: 'a@b.com'),
    providerIds: providerIds,
  );
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => auth),
      userRepositoryProvider.overrideWith((_) => MockUserRepository()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: appLightTheme, home: SecurityScreen()),
    ),
  );
  await tester.pump();
  return auth;
}

void main() {
  testWidgets('OAuth accounts see their provider, not a password form',
      (tester) async {
    await _pump(tester, providerIds: ['google.com']);

    expect(find.textContaining('Google'), findsOneWidget);
    expect(find.text('Change Password'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('password accounts can change their password', (tester) async {
    final auth = await _pump(tester, providerIds: ['password']);

    expect(find.text('Change Password'), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('current_password')), 'old-secret');
    await tester.enterText(
        find.byKey(const Key('new_password')), 'new-secret');
    await tester.tap(find.text('Change Password'));
    await tester.pump();
    await tester.pump();

    expect(auth.lastUpdatedPassword, 'new-secret');
    expect(find.text('Password changed'), findsOneWidget);
  });

  testWidgets('a failed change shows the error', (tester) async {
    final auth = await _pump(tester, providerIds: ['password']);
    auth.reauthenticateError = const AuthException(
      'Failed to reauthenticate: wrong password',
      code: 'REAUTHENTICATE_ERROR',
    );

    await tester.enterText(
        find.byKey(const Key('current_password')), 'wrong');
    await tester.enterText(
        find.byKey(const Key('new_password')), 'new-secret');
    await tester.tap(find.text('Change Password'));
    await tester.pump();
    await tester.pump();

    expect(auth.lastUpdatedPassword, isNull);
    expect(find.textContaining('is incorrect'), findsOneWidget);
  });
}
