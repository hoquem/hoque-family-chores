import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../di/riverpod_container.dart';
import 'auth_notifier.dart';
import '../../../domain/entities/redemption.dart';
import '../../../domain/entities/reward.dart';
import '../../../domain/value_objects/family_id.dart';
import '../../../domain/value_objects/user_id.dart';

part 'rewards_notifier.g.dart';

/// The rewards a family offers.
@riverpod
Stream<List<Reward>> familyRewards(Ref ref, FamilyId familyId) =>
    ref.watch(rewardRepositoryProvider).streamRewards(familyId);

/// Every claim the family has made, newest first.
@riverpod
Stream<List<Redemption>> familyRedemptions(Ref ref, FamilyId familyId) =>
    ref.watch(rewardRepositoryProvider).streamRedemptions(familyId);

/// Outings the family still owes [userId].
///
/// Expired claims are settled on the way past: the refund is lazy by design —
/// no cron, no server — so it happens the next time anyone reads. The
/// consequence worth knowing: a child who stops opening the app does not get
/// their stars back until they do. Acceptable, but a real property rather than
/// an accident.
@riverpod
Future<List<Redemption>> outstandingClaims(
  Ref ref,
  FamilyId familyId,
  UserId userId,
) async {
  final all = await ref.watch(rewardRepositoryProvider).outstandingFor(
        familyId,
        userId,
      );
  final now = DateTime.now();

  final live = <Redemption>[];
  var refunded = false;
  for (final claim in all) {
    if (claim.isExpired(now)) {
      // The family let the deadline pass. Give the stars back rather than
      // quietly keeping them; the app is willing to say the family failed.
      await ref.read(settleRedemptionUseCaseProvider)(
        redemption: claim,
        actor: claim.claimedBy,
        happened: false,
      );
      refunded = true;
    } else {
      live.add(claim);
    }
  }
  // A lazy refund put stars back on the profile — re-read it so the balance
  // shown updates. The claim is now settled, so the next read won't loop.
  if (refunded) ref.invalidate(authNotifierProvider);
  return live;
}
