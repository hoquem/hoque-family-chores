// updateReward edits a reward's title/cost/timeframe in place. It's a targeted
// write (last-write-wins), so it must change exactly those fields and leave the
// provenance (createdBy/createdAt) intact.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/repositories/firebase_reward_repository.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

final _familyId = FamilyId('fam1');
const _rewardId = 'rw1';

Future<FakeFirebaseFirestore> _seedReward() async {
  final db = FakeFirebaseFirestore();
  await db
      .collection('families')
      .doc(_familyId.value)
      .collection('rewards')
      .doc(_rewardId)
      .set({
    'title': 'Walk in the park',
    'cost': 100,
    'timeframe': RewardTimeframe.openEnded.name,
    'createdBy': 'parent1',
    'createdAt': Timestamp.fromDate(DateTime(2026, 7, 1)),
  });
  return db;
}

void main() {
  test('updateReward changes title/cost/timeframe and keeps provenance',
      () async {
    final db = await _seedReward();
    final repo = FirebaseRewardRepository(firestore: db);

    await repo.updateReward(
      Reward(
        id: _rewardId,
        familyId: _familyId,
        title: 'Trip to the cinema',
        cost: Points(250),
        timeframe: RewardTimeframe.thisWeek,
        createdBy: UserId('parent1'),
        createdAt: DateTime(2026, 7, 1),
      ),
    );

    final data = (await db
            .collection('families')
            .doc(_familyId.value)
            .collection('rewards')
            .doc(_rewardId)
            .get())
        .data()!;

    expect(data['title'], 'Trip to the cinema');
    expect(data['cost'], 250);
    expect(data['timeframe'], RewardTimeframe.thisWeek.name);
    // Provenance untouched by the targeted write.
    expect(data['createdBy'], 'parent1');
    expect((data['createdAt'] as Timestamp).toDate(), DateTime(2026, 7, 1));
  });
}
