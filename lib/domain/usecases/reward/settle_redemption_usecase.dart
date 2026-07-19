import 'package:dartz/dartz.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../entities/redemption.dart';
import '../../repositories/reward_repository.dart';
import '../../value_objects/user_id.dart';

/// Closes a claim: it happened, or it didn't and the stars go back.
///
/// **The claimant is the judge.** Everywhere else in this app a parent rules on
/// a child's work; here the family made a promise and the child says whether it
/// was kept. Nobody else can mark an outing delivered — a parent insisting the
/// park trip counted would be the app taking the family's side against the
/// child, which is the opposite of what it is for.
class SettleRedemptionUseCase {
  SettleRedemptionUseCase(this._rewards);

  final RewardRepository _rewards;

  /// [happened] false refunds the stars.
  Future<Either<Failure, Unit>> call({
    required Redemption redemption,
    required UserId actor,
    required bool happened,
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

      // The checks above are friendly early exits; the Cloud Function re-reads
      // the status inside its transaction as the real guard (and returns the
      // stars atomically on a refund), so a claim can never be refunded twice.
      await _rewards.settleRedemption(
        redemption.familyId,
        redemption.id,
        happened: happened,
      );

      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to settle claim: $e'));
    }
  }
}
