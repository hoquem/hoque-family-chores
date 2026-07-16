import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/presentation/screens/login_screen.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_user_repository.dart';

Future<void> _pumpLogin(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => MockUserRepository()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: appLightTheme, home: LoginScreen()),
    ),
  );
}

void main() {
  testWidgets('email/password auth is hidden by default', (tester) async {
    await _pumpLogin(tester);

    // OAuth stays front and centre.
    expect(find.text('Continue with Google'), findsOneWidget);

    // Email/password is for App Store review only — not visible.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Sign In'), findsNothing);
    expect(find.textContaining('Sign Up'), findsNothing);
    expect(find.text('Forgot Password?'), findsNothing);
  });

  testWidgets('long-pressing the Login title reveals email/password auth',
      (tester) async {
    await _pumpLogin(tester);

    await tester.longPress(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.textContaining('Sign Up'), findsOneWidget);
  });
}
