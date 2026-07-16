import 'package:dartz/dartz.dart' hide Task;

import '../../../core/error/failures.dart';
import '../../entities/family.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../value_objects/user_id.dart';
import '../user/initialize_user_data_usecase.dart';
import 'join_family_usecase.dart';

/// Joins a family as a child using only a display name and an invite code.
///
/// Children have no email or password: an anonymous Firebase account is
/// created and a normal profile (role child, no email) is linked to the
/// family, so tasks, points, and security rules work exactly as they do
/// for adults.
class JoinFamilyAsChildUseCase {
  final AuthRepository _authRepository;
  final InitializeUserDataUseCase _initializeUserData;
  final JoinFamilyUseCase _joinFamily;

  JoinFamilyAsChildUseCase(
    this._authRepository,
    this._initializeUserData,
    this._joinFamily,
  );

  /// Signs in anonymously, creates the child profile, and joins the family.
  ///
  /// Any failure after the anonymous sign-in deletes the anonymous account
  /// again: a signed-in user without a profile would strand the app on the
  /// home screen at next launch.
  ///
  /// :param name: the child's display name.
  /// :param inviteCode: the family's invite code.
  /// :returns: the joined ``FamilyEntity`` or a ``Failure``.
  Future<Either<Failure, FamilyEntity>> call({
    required String name,
    required String inviteCode,
  }) async {
    if (name.trim().isEmpty) {
      return Left(ValidationFailure('Please enter your name'));
    }
    if (inviteCode.trim().isEmpty) {
      return Left(ValidationFailure('Please enter your family code'));
    }

    final dynamic firebaseUser;
    try {
      firebaseUser = await _authRepository.signInAnonymously();
    } catch (e) {
      return Left(AuthFailure('Could not start the sign-in: $e'));
    }
    final userId = UserId(firebaseUser.uid as String);

    final result = await _createProfileAndJoin(userId, name.trim(), inviteCode);
    if (result.isLeft()) {
      // Roll back: never leave an authenticated account with no profile.
      await _authRepository.deleteUser();
    }
    return result;
  }

  Future<Either<Failure, FamilyEntity>> _createProfileAndJoin(
    UserId userId,
    String name,
    String inviteCode,
  ) async {
    final profileResult = await _initializeUserData.call(
      userId: userId,
      name: name,
      role: UserRole.child,
    );
    final profileFailure = profileResult.fold((f) => f, (_) => null);
    if (profileFailure != null) return Left(profileFailure);

    return _joinFamily.call(
      inviteCode: inviteCode,
      userId: userId,
      role: UserRole.child,
    );
  }
}
