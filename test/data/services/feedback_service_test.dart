// Feedback submission writes a well-formed record.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/services/feedback_service.dart';

void main() {
  test('submit records message, type, uid, family, version', () async {
    final db = FakeFirebaseFirestore();
    final service = FeedbackService(db);

    await service.submit(
      message: '  Please add a dark mode  ',
      type: FeedbackType.featureRequest,
      userId: 'uid-1',
      familyId: 'fam-1',
      appVersion: '1.0.0+35',
    );

    final docs = await db.collection('feedback').get();
    expect(docs.docs, hasLength(1));
    final d = docs.docs.single.data();
    expect(d['message'], 'Please add a dark mode', reason: 'trimmed');
    expect(d['type'], 'featureRequest');
    expect(d['userId'], 'uid-1');
    expect(d['familyId'], 'fam-1');
    expect(d['appVersion'], '1.0.0+35');
    expect(d.containsKey('createdAt'), isTrue);
  });
}
