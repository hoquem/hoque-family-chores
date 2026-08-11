import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/family.dart';
import '../../entities/user.dart';
import '../../repositories/family_repository.dart';
import '../../repositories/user_repository.dart';
import '../../value_objects/user_id.dart';

/// Strips the separators people add to a long code and upper-cases the rest.
///
/// Twelve characters is long enough that it gets written down and read back in
/// groups — "ABCD EFGH JKMN", or with dashes, or split across a line. Those are
/// how a human breaks up a long string, not a different code, so refusing them
/// would be the app being pedantic at the one moment a new member is trying to
/// get in. Anything outside the code alphabet goes; what is left is compared.
String normaliseInviteCode(String raw) =>
    raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// Breaks a code into groups of four for display: ``ABCD EFGH JKMN``.
///
/// Twelve unbroken characters is a lot to read down a phone line to a child.
/// Grouped, it is three short things to say. [normaliseInviteCode] is the
/// inverse — whatever the reader does with those spaces, the code still
/// resolves — so the two must always be changed together.
String formatInviteCode(String code) {
  final buffer = StringBuffer();
  for (var i = 0; i < code.length; i += 4) {
    if (i > 0) buffer.write(' ');
    buffer.write(code.substring(i, i + 4 > code.length ? code.length : i + 4));
  }
  return buffer.toString();
}

/// Use case for joining an existing family with an invite code
class JoinFamilyUseCase {
  final FamilyRepository _familyRepository;
  final UserRepository _userRepository;

  JoinFamilyUseCase(this._familyRepository, this._userRepository);

  /// Joins the family matching [inviteCode] and links the user's profile.
  ///
  /// :param inviteCode: The family's invite code (case-insensitive).
  /// :param userId: ID of the joining user.
  /// :param role: Role the user joins with (parent or child).
  /// :returns: ``FamilyEntity`` on success or ``Failure`` on error.
  Future<Either<Failure, FamilyEntity>> call({
    required String inviteCode,
    required UserId userId,
    required UserRole role,
  }) async {
    try {
      final code = normaliseInviteCode(inviteCode);
      if (code.isEmpty) {
        return Left(ValidationFailure('Invite code cannot be empty'));
      }

      final user = await _userRepository.getUserProfile(userId);
      if (user == null) {
        return Left(NotFoundFailure('User profile not found'));
      }
      if (user.familyId.value.isNotEmpty) {
        return Left(BusinessFailure('You already belong to a family'));
      }

      final familyId = await _familyRepository.resolveInviteCode(code);
      if (familyId == null) {
        return Left(NotFoundFailure('No family found for that invite code'));
      }

      // Prove we hold the invite code before reading or joining the family: the
      // security rules gate both the family read and the memberIds self-add on
      // this request, so a bare family id cannot join.
      await _familyRepository.requestToJoinFamily(familyId, userId, code);

      final family = await _familyRepository.getFamily(familyId);
      if (family == null) {
        return Left(NotFoundFailure('No family found for that invite code'));
      }

      if (!family.hasMember(userId)) {
        await _familyRepository.addUserToFamily(family.id, userId);
      }

      await _userRepository.updateUserProfile(
        user.copyWith(
          familyId: family.id,
          role: role,
          updatedAt: DateTime.now(),
        ),
      );

      return Right(family.addMember(userId));
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to join family: $e'));
    }
  }
}
