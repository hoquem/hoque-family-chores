import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/services/managed_child_policy.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

User _user(String id, UserRole role, {String family = 'fam_1', bool managed = false}) => User(
      id: UserId(id),
      name: id,
      familyId: FamilyId(family),
      role: role,
      points: Points(0),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isManaged: managed,
    );

void main() {
  final kid = _user('kid', UserRole.child, managed: true);

  test('a parent may act for a managed child in their family', () {
    expect(canActForMember(viewer: _user('mum', UserRole.parent), member: kid), isTrue);
  });

  test('a guardian may too', () {
    expect(canActForMember(viewer: _user('gran', UserRole.guardian), member: kid), isTrue);
  });

  test('a child may not', () {
    expect(canActForMember(viewer: _user('teen', UserRole.child), member: kid), isFalse);
  });

  test("another family's parent may not", () {
    expect(
      canActForMember(viewer: _user('other', UserRole.parent, family: 'fam_2'), member: kid),
      isFalse,
    );
  });

  test('nobody acts for a member who signs in themselves', () {
    expect(
      canActForMember(viewer: _user('mum', UserRole.parent), member: _user('teen', UserRole.child)),
      isFalse,
    );
  });
}
