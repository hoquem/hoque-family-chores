import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/data/repositories/firebase_user_repository.dart';

void main() {
  test('a child profile without an email parses with email == null', () {
    final user = FirebaseUserRepository.mapFirestoreToUser({
      'name': 'Zayan',
      'email': null,
      'familyId': 'fam_1',
      'role': 'child',
      'points': 0,
      'joinedAt': '2026-07-13T00:00:00.000Z',
      'updatedAt': '2026-07-13T00:00:00.000Z',
    }, 'anon_uid');

    expect(user.email, isNull);
    expect(user.name, 'Zayan');
  });

  test('a present but invalid email is still malformed data', () {
    expect(
      () => FirebaseUserRepository.mapFirestoreToUser({
        'name': 'Broken',
        'email': 'not-an-email',
        'familyId': '',
        'role': 'parent',
        'points': 0,
      }, 'uid_x'),
      throwsA(isA<ServerException>()
          .having((e) => e.code, 'code', 'USER_DATA_MALFORMED')),
    );
  });
}
