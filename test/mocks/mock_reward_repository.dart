import 'dart:async';

import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/domain/entities/redemption.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/repositories/reward_repository.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

/// In-memory [RewardRepository] standing in for the real Firestore +
/// Cloud Function pair: `claimReward`/`settleRedemption` mutate the same
/// in-memory list `outstandingFor` queries and `streamRedemptions` streams,
/// the way the real Cloud Functions mutate the same Firestore collection the
/// client reads back from. [claimant] stands in for the authenticated caller
/// the real Cloud Function infers server-side (neither `claimReward` nor
/// `settleRedemption` takes a userId — the server decides who is acting).
///
/// [queryLag] models a real Firestore gap that a naive same-process mock
/// would otherwise hide: `claimReward`/`settleRedemption` are writes made
/// server-side by a Cloud Function via the Admin SDK, not direct writes from
/// this client's Firestore SDK. A direct client write gets an instant local
/// echo ("read your own writes"); a Cloud Function's write does not -- this
/// client only sees it once the server actually pushes the update down, the
/// same way it would see any other family member's change. A `.get()` (used
/// by `outstandingFor`) or `.snapshots()` (used by `streamRedemptions`)
/// issued immediately after the callable resolves can therefore still
/// briefly return the pre-mutation state. [_redemptions] is the immediate,
/// authoritative truth (what `settleRedemption`'s own-write guard checks
/// against, matching the Cloud Function's in-transaction re-read);
/// [_visibleRedemptions] is the lagged copy every query/listener actually
/// reads, publishing [queryLag] after the mutation that produced it.
class MockRewardRepository implements RewardRepository {
  MockRewardRepository({
    required this.claimant,
    this.queryLag = const Duration(milliseconds: 60),
  });

  final UserId claimant;
  final Duration queryLag;

  final List<Reward> _rewards = [];
  final List<Redemption> _redemptions = [];
  List<Redemption> _visibleRedemptions = [];
  int _redemptionCounter = 0;

  final _rewardsController = StreamController<List<Reward>>.broadcast();
  final _redemptionsController = StreamController<List<Redemption>>.broadcast();

  void seedReward(Reward reward) => _rewards.add(reward);

  @override
  Stream<List<Reward>> streamRewards(FamilyId familyId) async* {
    yield _rewardsForFamily(familyId);
    yield* _rewardsController.stream.map((_) => _rewardsForFamily(familyId));
  }

  List<Reward> _rewardsForFamily(FamilyId familyId) =>
      _rewards.where((r) => r.familyId == familyId).toList();

  List<Redemption> _visibleRedemptionsForFamily(FamilyId familyId) =>
      _visibleRedemptions.where((r) => r.familyId == familyId).toList();

  /// Makes the current [_redemptions] truth visible to queries and
  /// listeners after [queryLag] -- see the class doc for why that gap is
  /// real rather than an artificial test seam.
  void _publishRedemptions() {
    final snapshot = List.of(_redemptions);
    void publish() {
      _visibleRedemptions = snapshot;
      if (!_redemptionsController.isClosed) {
        _redemptionsController.add(_visibleRedemptions);
      }
    }

    if (queryLag == Duration.zero) {
      publish();
    } else {
      Future.delayed(queryLag, publish);
    }
  }

  @override
  Future<Reward> createReward(Reward reward) async {
    _rewards.add(reward);
    _rewardsController.add(List.of(_rewards));
    return reward;
  }

  @override
  Future<void> updateReward(Reward reward) async {
    final index = _rewards.indexWhere((r) => r.id == reward.id);
    if (index == -1) {
      throw NotFoundException('Reward not found', code: 'REWARD_NOT_FOUND');
    }
    _rewards[index] = reward;
    _rewardsController.add(List.of(_rewards));
  }

  @override
  Future<void> deleteReward(FamilyId familyId, String rewardId) async {
    _rewards.removeWhere((r) => r.id == rewardId && r.familyId == familyId);
    _rewardsController.add(List.of(_rewards));
  }

  @override
  Stream<List<Redemption>> streamRedemptions(FamilyId familyId) async* {
    yield _visibleRedemptionsForFamily(familyId);
    yield* _redemptionsController.stream.map(
      (_) => _visibleRedemptionsForFamily(familyId),
    );
  }

  @override
  Future<String> claimReward(FamilyId familyId, String rewardId) async {
    final reward = _rewards.firstWhere(
      (r) => r.id == rewardId && r.familyId == familyId,
      orElse:
          () =>
              throw NotFoundException(
                'Reward not found',
                code: 'REWARD_NOT_FOUND',
              ),
    );
    final id = 'redemption_${_redemptionCounter++}';
    final redemption = Redemption(
      id: id,
      familyId: familyId,
      rewardId: rewardId,
      rewardTitle: reward.title,
      cost: reward.cost,
      claimedBy: claimant,
      claimedAt: DateTime.now(),
      status: RedemptionStatus.claimed,
      dueBy: reward.timeframe.dueFrom(DateTime.now()),
    );
    _redemptions.add(redemption);
    _publishRedemptions();
    return id;
  }

  @override
  Future<void> settleRedemption(
    FamilyId familyId,
    String redemptionId, {
    required bool happened,
  }) async {
    final index = _redemptions.indexWhere(
      (r) => r.id == redemptionId && r.familyId == familyId,
    );
    if (index == -1) {
      throw NotFoundException('Claim not found', code: 'REDEMPTION_NOT_FOUND');
    }
    final current = _redemptions[index];
    // The real in-transaction re-read guard the Cloud Function comment
    // describes: settling twice must fail here even if the caller's own copy
    // of the redemption still (wrongly) believes it is outstanding.
    if (!current.isOutstanding) {
      throw const ValidationException(
        'That one is already settled.',
        code: 'ALREADY_SETTLED',
      );
    }
    _redemptions[index] = current.settle(
      happened ? RedemptionStatus.fulfilled : RedemptionStatus.refunded,
      DateTime.now(),
    );
    _publishRedemptions();
  }

  /// A one-shot query -- reads [_visibleRedemptions], the lagged view, the
  /// same way the real Firestore `.get()` does. Unlike `streamRedemptions`,
  /// nothing calls this again once the lag passes, so a caller that fetches
  /// right after a mutation and never refetches keeps whatever stale answer
  /// it got.
  @override
  Future<List<Redemption>> outstandingFor(
    FamilyId familyId,
    UserId userId,
  ) async {
    return _visibleRedemptions
        .where(
          (r) =>
              r.familyId == familyId &&
              r.claimedBy == userId &&
              r.status == RedemptionStatus.claimed,
        )
        .toList();
  }

  void dispose() {
    _rewardsController.close();
    _redemptionsController.close();
  }
}
