// Settling a claim moves stars, and it does so exactly once.
//
// The use-case tests (claim_and_settle_test.dart) prove who may settle and what
// outcome they dispatch. These prove the part that only exists in the
// repository: the refund and the status flip land together, and the in-
// transaction status re-read refuses a second settlement. No mock can show
// that — it needs a Firestore that actually runs the transaction, so these run
// against fake_cloud_firestore.
//
// On concurrency: no unit test drives two truly simultaneous transactions, so
// these are sequential. They prove the *guard exists* — settle once, then try
// again and watch it refuse and move zero stars. Real concurrent retry is
// Firestore's job; the test proves the mechanism is wired, not that Firestore
// works.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/data/repositories/firebase_reward_repository.dart';
import 'package:hoque_family_chores/domain/entities/redemption.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';

final _familyId = FamilyId('fam1');
const _claimantId = 'kid1';
const _redemptionId = 'rd1';

/// Seeds a claimant with [balance] stars and one outstanding claim costing
/// [cost], and returns a repository wired to the same fake Firestore.
Future<(FakeFirebaseFirestore, FirebaseRewardRepository)> _seed({
  required int balance,
  int cost = 200,
  RedemptionStatus status = RedemptionStatus.claimed,
}) async {
  final db = FakeFirebaseFirestore();
  await db.collection('users').doc(_claimantId).set({'points': balance});
  await db
      .collection('families')
      .doc(_familyId.value)
      .collection('redemptions')
      .doc(_redemptionId)
      .set({
    'rewardId': 'rw1',
    'rewardTitle': 'Walk in the park',
    'cost': cost,
    'claimedBy': _claimantId,
    'claimedAt': Timestamp.fromDate(DateTime(2026, 7, 15)),
    'status': status.name,
    'dueBy': null,
    'settledAt': null,
  });
  return (db, FirebaseRewardRepository(firestore: db));
}

Future<int> _points(FakeFirebaseFirestore db) async =>
    ((await db.collection('users').doc(_claimantId).get()).data()!['points']
            as num)
        .toInt();

Future<String> _status(FakeFirebaseFirestore db) async =>
    (await db
            .collection('families')
            .doc(_familyId.value)
            .collection('redemptions')
            .doc(_redemptionId)
            .get())
        .data()!['status'] as String;

void main() {
  test('refund returns the stars AND marks the claim refunded', () async {
    final (db, repo) = await _seed(balance: 0, cost: 200);

    await repo.settleRedemption(
        _familyId, _redemptionId, RedemptionStatus.refunded, DateTime(2026, 7, 18));

    expect(await _points(db), 200, reason: 'stars came back');
    expect(await _status(db), 'refunded', reason: 'and the claim is closed');
  });

  test('fulfilled: the claim closes and NO stars are refunded', () async {
    final (db, repo) = await _seed(balance: 0, cost: 200);

    await repo.settleRedemption(
        _familyId, _redemptionId, RedemptionStatus.fulfilled, DateTime(2026, 7, 18));

    expect(await _points(db), 0, reason: 'a delivered outing costs its stars');
    expect(await _status(db), 'fulfilled');
  });

  test('settling an already-refunded claim throws and moves zero stars',
      () async {
    // This is the double-refund exploit. The first refund left status=refunded;
    // the in-transaction re-read must now refuse, or a 200-star claim refunds
    // 400.
    final (db, repo) = await _seed(
        balance: 200, cost: 200, status: RedemptionStatus.refunded);

    await expectLater(
      () => repo.settleRedemption(
          _familyId, _redemptionId, RedemptionStatus.refunded, DateTime(2026, 7, 18)),
      throwsA(isA<DataException>()),
    );

    expect(await _points(db), 200, reason: 'balance unchanged — no second refund');
  });

  test('settling twice in a row refunds exactly once', () async {
    final (db, repo) = await _seed(balance: 0, cost: 200);

    await repo.settleRedemption(
        _familyId, _redemptionId, RedemptionStatus.refunded, DateTime(2026, 7, 18));
    // The second attempt — the race loser, run sequentially here — must bounce.
    await expectLater(
      () => repo.settleRedemption(
          _familyId, _redemptionId, RedemptionStatus.refunded, DateTime(2026, 7, 19)),
      throwsA(isA<DataException>()),
    );

    expect(await _points(db), 200, reason: 'refunded once, not twice');
  });

  test('a missing claim throws rather than silently doing nothing', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirebaseRewardRepository(firestore: db);

    await expectLater(
      () => repo.settleRedemption(
          _familyId, 'ghost', RedemptionStatus.refunded, DateTime(2026, 7, 18)),
      throwsA(isA<DataException>()),
    );
  });
}
