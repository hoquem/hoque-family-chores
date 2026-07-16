import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/home_screen.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_user_repository.dart';

/// Pumps HomeScreen with a restored (keychain-persisted) Firebase session
/// whose profile stream has not delivered anything yet.
Future<(ProviderContainer, MockUserRepository)> _pumpRestoredSession(
  WidgetTester tester,
) async {
  final users = MockUserRepository();
  final auth = MockAuthRepository(
    currentUser: FakeFirebaseUser(uid: 'stale_uid', email: 'stale@example.com'),
  );
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
      child: MaterialApp(theme: appLightTheme, home: Scaffold(body: HomeScreen())),
    ),
  );
  return (container, users);
}

void main() {
  testWidgets('profile stream failure shows the error and a Sign Out button',
      (tester) async {
    final (container, users) = await _pumpRestoredSession(tester);

    // Still loading: spinner is correct here.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    users.emitProfileError(
      const ServerException(
        'User profile data is malformed for stale_uid',
        code: 'USER_DATA_MALFORMED',
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: 'an error state must not render as an endless spinner');
    expect(find.textContaining('malformed'), findsOneWidget,
        reason: 'the failure message must be visible to the user');
    expect(find.widgetWithText(ElevatedButton, 'Sign Out'), findsOneWidget,
        reason: 'the user needs an escape hatch back to the login screen');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Out'));
    await tester.pump();
    await tester.pump();

    expect(
      container.read(authNotifierProvider).status,
      AuthStatus.unauthenticated,
    );
  });

  testWidgets('spinner remains while profile is genuinely loading',
      (tester) async {
    final (container, _) = await _pumpRestoredSession(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign Out'), findsNothing);
    expect(container.read(authNotifierProvider).status,
        AuthStatus.authenticated);
  });
}
