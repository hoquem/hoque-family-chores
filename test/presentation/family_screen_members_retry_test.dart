import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/family_screen.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';
final _familyId = FamilyId('fam_1');

/// Members fail with a non-transient error until [failMembers] is cleared.
class _FailingMembersRepository extends MockFamilyRepository {
  bool failMembers = true;

  @override
  Future<FamilyEntity?> getFamily(FamilyId familyId) async => FamilyEntity(
        id: _familyId,
        name: 'Test Family',
        description: '',
        creatorId: UserId(_uid),
        memberIds: [UserId(_uid)],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        inviteCode: 'ABC234',
      );

  @override
  Future<List<User>> getFamilyMembers(FamilyId familyId) async {
    if (failMembers) {
      throw const ServerException('network unreachable', code: 'X');
    }
    final me = await MockUserRepository().getUserProfile(UserId('user_1'));
    return [me!];
  }
}

void main() {
  testWidgets('members error shows a Retry button that reloads the list',
      (tester) async {
    final users = MockUserRepository();
    final auth = MockAuthRepository();
    final family = _FailingMembersRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWith((_) => auth),
        userRepositoryProvider.overrideWith((_) => users),
        familyRepositoryProvider.overrideWith((_) => family),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FamilyScreen()),
      ),
    );

    // Sign in and deliver a profile that belongs to fam_1.
    await tester.runAsync(() async {
      await container.read(authNotifierProvider.notifier).signInWithGoogle();
      final profile = await users.getUserProfile(UserId(_uid));
      await users
          .updateUserProfile(profile!.copyWith(familyId: _familyId));
    });
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Could not load members'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget,
        reason: 'a failed members load needs an explicit way to retry');

    family.failMembers = false;
    await tester.tap(find.text('Retry'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Could not load members'), findsNothing);
    expect(find.text('John Doe'), findsOneWidget,
        reason: 'the member list must load after a successful retry');
  });
}
