import 'package:dartz/dartz.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../entities/redemption.dart';
import '../../entities/reward.dart';
import '../../repositories/reward_repository.dart';
import '../../repositories/user_repository.dart';
import '../../value_objects/user_id.dart';

/// Spends stars on a reward.
///
/// Anyone in the family may claim anything, including a reward they created
/// themselves — proposing "bike ride with Dad" and then claiming it is the
/// feature working, not an exploit. The stars were earned on chores somebody
/// else signed off.
class ClaimRewardUseCase {
  ClaimRewardUseCase(this._rewards, this._users);

  final RewardRepository _rewards;
  final UserRepository _users;

  Future<Either<Failure, Redemption>> call({
    required Reward reward,
    required UserId claimedBy,
    required DateTime now,
  }) async {
    try {
      // Take the stars FIRST.
      //
      // If this fails — not enough stars, or a concurrent claim got there
      // first — nothing else has happened yet. The reverse order would record
      // a promise the claimant never paid for, and the family would owe an
      // outing bought with stars that were never spent.
      //
      // subtractPoints is transactional and refuses to go below zero, so two
      // claims racing for the same last 200 stars cannot both win.
      await _users.subtractPoints(claimedBy, reward.cost);

      final redemption = Redemption(
        id: '',
        familyId: reward.familyId,
        rewardId: reward.id,
        // Copied, not linked: repricing "Tennis" later must not rewrite what
        // this claim cost.
        rewardTitle: reward.title,
        cost: reward.cost,
        claimedBy: claimedBy,
        claimedAt: now,
        status: RedemptionStatus.claimed,
        dueBy: reward.timeframe.dueFrom(now),
      );

      try {
        return Right(await _rewards.createRedemption(redemption));
      } catch (e) {
        // The stars are gone but the claim was never recorded, so nobody knows
        // the family owes anything. Put them back rather than let them vanish:
        // silently losing a child's stars is the worst outcome this flow has.
        await _users.addPoints(claimedBy, reward.cost);
        rethrow;
      }
    } on ValidationException catch (e) {
      // Raised by subtractPoints when the balance will not cover it.
      return Left(BusinessFailure(
        'Not enough stars for that yet — keep going!',
        code: e.code,
      ));
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to claim reward: $e'));
    }
  }
}
