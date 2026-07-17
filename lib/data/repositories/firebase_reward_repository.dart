import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/error/exceptions.dart';
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
  FirebaseRewardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
  Future<Redemption> createRedemption(Redemption redemption) async {
    try {
      final doc = _redemptions(redemption.familyId).doc();
      await doc.set(_fromRedemption(redemption));
      return _toRedemption(_fromRedemption(redemption), doc.id,
          redemption.familyId);
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to record claim: $e',
          code: 'REDEMPTION_CREATE_ERROR');
    }
  }

  @override
  Future<void> settleRedemption(
    FamilyId familyId,
    String redemptionId,
    RedemptionStatus outcome,
    DateTime settledAt,
  ) async {
    try {
      await _redemptions(familyId).doc(redemptionId).update({
        'status': outcome.name,
        'settledAt': Timestamp.fromDate(settledAt),
      });
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to settle claim: $e',
          code: 'REDEMPTION_SETTLE_ERROR');
    }
  }

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

  Map<String, dynamic> _fromRedemption(Redemption r) => {
        'rewardId': r.rewardId,
        // Copies, not links. Repricing a reward must not rewrite what a claim
        // already cost.
        'rewardTitle': r.rewardTitle,
        'cost': r.cost.value,
        'claimedBy': r.claimedBy.value,
        'claimedAt': Timestamp.fromDate(r.claimedAt),
        'status': r.status.name,
        'dueBy': r.dueBy == null ? null : Timestamp.fromDate(r.dueBy!),
        'settledAt': r.settledAt == null ? null : Timestamp.fromDate(r.settledAt!),
      };

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
