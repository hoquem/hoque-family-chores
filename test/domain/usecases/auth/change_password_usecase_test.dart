import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/usecases/auth/change_password_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';

import '../../../mocks/mock_auth_repository.dart';

void main() {
  test('changes the password after reauthenticating', () async {
    final auth = MockAuthRepository(
      currentUser: FakeFirebaseUser(uid: 'u1', email: 'a@b.com'),
    );
    final useCase = ChangePasswordUseCase(auth);

    final result = await useCase.call(
      email: Email('a@b.com'),
      currentPassword: 'old-secret',
      newPassword: 'new-secret',
    );

    expect(result.isRight(), isTrue);
    expect(auth.reauthenticatedWithPassword, 'old-secret');
    expect(auth.lastUpdatedPassword, 'new-secret');
  });

  test('a wrong current password fails with a friendly message', () async {
    final auth = MockAuthRepository(
      currentUser: FakeFirebaseUser(uid: 'u1', email: 'a@b.com'),
      reauthenticateError: const AuthException(
        'Failed to reauthenticate: wrong password',
        code: 'REAUTHENTICATE_ERROR',
      ),
    );
    final useCase = ChangePasswordUseCase(auth);

    final result = await useCase.call(
      email: Email('a@b.com'),
      currentPassword: 'wrong',
      newPassword: 'new-secret',
    );

    final failure = result.fold((f) => f, (_) => null);
    expect(failure, isA<AuthFailure>());
    expect(failure!.message, contains('Current password'));
    expect(auth.lastUpdatedPassword, isNull,
        reason: 'the password must not change when reauthentication fails');
  });

  test('a too-short new password is rejected without touching the account',
      () async {
    final auth = MockAuthRepository(
      currentUser: FakeFirebaseUser(uid: 'u1', email: 'a@b.com'),
    );
    final useCase = ChangePasswordUseCase(auth);

    final result = await useCase.call(
      email: Email('a@b.com'),
      currentPassword: 'old-secret',
      newPassword: '123',
    );

    final failure = result.fold((f) => f, (_) => null);
    expect(failure, isA<ValidationFailure>());
    expect(auth.reauthenticatedWithPassword, isNull);
    expect(auth.lastUpdatedPassword, isNull);
  });
}
