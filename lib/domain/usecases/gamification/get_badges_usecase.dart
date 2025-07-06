import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/badge.dart';
import '../../repositories/badge_repository.dart';
import '../../value_objects/family_id.dart';

/// Use case for getting available badges
class GetBadgesUseCase {
  final BadgeRepository _badgeRepository;

  GetBadgesUseCase(this._badgeRepository);

  /// Gets all badges for a family
  /// 
  /// [familyId] - ID of the family to get badges for
  /// 
  /// Returns [List<Badge>] on success or [Failure] on error
  Future<Either<Failure, List<Badge>>> call({
    required FamilyId familyId,
  }) async {
    try {
      // Validate family ID
      if (familyId.value.trim().isEmpty) {
        return Left(ValidationFailure('Family ID cannot be empty'));
      }

      // Get the badges
      final badges = await _badgeRepository.getBadges(familyId);
      return Right(badges);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to get badges: $e'));
    }
  }
} 