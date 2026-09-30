import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../di/riverpod_container.dart';
import '../../../domain/entities/redemption.dart';
import '../../../domain/entities/reward.dart';
import '../../../domain/value_objects/family_id.dart';
import '../../../domain/value_objects/user_id.dart';
import '../../../utils/logger.dart';

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
/// A live view of the family's redemptions stream rather than a
/// one-shot `RewardRepository.outstandingFor` read kept in sync by hand: a
/// one-shot fetch is only ever as fresh as the last explicit
/// `ref.invalidate` call, and every mutation site (claim, settle, the lazy
/// refund below) has to remember to fire one with exactly the right
/// arguments. Miss one, race two, or have a caller torn down between the
/// mutation and the invalidate, and this list silently goes stale — which is
/// exactly what let a settled claim keep showing as outstanding, so
/// re-settling it (or re-claiming the same reward) failed with "That one is
/// already settled." Deriving from the collection's own `.snapshots()`
/// stream means any change to any redemption — claim, settle, or this
/// provider's own lazy refund — reaches every watcher on its own, with no
/// invalidate anywhere.
///
/// Expired claims are settled on the way past: the refund is lazy by design —
/// no cron, no server — so it happens the next time anyone reads. The
/// consequence worth knowing: a child who stops opening the app does not get
/// their stars back until they do. Acceptable, but a real property rather than
/// an accident.
///
/// The refund is fired and not awaited: blocking this stream's emission on
/// the settle round-trip would hold back every *other* outstanding claim in
/// the same list until it returned. [_refunding] instead deduplicates by
/// claim id, so a claim already mid-refund is not resubmitted on the next
/// emission that arrives before its settle completes -- the same claim
/// naturally stops being "expired" input at all once the settle lands and
/// this provider's own live stream reflects the new status.
@riverpod
Stream<List<Redemption>> outstandingClaims(
  Ref ref,
  FamilyId familyId,
  UserId userId,
) {
  final refunding = <String>{};

  Future<void> refund(Redemption claim) async {
    if (!refunding.add(claim.id)) return;
    final result = await ref.read(settleRedemptionUseCaseProvider)(
      redemption: claim,
      actor: claim.claimedBy,
      happened: false,
    );
    result.fold(
      // Logged, not swallowed: a failed lazy refund would otherwise vanish
      // with no trace anywhere, and the claim stays outstanding (correctly)
      // for the next read to try again.
      (failure) => logger.e(
        '[outstandingClaims] lazy refund failed for ${claim.id}: '
        '${failure.message}',
      ),
      (_) {},
    );
  }

  return ref.watch(rewardRepositoryProvider).streamRedemptions(familyId).map((
    all,
  ) {
    final now = DateTime.now();
    final live = <Redemption>[];
    for (final claim in all.where(
      (r) => r.claimedBy == userId && r.isOutstanding,
    )) {
      if (claim.isExpired(now)) {
        // The family let the deadline pass. Give the stars back rather than
        // quietly keeping them; the app is willing to say the family failed.
        // The refund itself lands back here through the same live stream --
        // no need to add it to `live` or invalidate anything.
        unawaited(refund(claim));
      } else {
        live.add(claim);
      }
    }
    return live;
  });
}
