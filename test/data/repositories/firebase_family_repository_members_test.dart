// A child in the family must not break the members list.
//
// Children join anonymously with no email. The mapper used to force every
// member's email through Email(''), which throws 'Invalid email format' — so
// the moment a family had one child, getFamilyMembers threw and the whole
// Family tab (and the add-task member picker, same query) showed an error
// instead of the members. This is the regression guard.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/repositories/firebase_family_repository.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';

final _familyId = FamilyId('fam1');

Future<FirebaseFamilyRepository> _seed(FakeFirebaseFirestore db) async {
  // A parent with an email…
  await db.collection('users').doc('parent1').set({
    'name': 'Mum',
    'email': 'mum@example.com',
    'familyId': _familyId.value,
    'role': 'parent',
    'points': 0,
  });
  // …and a child who joined with no email at all (the field is simply absent).
  await db.collection('users').doc('kid1').set({
    'name': 'Yamin',
    'familyId': _familyId.value,
    'role': 'child',
    'points': 40,
  });
  return FirebaseFamilyRepository(firestore: db);
}

void main() {
  test('a child with no email loads instead of crashing the list', () async {
    final repo = await _seed(FakeFirebaseFirestore());

    final members = await repo.getFamilyMembers(_familyId);

    expect(members.length, 2, reason: 'both members come back');
    final kid = members.firstWhere((m) => m.name == 'Yamin');
    final mum = members.firstWhere((m) => m.name == 'Mum');
    expect(kid.email, isNull, reason: 'a child legitimately has no email');
    expect(mum.email?.value, 'mum@example.com');
  });

  test('an empty-string email is treated as no email, not a format error',
      () async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('kid2').set({
      'name': 'Sam',
      'email': '', // some child docs carry an empty string rather than a null
      'familyId': _familyId.value,
      'role': 'child',
      'points': 0,
    });
    final repo = FirebaseFamilyRepository(firestore: db);

    final members = await repo.getFamilyMembers(_familyId);

    expect(members.single.email, isNull);
  });
}
