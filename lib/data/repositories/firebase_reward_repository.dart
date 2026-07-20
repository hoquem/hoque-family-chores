import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/error/exceptions.dart';
import '../services/economy_functions.dart';
import '../../domain/entities/redemption.dart';
import '../../domain/entities/reward.dart';
import '../../domain/repositories/reward_repository.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/points.dart';
import '../../domain/value_objects/user_id.dart';

/// Rewards and claims, under `families/{familyId}/…`.
///
/// Sits beside `tasks` in the same family document so one security rule shape
/// covers all three, and so a family's data stays in one subtree.
class FirebaseRewardRepository implements RewardRepository {
  FirebaseRewardRepository({
    FirebaseFirestore? firestore,
    EconomyFunctions? economy,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _economy = economy ?? EconomyFunctions();

  final FirebaseFirestore _firestore;
  final EconomyFunctions _economy;

  CollectionReference<Map<String, dynamic>> _rewards(FamilyId familyId) =>
      _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('rewards');

  CollectionReference<Map<String, dynamic>> _redemptions(FamilyId familyId) =>
      _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('redemptions');

  @override
  Stream<List<Reward>> streamRewards(FamilyId familyId) => _rewards(familyId)
      .snapshots()
      .map((s) => s.docs.map((d) => _toReward(d.data(), d.id, familyId)).toList()
        ..sort((a, b) => a.cost.value.compareTo(b.cost.value)));

  @override
  Future<Reward> createReward(Reward reward) async {
    try {
      final doc = _rewards(reward.familyId).doc();
      final withId = reward.copyWith(id: doc.id);
      await doc.set(_fromReward(withId));
      return withId;
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to create reward: $e',
          code: 'REWARD_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateReward(Reward reward) async {
    try {
      // Targeted write: only the editable fields, so createdBy/createdAt are
      // never rewritten. Last-write-wins across concurrent edits.
      await _rewards(reward.familyId).doc(reward.id).update({
        'title': reward.title,
        'cost': reward.cost.value,
        'timeframe': reward.timeframe.name,
      });
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to update reward: $e',
          code: 'REWARD_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteReward(FamilyId familyId, String rewardId) async {
    try {
      await _rewards(familyId).doc(rewardId).delete();
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to delete reward: $e',
          code: 'REWARD_DELETE_ERROR');
    }
  }

  @override
  Stream<List<Redemption>> streamRedemptions(FamilyId familyId) =>
      _redemptions(familyId).snapshots().map((s) => s.docs
          .map((d) => _toRedemption(d.data(), d.id, familyId))
          .toList()
        ..sort((a, b) => b.claimedAt.compareTo(a.claimedAt)));

  @override
  Future<String> claimReward(FamilyId familyId, String rewardId) =>
      // Deducting stars and recording the claim happen server-side (Cloud
      // Function), atomically, so a claim can never overspend.
      _economy.claimReward(familyId, rewardId);

  @override
  Future<void> settleRedemption(
    FamilyId familyId,
    String redemptionId, {
    required bool happened,
  }) =>
      // Status flip and refund happen server-side (Cloud Function) with the
      // same in-transaction status re-read guard, so a claim can't refund twice.
      _economy.settleRedemption(familyId, redemptionId, happened: happened);

  @override
  Future<List<Redemption>> outstandingFor(
      FamilyId familyId, UserId userId) async {
    try {
      final snapshot = await _redemptions(familyId)
          .where('claimedBy', isEqualTo: userId.value)
          .where('status', isEqualTo: RedemptionStatus.claimed.name)
          .get();
      return snapshot.docs
          .map((d) => _toRedemption(d.data(), d.id, familyId))
          .toList();
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to load claims: $e',
          code: 'REDEMPTION_FETCH_ERROR');
    }
  }

  Map<String, dynamic> _fromReward(Reward r) => {
        'title': r.title,
        'cost': r.cost.value,
        'timeframe': r.timeframe.name,
        'createdBy': r.createdBy.value,
        'createdAt': Timestamp.fromDate(r.createdAt),
      };

  Reward _toReward(Map<String, dynamic> d, String id, FamilyId familyId) =>
      Reward(
        id: id,
        familyId: familyId,
        title: d['title'] as String? ?? '',
        cost: Points((d['cost'] as num?)?.toInt() ?? 0),
        // An unknown timeframe is treated as open-ended rather than throwing:
        // the value is a display hint and a deadline, and a reward that cannot
        // be read at all is worse than one with no deadline. Unlike a task's
        // status, nothing branches on it.
        timeframe: RewardTimeframe.values.firstWhere(
          (t) => t.name == d['timeframe'],
          orElse: () => RewardTimeframe.openEnded,
        ),
        createdBy: UserId(d['createdBy'] as String? ?? 'unknown'),
        createdAt: _date(d['createdAt']) ?? DateTime.now(),
      );


  Redemption _toRedemption(
          Map<String, dynamic> d, String id, FamilyId familyId) =>
      Redemption(
        id: id,
        familyId: familyId,
        rewardId: d['rewardId'] as String? ?? '',
        rewardTitle: d['rewardTitle'] as String? ?? '',
        cost: Points((d['cost'] as num?)?.toInt() ?? 0),
        claimedBy: UserId(d['claimedBy'] as String? ?? 'unknown'),
        claimedAt: _date(d['claimedAt']) ?? DateTime.now(),
        // A status we cannot read must NOT silently become `claimed` — that
        // would resurrect a settled claim and let it be refunded again. Fail
        // loudly instead; this one branches on real money.
        status: RedemptionStatus.values.firstWhere(
          (s) => s.name == d['status'],
          orElse: () => throw ParsingException(
            'Unknown redemption status: ${d['status']}',
            code: 'REDEMPTION_BAD_STATUS',
          ),
        ),
        dueBy: _date(d['dueBy']),
        settledAt: _date(d['settledAt']),
      );

  DateTime? _date(dynamic v) => v is Timestamp ? v.toDate() : null;
}
