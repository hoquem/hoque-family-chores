import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

FamilyEntity _makeFamily({List<UserId>? memberIds}) {
  return FamilyEntity(
    id: FamilyId('f1'),
    name: 'Test Family',
    description: 'desc',
    creatorId: UserId('u1'),
    memberIds: memberIds ?? [UserId('u1'), UserId('u2')],
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('FamilyEntity', () {
    test('hasMember', () {
      final family = _makeFamily();
      expect(family.hasMember(UserId('u1')), true);
      expect(family.hasMember(UserId('u99')), false);
    });

    test('isCreatedBy', () {
      final family = _makeFamily();
      expect(family.isCreatedBy(UserId('u1')), true);
      expect(family.isCreatedBy(UserId('u2')), false);
    });

    test('memberCount', () {
      expect(_makeFamily().memberCount, 2);
    });

    test('hasMembers / isEmpty', () {
      expect(_makeFamily().hasMembers, true);
      expect(_makeFamily().isEmpty, false);
      expect(_makeFamily(memberIds: []).hasMembers, false);
      expect(_makeFamily(memberIds: []).isEmpty, true);
    });

    test('addMember adds new member', () {
      final family = _makeFamily();
      final updated = family.addMember(UserId('u3'));
      expect(updated.memberIds.length, 3);
      expect(updated.hasMember(UserId('u3')), true);
    });

    test('addMember ignores existing member', () {
      final family = _makeFamily();
      final updated = family.addMember(UserId('u1'));
      expect(updated.memberIds.length, 2);
      expect(identical(updated, family), true);
    });

    test('removeMember removes existing member', () {
      final family = _makeFamily();
      final updated = family.removeMember(UserId('u2'));
      expect(updated.memberIds.length, 1);
      expect(updated.hasMember(UserId('u2')), false);
    });

    test('removeMember ignores non-member', () {
      final family = _makeFamily();
      final updated = family.removeMember(UserId('u99'));
      expect(identical(updated, family), true);
    });

    test('copyWith', () {
      final family = _makeFamily();
      final copy = family.copyWith(name: 'New Name');
      expect(copy.name, 'New Name');
      expect(copy.id, family.id);
    });

    test('equality', () {
      expect(_makeFamily(), equals(_makeFamily()));
    });
  });
}
