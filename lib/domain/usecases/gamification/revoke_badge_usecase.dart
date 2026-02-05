import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/badge_repository.dart';
import '../../value_objects/user_id.dart';
import '../../value_objects/family_id.dart';

/// Use case for revoking badges from users
class RevokeBadgeUseCase {
  final BadgeRepository _badgeRepository;

  RevokeBadgeUseCase(this._badgeRepository);

  /// Revokes a badge from a user
  /// 
  /// [familyId] - ID of the family
  /// [userId] - ID of the user to revoke the badge from
  /// [badgeId] - ID of the badge to revoke
  /// 
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required FamilyId familyId,
    required UserId userId,
    required String badgeId,
  }) async {
    try {
      // Validate family ID
      if (familyId.value.trim().isEmpty) {
        return Left(ValidationFailure('Family ID cannot be empty'));
      }

      // Validate user ID
      if (userId.value.trim().isEmpty) {
        return Left(ValidationFailure('User ID cannot be empty'));
      }

      // Validate badge ID
      if (badgeId.trim().isEmpty) {
        return Left(ValidationFailure('Badge ID cannot be empty'));
      }

      // Revoke the badge
      await _badgeRepository.revokeBadge(familyId, userId, badgeId);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to revoke badge: $e'));
    }
  }
} 