import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/repositories/firebase_user_repository.dart';

void main() {
  final base = {
    'name': 'Amira',
    'familyId': 'fam_1',
    'role': 'child',
    'points': 0,
  };

  test('a profile with managed: true maps to isManaged', () {
    final user =
        FirebaseUserRepository.mapFirestoreToUser({...base, 'managed': true}, 'kid');
    expect(user.isManaged, isTrue);
  });

  test('a profile without managed is not managed', () {
    final user = FirebaseUserRepository.mapFirestoreToUser(base, 'kid');
    expect(user.isManaged, isFalse);
  });

  test('isManaged takes part in equality', () {
    final a = FirebaseUserRepository.mapFirestoreToUser(base, 'kid');
    expect(a == a.copyWith(isManaged: true), isFalse);
  });
}
