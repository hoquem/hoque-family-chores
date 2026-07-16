import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/child_join_screen.dart';
import 'package:hoque_family_chores/presentation/screens/login_screen.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_user_repository.dart';

FamilyEntity _family() => FamilyEntity(
      id: FamilyId('fam_1'),
      name: 'Hoque Family',
      description: '',
      creatorId: UserId('parent_uid'),
      memberIds: [UserId('parent_uid')],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      inviteCode: 'ABC234',
    );

Future<(ProviderContainer, MockFamilyRepository)> _pump(
  WidgetTester tester, {
  Widget home = const ChildJoinScreen(),
}) async {
  final families = MockFamilyRepository();
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
    userRepositoryProvider.overrideWith((_) => MockUserRepository()),
    familyRepositoryProvider.overrideWith((_) => families),
  ]);
  addTearDown(container.dispose);
  await tester.runAsync(() => families.createFamily(_family()));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: appLightTheme, home: home),
    ),
  );
  return (container, families);
}

void main() {
  testWidgets('a child joins with name and family code', (tester) async {
    final (container, _) = await _pump(tester);

    await tester.enterText(find.byKey(const Key('child_name_field')), 'Zayan');
    await tester.enterText(
        find.byKey(const Key('child_code_field')), 'abc234');
    await tester.tap(find.text('Join'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    final state = container.read(authNotifierProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.name, 'Zayan');
  });

  testWidgets('a wrong code shows a friendly error and stays put',
      (tester) async {
    final (container, _) = await _pump(tester);

    await tester.enterText(find.byKey(const Key('child_name_field')), 'Zayan');
    await tester.enterText(
        find.byKey(const Key('child_code_field')), 'WRONG1');
    await tester.tap(find.text('Join'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(container.read(authNotifierProvider).status,
        isNot(AuthStatus.authenticated));
    expect(find.textContaining('invite code'), findsOneWidget);
  });

  testWidgets('the login screen links kids to the join screen',
      (tester) async {
    await _pump(tester, home: const LoginScreen());

    await tester.tap(find.textContaining("kid"));
    await tester.pumpAndSettle();

    expect(find.byType(ChildJoinScreen), findsOneWidget);
  });
}
