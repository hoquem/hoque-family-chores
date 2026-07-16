import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/usecases/family/join_family_as_child_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/family/join_family_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/user/initialize_user_data_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

import '../../../mocks/mock_auth_repository.dart';
import '../../../mocks/mock_family_repository.dart';
import '../../../mocks/mock_user_repository.dart';

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

(JoinFamilyAsChildUseCase, MockAuthRepository, MockUserRepository,
    MockFamilyRepository) _make() {
  final auth = MockAuthRepository();
  final users = MockUserRepository();
  final families = MockFamilyRepository();
  final useCase = JoinFamilyAsChildUseCase(
    auth,
    InitializeUserDataUseCase(users),
    JoinFamilyUseCase(families, users),
  );
  return (useCase, auth, users, families);
}

void main() {
  test('a child joins with just a name and a valid code', () async {
    final (useCase, auth, users, families) = _make();
    await families.createFamily(_family());

    final result = await useCase.call(name: 'Zayan', inviteCode: 'abc234');

    expect(result.isRight(), isTrue);
    final uid = (auth.currentUser as FakeFirebaseUser).uid;
    final profile = await users.getUserProfile(UserId(uid));
    expect(profile!.name, 'Zayan');
    expect(profile.role, UserRole.child);
    expect(profile.email, isNull,
        reason: 'children have no email — the profile must not fake one');
    expect(profile.familyId.value, 'fam_1');
    final family = await families.getFamily(FamilyId('fam_1'));
    expect(family!.memberIds.map((id) => id.value), contains(uid));
  });

  test('a bad code cleans up the anonymous account', () async {
    final (useCase, auth, _, families) = _make();
    await families.createFamily(_family());

    final result = await useCase.call(name: 'Zayan', inviteCode: 'WRONG1');

    final failure = result.fold((f) => f, (_) => null);
    expect(failure, isA<NotFoundFailure>());
    expect(auth.deleteUserCalled, isTrue,
        reason: 'a failed join must not strand a signed-in anonymous user '
            'with no profile');
    expect(auth.currentUser, isNull);
  });

  test('an empty name fails before any account is created', () async {
    final (useCase, auth, _, _) = _make();

    final result = await useCase.call(name: '   ', inviteCode: 'ABC234');

    expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    expect(auth.currentUser, isNull);
    expect(auth.deleteUserCalled, isFalse);
  });
}
