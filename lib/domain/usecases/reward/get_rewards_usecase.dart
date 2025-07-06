import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/repositories/reward_repository.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:dartz/dartz.dart';

class GetRewardsUseCase {
  final RewardRepository _rewardRepository;

  GetRewardsUseCase(this._rewardRepository);

  Future<Either<Failure, List<Reward>>> call(FamilyId familyId) async {
    try {
      final rewards = await _rewardRepository.getRewards(familyId);
      return Right(rewards);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
} 