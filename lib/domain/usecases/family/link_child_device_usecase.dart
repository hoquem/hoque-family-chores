import 'package:dartz/dartz.dart';
import 'package:hoque_family_chores/utils/logger.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/managed_child_repository.dart';
import '../../value_objects/user_id.dart';
import 'join_family_usecase.dart' show normaliseInviteCode;

/// Moves a managed child onto this phone: spends the link code a parent made
/// and signs in as the child's existing account, stars and history included.
class LinkChildDeviceUseCase {
  LinkChildDeviceUseCase(this._repository, this._auth);

  /// Server refusals whose message is written for the child. Anything else
  /// (INTERNAL, unavailable, ...) carries text meant for a developer.
  static const _childFacingCodes = {
    'not-found',
    'failed-precondition',
    'invalid-argument',
  };

  static const _genericFailure =
      'Something went wrong. Ask a parent for a new code.';

  final ManagedChildRepository _repository;
  final AuthRepository _auth;

  /// :param code: the link code, as typed (spaces, dashes and case ignored).
  /// :returns: the child's id once this phone is signed in as them.
  Future<Either<Failure, UserId>> call({required String code}) async {
    if (normaliseInviteCode(code).isEmpty) {
      return Left(ValidationFailure('Please enter the code.'));
    }

    final String token;
    try {
      token = await _repository.redeemLinkCode(code);
    } on DataException catch (e, s) {
      if (_childFacingCodes.contains(e.code)) {
        return Left(BusinessFailure(e.message, code: e.code));
      }
      AppLogger().e('[LinkChildDevice] redeemLinkCode failed', error: e, stackTrace: s);
      return Left(ServerFailure(_genericFailure, code: e.code));
    } catch (e, s) {
      AppLogger().e('[LinkChildDevice] redeemLinkCode failed', error: e, stackTrace: s);
      return Left(ServerFailure(_genericFailure));
    }

    try {
      final user = await _auth.signInWithCustomToken(token);
      return Right(UserId(user.uid as String));
    } catch (e, s) {
      AppLogger().e('[LinkChildDevice] sign-in with the link token failed', error: e, stackTrace: s);
      // The code is spent, but the server only clears `managed` once a
      // sign-in really happens, so the parent can simply make a new code.
      return Left(AuthFailure("That didn't finish. Ask a parent for a new code."));
    }
  }
}
