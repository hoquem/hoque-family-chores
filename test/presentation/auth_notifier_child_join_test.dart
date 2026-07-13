import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';

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

(ProviderContainer, MockAuthRepository, MockFamilyRepository) _make() {
  final auth = MockAuthRepository();
  final users = MockUserRepository();
  final families = MockFamilyRepository();
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWith((_) => auth),
    userRepositoryProvider.overrideWith((_) => users),
    familyRepositoryProvider.overrideWith((_) => families),
  ]);
  addTearDown(container.dispose);
  return (container, auth, families);
}

void main() {
  test('joinFamilyAsChild signs the child in with a linked profile', () async {
    final (container, _, families) = _make();
    await families.createFamily(_family());
    final sub = container.listen(authNotifierProvider, (_, __) {});
    addTearDown(sub.close);

    await container
        .read(authNotifierProvider.notifier)
        .joinFamilyAsChild(name: 'Zayan', inviteCode: 'ABC234');
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final state = container.read(authNotifierProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.errorMessage, isNull);
    expect(state.user?.name, 'Zayan');
    expect(state.user?.role, UserRole.child);
    expect(state.user?.familyId.value, 'fam_1');
  });

  test('a bad code surfaces the error and stays signed out', () async {
    final (container, auth, families) = _make();
    await families.createFamily(_family());
    final sub = container.listen(authNotifierProvider, (_, __) {});
    addTearDown(sub.close);

    await container
        .read(authNotifierProvider.notifier)
        .joinFamilyAsChild(name: 'Zayan', inviteCode: 'WRONG1');

    final state = container.read(authNotifierProvider);
    expect(state.status, isNot(AuthStatus.authenticated));
    expect(state.errorMessage, contains('invite code'));
    expect(auth.currentUser, isNull);
  });
}
