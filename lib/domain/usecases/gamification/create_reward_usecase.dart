import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/reward.dart';
import '../../repositories/reward_repository.dart';
import '../../value_objects/family_id.dart';

/// Use case for creating new rewards
class CreateRewardUseCase {
  final RewardRepository _rewardRepository;

  CreateRewardUseCase(this._rewardRepository);

  /// Creates a new reward
  /// 
  /// [familyId] - ID of the family to create the reward for
  /// [reward] - The reward to create
  /// 
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required FamilyId familyId,
    required Reward reward,
  }) async {
    try {
      // Validate family ID
      if (familyId.value.trim().isEmpty) {
        return Left(ValidationFailure('Family ID cannot be empty'));
      }

      // Validate reward data
      if (reward.name.trim().isEmpty) {
        return Left(ValidationFailure('Reward name cannot be empty'));
      }

      if (reward.description.trim().isEmpty) {
        return Left(ValidationFailure('Reward description cannot be empty'));
      }

      if (reward.pointsCost.value <= 0) {
        return Left(ValidationFailure('Reward points cost must be greater than 0'));
      }

      // Create the reward
      await _rewardRepository.createReward(familyId, reward);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to create reward: $e'));
    }
  }
} 