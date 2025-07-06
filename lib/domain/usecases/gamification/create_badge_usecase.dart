import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/badge.dart';
import '../../repositories/badge_repository.dart';
import '../../value_objects/family_id.dart';

/// Use case for creating new badges
class CreateBadgeUseCase {
  final BadgeRepository _badgeRepository;

  CreateBadgeUseCase(this._badgeRepository);

  /// Creates a new badge
  /// 
  /// [familyId] - ID of the family to create the badge for
  /// [badge] - The badge to create
  /// 
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required FamilyId familyId,
    required Badge badge,
  }) async {
    try {
      // Validate family ID
      if (familyId.value.trim().isEmpty) {
        return Left(ValidationFailure('Family ID cannot be empty'));
      }

      // Validate badge data
      if (badge.name.trim().isEmpty) {
        return Left(ValidationFailure('Badge name cannot be empty'));
      }

      if (badge.description.trim().isEmpty) {
        return Left(ValidationFailure('Badge description cannot be empty'));
      }

      if (badge.requiredPoints.value <= 0) {
        return Left(ValidationFailure('Badge points required must be greater than 0'));
      }

      // Create the badge
      await _badgeRepository.createBadge(familyId, badge);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to create badge: $e'));
    }
  }
} 