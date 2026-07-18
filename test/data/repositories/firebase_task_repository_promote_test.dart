// Promoting an approved after-photo to the family's Home background: the file is
// kept and pointed at, the task lets go of it, and the retired photos are deleted.
import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/repositories/firebase_task_repository.dart';
import 'package:hoque_family_chores/data/services/photo_storage_service.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockPhotoStorage extends Mock implements PhotoStorageService {}

final _familyId = FamilyId('fam1');
final _taskId = TaskId('task1');
const _after = 'https://x/after.jpg';
const _before = 'https://x/before.jpg';
const _oldBackground = 'https://x/old-bg.jpg';

void main() {
  setUpAll(() => registerFallbackValue(''));

  test('sets family background, clears task photos, deletes the retired ones',
      () async {
    final db = FakeFirebaseFirestore();
    await db.collection('families').doc(_familyId.value).set({
      'name': 'Hoque',
      'backgroundPhotoUrl': _oldBackground,
    });
    await db
        .collection('families')
        .doc(_familyId.value)
        .collection('tasks')
        .doc(_taskId.value)
        .set({
      'title': 'Mop',
      'status': TaskStatus.pendingApproval.name,
      'points': 10,
      'beforePhotoUrl': _before,
      'photoUrl': _after,
    });

    final photos = _MockPhotoStorage();
    final deleted = <String>[];
    when(() => photos.delete(any())).thenAnswer((i) async {
      deleted.add(i.positionalArguments.first as String);
      return const Right(null);
    });

    final repo = FirebaseTaskRepository(firestore: db, photoStorage: photos);
    await repo.promoteAfterPhotoToBackground(_familyId, _taskId);

    final family =
        (await db.collection('families').doc(_familyId.value).get()).data()!;
    expect(family['backgroundPhotoUrl'], _after,
        reason: 'the family now shows the just-cleaned room');

    final task = (await db
            .collection('families')
            .doc(_familyId.value)
            .collection('tasks')
            .doc(_taskId.value)
            .get())
        .data()!;
    expect(task['photoUrl'], isNull, reason: 'the task released the after-photo');
    expect(task['beforePhotoUrl'], isNull);

    // The kept after-photo is NOT deleted; the before-photo and old background are.
    expect(deleted, containsAll([_before, _oldBackground]));
    expect(deleted, isNot(contains(_after)));
  });

  test('with no after-photo it falls back to clearing', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('families').doc(_familyId.value).set({'name': 'Hoque'});
    await db
        .collection('families')
        .doc(_familyId.value)
        .collection('tasks')
        .doc(_taskId.value)
        .set({
      'title': 'Tidy',
      'status': TaskStatus.pendingApproval.name,
      'points': 5,
      'beforePhotoUrl': _before,
      'photoUrl': null,
    });
    final photos = _MockPhotoStorage();
    when(() => photos.delete(any())).thenAnswer((_) async => const Right(null));

    final repo = FirebaseTaskRepository(firestore: db, photoStorage: photos);
    await repo.promoteAfterPhotoToBackground(_familyId, _taskId);

    final family =
        (await db.collection('families').doc(_familyId.value).get()).data()!;
    expect(family.containsKey('backgroundPhotoUrl'), isFalse,
        reason: 'no after-photo means no background to set');
  });
}
