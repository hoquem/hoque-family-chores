import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/edit_profile_screen.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';

Future<(ProviderContainer, MockUserRepository)> _pumpSignedIn(
  WidgetTester tester,
) async {
  final users = MockUserRepository();
  final auth = MockAuthRepository();
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
      child: const MaterialApp(home: EditProfileScreen()),
    ),
  );

  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(UserId(_uid));
    await users.updateUserProfile(profile!.copyWith(name: 'Original Name'));
  });
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump();
  return (container, users);
}

void main() {
  testWidgets('shows the current name pre-filled', (tester) async {
    await _pumpSignedIn(tester);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'Original Name');
  });

  testWidgets('saving a new name updates the profile', (tester) async {
    final (container, users) = await _pumpSignedIn(tester);

    await tester.enterText(find.byType(TextField), 'New Name');
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    final saved = await tester.runAsync(
        () => users.getUserProfile(UserId(_uid)));
    expect(saved!.name, 'New Name');
    expect(container.read(authNotifierProvider).user?.name, 'New Name',
        reason: 'the profile stream must deliver the update to auth state');
  });

  testWidgets('an empty name is rejected and never saved', (tester) async {
    final (_, users) = await _pumpSignedIn(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Name cannot be empty'), findsOneWidget);
    final saved = await tester.runAsync(
        () => users.getUserProfile(UserId(_uid)));
    expect(saved!.name, 'Original Name');
  });
}
