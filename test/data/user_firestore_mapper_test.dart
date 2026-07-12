import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/data/repositories/firebase_user_repository.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';

void main() {
  test('parses a current-schema user document', () {
    final user = FirebaseUserRepository.mapFirestoreToUser({
      'name': 'Alice',
      'email': 'alice@example.com',
      'familyId': '',
      'role': 'parent',
      'points': 5,
      'joinedAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
    }, 'uid_1');

    expect(user.name, 'Alice');
    expect(user.email.value, 'alice@example.com');
    expect(user.role, UserRole.parent);
    expect(user.familyId.value, isEmpty);
  });

  test('malformed document throws a descriptive ServerException', () {
    // Legacy June-2025 schema: profile fields nested under `member`,
    // no top-level email. Must fail loudly, not with a cryptic
    // ArgumentError from Email validation.
    expect(
      () => FirebaseUserRepository.mapFirestoreToUser({
        'id': 'uid_legacy',
        'member': {'name': 'Old User', 'role': 'parent'},
        'points': 0,
      }, 'uid_legacy'),
      throwsA(isA<ServerException>()
          .having((e) => e.code, 'code', 'USER_DATA_MALFORMED')
          .having((e) => e.message, 'message', contains('uid_legacy'))),
    );
  });
}
