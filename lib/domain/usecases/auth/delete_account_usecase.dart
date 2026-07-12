import 'package:dartz/dartz.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';

/// Use case for permanently deleting the signed-in user's account
/// (App Store guideline 5.1.1(v)).
class DeleteAccountUseCase {
  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  DeleteAccountUseCase(this._userRepository, this._authRepository);

  /// Deletes [user]'s profile document and then the Firebase auth user.
  ///
  /// The profile document goes first: Firestore rules only allow a user to
  /// delete their own document while their auth user still exists. If the
  /// auth-user delete is then rejected (Firebase requires a recent login),
  /// the profile document is restored so the surviving account stays usable,
  /// and an [AuthFailure] with code `REQUIRES_RECENT_LOGIN` is returned.
  ///
  /// [user] - the full profile of the account to delete, needed to restore
  /// the document if the second step fails
  ///
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({required User user}) async {
    try {
      await _userRepository.deleteUserProfile(user.id);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to delete profile: $e'));
    }

    try {
      await _authRepository.deleteUser();
    } on AuthException catch (e) {
      await _userRepository.createUserProfile(user);
      if (e.code == 'REQUIRES_RECENT_LOGIN') {
        return Left(AuthFailure(
          'For security, deleting your account needs a recent sign-in. '
          'Please sign out, sign in again, and retry.',
          code: e.code,
        ));
      }
      return Left(AuthFailure(e.message, code: e.code));
    }

    return const Right(unit);
  }
}
