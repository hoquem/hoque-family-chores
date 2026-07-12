import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/usecases/auth/delete_account_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

import '../../../mocks/mock_auth_repository.dart';
import '../../../mocks/mock_user_repository.dart';

User _makeUser() => User(
      id: UserId('uid_1'),
      name: 'Doomed User',
      email: Email('doomed@example.com'),
      familyId: FamilyId.empty,
      role: UserRole.parent,
      points: Points(0),
      joinedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  test('deletes the profile doc and then the auth user', () async {
    final users = MockUserRepository();
    final auth = MockAuthRepository();
    final user = _makeUser();
    await users.createUserProfile(user);

    final result = await DeleteAccountUseCase(users, auth).call(user: user);

    expect(result.isRight(), isTrue);
    expect(await users.getUserProfile(user.id), isNull,
        reason: 'profile doc must be gone');
    expect(auth.deleteUserCalled, isTrue);
  });

  test('requires-recent-login restores the profile doc and reports it',
      () async {
    final users = MockUserRepository();
    final auth = MockAuthRepository(
      deleteUserError: const AuthException(
        'needs recent login',
        code: 'REQUIRES_RECENT_LOGIN',
      ),
    );
    final user = _makeUser();
    await users.createUserProfile(user);

    final result = await DeleteAccountUseCase(users, auth).call(user: user);

    final failure = result.fold((f) => f, (_) => null);
    expect(failure, isA<AuthFailure>());
    expect(failure!.code, 'REQUIRES_RECENT_LOGIN');
    expect(await users.getUserProfile(user.id), isNotNull,
        reason: 'the profile doc must be restored: the auth user still '
            'exists, and an account without a profile doc is unusable');
  });

  test('a failed profile-doc delete leaves the auth user untouched', () async {
    final users = MockUserRepository(); // profile never created -> delete throws
    final auth = MockAuthRepository();
    final user = _makeUser();

    final result = await DeleteAccountUseCase(users, auth).call(user: user);

    expect(result.isLeft(), isTrue);
    expect(auth.deleteUserCalled, isFalse,
        reason: 'never delete the auth user if its data could not be removed');
  });
}
