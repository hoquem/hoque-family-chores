// What is worth testing here, and what is not.
//
// `upload` cannot be unit-tested end to end: FlutterImageCompress runs over a
// platform channel that does not exist under `flutter test`. Rather than fake
// the whole pipeline and prove nothing, this pins the two pieces that can fail
// silently:
//
//  - the storage path, which is the contract with `storage.rules`. If the two
//    drift, every upload is denied at runtime while this suite stays green.
//  - delete's error path, because a swallowed failure leaves a stranger's
//    before-photo attached to the next child's task.
//
// The compress -> put -> URL round trip is verified on device (Task 13),
// against the deployed rules. That is the only place it can be verified.
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/services/photo_storage_service.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements FirebaseStorage {}

class _MockRef extends Mock implements Reference {}

void main() {
  group('pathFor — the contract with storage.rules', () {
    String path(PhotoKind kind) => PhotoStorageService.pathFor(
          familyId: FamilyId('fam1'),
          taskId: TaskId('task1'),
          kind: kind,
          timestamp: 1752700000000,
        );

    test('is family-scoped, so a rule can restrict a family to its own photos',
        () {
      // The old convention was quest_photos/{taskId}/ — no familyId, so no
      // rule could scope it. Nothing ever wrote there; nothing to migrate.
      expect(path(PhotoKind.before), startsWith('families/fam1/'));
      expect(path(PhotoKind.before), contains('/tasks/task1/'));
    });

    test('before and after do not collide under the same task', () {
      expect(path(PhotoKind.before), isNot(equals(path(PhotoKind.after))));
      expect(path(PhotoKind.before), endsWith('before-1752700000000.jpg'));
      expect(path(PhotoKind.after), endsWith('after-1752700000000.jpg'));
    });

    test('the full shape is exactly what storage.rules matches on', () {
      expect(
        path(PhotoKind.before),
        'families/fam1/tasks/task1/before-1752700000000.jpg',
      );
    });
  });

  group('delete', () {
    late _MockStorage storage;
    late _MockRef ref;
    late PhotoStorageService service;

    setUp(() {
      storage = _MockStorage();
      ref = _MockRef();
      service = PhotoStorageService(storage: storage);
      when(() => storage.refFromURL(any())).thenReturn(ref);
    });

    test('resolves the blob from its download URL and removes it', () async {
      when(() => ref.delete()).thenAnswer((_) async {});

      final result = await service.delete('https://example.com/x.jpg');

      expect(result.isRight(), isTrue);
      verify(() => storage.refFromURL('https://example.com/x.jpg')).called(1);
      verify(() => ref.delete()).called(1);
    });

    test('surfaces a storage error as a Failure rather than swallowing it',
        () async {
      when(() => ref.delete()).thenThrow(Exception('permission denied'));

      final result = await service.delete('https://example.com/x.jpg');

      expect(result.isLeft(), isTrue,
          reason: 'a failed delete must not look like success — the next child '
              'would inherit the previous one\'s before photo');
    });
  });
}
