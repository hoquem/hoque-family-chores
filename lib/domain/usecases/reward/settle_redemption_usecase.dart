import 'package:dartz/dartz.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../entities/redemption.dart';
import '../../repositories/reward_repository.dart';
import '../../repositories/user_repository.dart';
import '../../value_objects/user_id.dart';

/// Closes a claim: it happened, or it didn't and the stars go back.
///
/// **The claimant is the judge.** Everywhere else in this app a parent rules on
/// a child's work; here the family made a promise and the child says whether it
/// was kept. Nobody else can mark an outing delivered — a parent insisting the
/// park trip counted would be the app taking the family's side against the
/// child, which is the opposite of what it is for.
class SettleRedemptionUseCase {
  SettleRedemptionUseCase(this._rewards, this._users);

  final RewardRepository _rewards;
  final UserRepository _users;

  /// [happened] false refunds the stars.
  Future<Either<Failure, Unit>> call({
    required Redemption redemption,
    required UserId actor,
    required bool happened,
    required DateTime now,
  }) async {
    try {
      if (redemption.claimedBy != actor) {
        return Left(PermissionFailure(
          'Only the person who claimed this can say whether it happened.',
        ));
      }

      if (!redemption.isOutstanding) {
        // Already fulfilled or refunded. Settling twice would either refund
        // stars a second time or take back an outing that already happened.
        return Left(BusinessFailure('That one is already settled.'));
      }

      final outcome =
          happened ? RedemptionStatus.fulfilled : RedemptionStatus.refunded;

      // Record the outcome before moving stars. If the refund succeeded and
      // this then failed, the claim would still read as outstanding and could
      // be refunded again — stars from nothing.
      await _rewards.settleRedemption(
        redemption.familyId,
        redemption.id,
        outcome,
        now,
      );

      if (!happened) {
        await _users.addPoints(redemption.claimedBy, redemption.cost);
      }

      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to settle claim: $e'));
    }
  }
}
