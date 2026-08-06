// Notifications live at users/{userId}/notifications/{id}, so every write
// needs the owner's id to address the document.
//
// These exist because the repository had none (0/125 covered) and a real bug
// hid there: markNotificationAsRead took only a notification id, so it scanned
// `collection('users')` looking for the owner. firestore.rules:23 permits
// reading a user document only if it is yours or a family member's, so that
// unconstrained list is rejected outright — tapping a notification failed
// silently and the unread badge never cleared.
//
// The permission half cannot be reproduced here (FakeFirebaseFirestore does not
// evaluate rules), so `test/rules/notification_read.test.mjs` pins that. What
// these pin is the half a fake CAN prove: the write lands on the right
// document, and never on someone else's.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/repositories/firebase_notification_repository.dart';
import 'package:hoque_family_chores/domain/repositories/notification_repository.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

final _me = UserId('kid1');
final _sibling = UserId('kid2');

/// Seeds one notification under [owner]. The id is deliberately reusable across
/// users — Firestore ids are only unique within their own subcollection.
Future<void> _seed(
  FakeFirebaseFirestore db,
  UserId owner,
  String id, {
  bool isRead = false,
}) =>
    db
        .collection('users')
        .doc(owner.value)
        .collection('notifications')
        .doc(id)
        .set({
      'userId': owner.value,
      'title': 'Mum is on it!',
      'message': "Mum claimed 'Clean the middle bathroom'",
      'isRead': isRead,
      'createdAt': DateTime(2026, 8, 2),
    });

Future<Map<String, dynamic>?> _read(
        FakeFirebaseFirestore db, UserId owner, String id) async =>
    (await db
            .collection('users')
            .doc(owner.value)
            .collection('notifications')
            .doc(id)
            .get())
        .data();

void main() {
  late FakeFirebaseFirestore db;
  late NotificationRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirebaseNotificationRepository(firestore: db);
  });

  group('marking a notification read', () {
    test('sets isRead on the owner\'s document', () async {
      await _seed(db, _me, 'n1');

      await repo.markNotificationAsRead(_me, 'n1');

      expect((await _read(db, _me, 'n1'))!['isRead'], isTrue);
    });

    // The bug this file exists for. Ids are unique per subcollection, not
    // globally, so a scan that stops at the first user holding a matching id
    // can mark the wrong person's notification read. Passing the owner makes
    // that unrepresentable.
    test('leaves another user\'s identically-numbered notification alone',
        () async {
      await _seed(db, _sibling, 'shared-id');
      await _seed(db, _me, 'shared-id');

      await repo.markNotificationAsRead(_me, 'shared-id');

      expect((await _read(db, _me, 'shared-id'))!['isRead'], isTrue);
      expect((await _read(db, _sibling, 'shared-id'))!['isRead'], isFalse,
          reason: 'a sibling\'s notification must not be touched');
    });
  });

  group('marking a notification unread', () {
    test('clears isRead on the owner\'s document', () async {
      await _seed(db, _me, 'n1', isRead: true);

      await repo.markNotificationAsUnread(_me, 'n1');

      expect((await _read(db, _me, 'n1'))!['isRead'], isFalse);
    });
  });

  group('deleting a notification', () {
    test('removes the owner\'s document', () async {
      await _seed(db, _me, 'n1');

      await repo.deleteNotification(_me, 'n1');

      expect(await _read(db, _me, 'n1'), isNull);
    });

    test('leaves another user\'s identically-numbered notification alone',
        () async {
      await _seed(db, _sibling, 'shared-id');
      await _seed(db, _me, 'shared-id');

      await repo.deleteNotification(_me, 'shared-id');

      expect(await _read(db, _me, 'shared-id'), isNull);
      expect(await _read(db, _sibling, 'shared-id'), isNotNull);
    });

    // Deliberate change from the scanning implementation, which threw
    // NotFoundException. Deleting something already gone has achieved what the
    // caller wanted, and the caller cannot usefully react — a swipe-to-dismiss
    // that raced with another device would have thrown for no reason.
    test('is a no-op, not an error, when it has already gone', () async {
      await expectLater(repo.deleteNotification(_me, 'never-existed'),
          completes);
    });
  });

  group('streaming', () {
    test('returns only the requested user\'s notifications', () async {
      await _seed(db, _me, 'mine');
      await _seed(db, _sibling, 'theirs');

      final list = await repo.streamNotifications(_me).first;

      expect(list.map((n) => n.id), ['mine']);
    });
  });
}
