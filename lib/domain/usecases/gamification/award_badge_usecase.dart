import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/badge_repository.dart';
import '../../value_objects/user_id.dart';
import '../../value_objects/family_id.dart';

/// Use case for awarding badges to users
class AwardBadgeUseCase {
  final BadgeRepository _badgeRepository;

  // final UserRepository _userRepository; // Unused - commented out

  AwardBadgeUseCase(this._badgeRepository, [dynamic _]);

  /// Awards a badge to a user
  /// 
  /// [familyId] - ID of the family
  /// [userId] - ID of the user to award the badge to
  /// [badgeId] - ID of the badge to award
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

      // Award the badge
      await _badgeRepository.awardBadge(familyId, userId, badgeId);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to award badge: $e'));
    }
  }
} 