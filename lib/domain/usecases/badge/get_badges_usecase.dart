import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/badge.dart';
import 'package:hoque_family_chores/domain/repositories/badge_repository.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:dartz/dartz.dart';

class GetBadgesUseCase {
  final BadgeRepository _badgeRepository;

  GetBadgesUseCase(this._badgeRepository);

  Future<Either<Failure, List<Badge>>> call(FamilyId familyId) async {
    try {
      final badges = await _badgeRepository.getBadges(familyId);
      return Right(badges);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
} 