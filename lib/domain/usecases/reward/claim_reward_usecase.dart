import 'package:dartz/dartz.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../entities/reward.dart';
import '../../repositories/reward_repository.dart';

/// Spends stars on a reward.
///
/// Anyone in the family may claim anything, including a reward they created
/// themselves — proposing "bike ride with Dad" and then claiming it is the
/// feature working, not an exploit.
///
/// Deducting the stars and recording the claim happen server-side (Cloud
/// Function), atomically and refusing to go below zero, so a claim can never
/// overspend and the client never touches `points`.
class ClaimRewardUseCase {
  ClaimRewardUseCase(this._rewards);

  final RewardRepository _rewards;

  Future<Either<Failure, Unit>> call({required Reward reward}) async {
    try {
      await _rewards.claimReward(reward.familyId, reward.id);
      return const Right(unit);
    } on ValidationException catch (e) {
      // Raised when the balance will not cover it.
      return Left(BusinessFailure(e.message, code: e.code));
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to claim reward: $e'));
    }
  }
}
