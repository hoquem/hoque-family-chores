import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/presentation/screens/login_screen.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_user_repository.dart';

Future<MockAuthRepository> _pumpLoginScreen(WidgetTester tester) async {
  final auth = MockAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWith((_) => auth),
        userRepositoryProvider.overrideWith((_) => MockUserRepository()),
      ],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
  return auth;
}

void main() {
  testWidgets('shows the Apple and Google buttons', (tester) async {
    await _pumpLoginScreen(tester);

    expect(find.byType(SignInWithAppleButton), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    // Email/password is hidden by default (App Store review only) —
    // covered in login_screen_email_hidden_test.dart.
  });

  testWidgets('tapping Continue with Google signs in through the repository',
      (tester) async {
    final auth = await _pumpLoginScreen(tester);
    expect(auth.currentUser, isNull);

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(auth.currentUser, isNotNull);
    expect(auth.currentUser.uid, 'mock_google_uid');
  });

  testWidgets('tapping the Apple button signs in through the repository',
      (tester) async {
    final auth = await _pumpLoginScreen(tester);

    await tester.tap(find.byType(SignInWithAppleButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(auth.currentUser, isNotNull);
    expect(auth.currentUser.uid, 'mock_apple_uid');
  });
}
