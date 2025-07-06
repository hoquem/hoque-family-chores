import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/reward.dart';
import '../../repositories/reward_repository.dart';
import '../../value_objects/family_id.dart';

/// Use case for getting available rewards
class GetRewardsUseCase {
  final RewardRepository _rewardRepository;

  GetRewardsUseCase(this._rewardRepository);

  /// Gets all rewards for a family
  /// 
  /// [familyId] - ID of the family to get rewards for
  /// 
  /// Returns [List<Reward>] on success or [Failure] on error
  Future<Either<Failure, List<Reward>>> call({
    required FamilyId familyId,
  }) async {
    try {
      // Validate family ID
      if (familyId.value.trim().isEmpty) {
        return Left(ValidationFailure('Family ID cannot be empty'));
      }

      // Get the rewards
      final rewards = await _rewardRepository.getRewards(familyId);
      return Right(rewards);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to get rewards: $e'));
    }
  }
} 