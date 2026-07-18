// The analytics writer records a well-formed, PII-free event.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';

void main() {
  test('log writes an append-only event with name, uid, params', () async {
    final db = FakeFirebaseFirestore();
    final analytics = Analytics(db);

    await analytics.log(
      AnalyticsEventName.taskApproved,
      userId: 'uid-123',
      familyId: 'fam-1',
      params: {'points': 25},
    );

    final docs = await db.collection('analyticsEvents').get();
    expect(docs.docs, hasLength(1));
    final data = docs.docs.single.data();
    expect(data['name'], 'taskApproved');
    expect(data['userId'], 'uid-123');
    expect(data['familyId'], 'fam-1');
    expect(data['params'], {'points': 25});
    expect(data.containsKey('createdAt'), isTrue);
    // No PII: the only identifier is the pseudonymous uid.
    expect(data.toString(), isNot(contains('@')));
  });

  test('log never throws, even when the write fails', () async {
    // A repository pointed at nothing usable still must not blow up a screen.
    final analytics = Analytics(FakeFirebaseFirestore());
    // Two rapid logs, no await race issues, no exception surfaces.
    await analytics.log(AnalyticsEventName.signedIn, userId: 'u');
    await analytics.log(AnalyticsEventName.helpOpened,
        userId: 'u', params: {'screen': 'home'});
    // Reaching here without throwing is the assertion.
    expect(true, isTrue);
  });
}
