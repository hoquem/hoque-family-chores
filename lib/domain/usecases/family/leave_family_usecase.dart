import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/family_repository.dart';
import '../../repositories/user_repository.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/user_id.dart';

/// Use case for leaving the family the user currently belongs to.
///
/// The inverse of :class:`JoinFamilyUseCase`: it drops the user from the
/// family roster and then clears their own profile's ``familyId``. The
/// security rules let a member remove only themselves and clear only their own
/// profile, so no elevated role is required.
class LeaveFamilyUseCase {
  final FamilyRepository _familyRepository;
  final UserRepository _userRepository;

  LeaveFamilyUseCase(this._familyRepository, this._userRepository);

  /// Removes [userId] from their current family.
  ///
  /// :param userId: ID of the user leaving.
  /// :returns: ``Unit`` on success or ``Failure`` on error.
  Future<Either<Failure, Unit>> call({required UserId userId}) async {
    try {
      final user = await _userRepository.getUserProfile(userId);
      if (user == null) {
        return Left(NotFoundFailure('User profile not found'));
      }
      if (user.familyId.value.isEmpty) {
        return Left(BusinessFailure("You're not in a family."));
      }

      final familyId = user.familyId;

      // Profile first, then roster. The family update is gated on the *family
      // doc's* memberIds (not the caller's profile), so clearing the profile
      // first doesn't block the roster removal. This ordering makes a partial
      // failure benign: if the roster write fails, the profile is already
      // detached so the user routes to onboarding and can rejoin, leaving only
      // a stale roster entry. The reverse order would strand them — once off
      // the roster, a retry can't clear the profile because the roster rule
      // then denies a non-member, pinning them to a family they've left.
      await _userRepository.updateUserProfile(
        user.copyWith(familyId: FamilyId.empty, updatedAt: DateTime.now()),
      );
      await _familyRepository.removeUserFromFamily(familyId, userId);

      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to leave family: $e'));
    }
  }
}
