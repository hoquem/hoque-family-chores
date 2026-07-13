import 'package:dartz/dartz.dart' hide Task;

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../repositories/auth_repository.dart';
import '../../value_objects/email.dart';

/// Changes the signed-in user's password.
///
/// Firebase requires a recent sign-in for password changes, so the user is
/// reauthenticated with the current password first — which also proves they
/// know it.
class ChangePasswordUseCase {
  final AuthRepository _authRepository;

  ChangePasswordUseCase(this._authRepository);

  /// Reauthenticates with [currentPassword], then sets [newPassword].
  ///
  /// :param email: the account's email address.
  /// :param currentPassword: the password in use now.
  /// :param newPassword: the replacement password (min 6 characters).
  /// :returns: ``Right(unit)`` on success or a ``Failure``.
  Future<Either<Failure, Unit>> call({
    required Email email,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      return Left(
        ValidationFailure('New password must be at least 6 characters'),
      );
    }

    try {
      await _authRepository.reauthenticate(email, currentPassword);
    } on AuthException {
      return Left(AuthFailure(
        'Current password is incorrect. Please try again.',
        code: 'WRONG_CURRENT_PASSWORD',
      ));
    }

    try {
      await _authRepository.updatePassword(newPassword);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    }

    return const Right(unit);
  }
}
