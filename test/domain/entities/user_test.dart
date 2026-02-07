import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';

User _makeUser({UserRole role = UserRole.parent, Points? points}) {
  return User(
    id: UserId('u1'),
    name: 'Test',
    email: Email('test@example.com'),
    familyId: FamilyId('f1'),
    role: role,
    points: points ?? Points(100),
    joinedAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('User', () {
    test('role checks', () {
      expect(_makeUser(role: UserRole.parent).isParent, true);
      expect(_makeUser(role: UserRole.child).isChild, true);
      expect(_makeUser(role: UserRole.guardian).isGuardian, true);
    });

    test('hasPoints / hasNoPoints', () {
      expect(_makeUser(points: Points(10)).hasPoints, true);
      expect(_makeUser(points: Points(0)).hasNoPoints, true);
    });

    test('copyWith', () {
      final user = _makeUser();
      final copy = user.copyWith(name: 'New Name');
      expect(copy.name, 'New Name');
      expect(copy.id, user.id);
    });

    test('equality', () {
      expect(_makeUser(), equals(_makeUser()));
    });
  });

  group('UserRole', () {
    test('displayName', () {
      expect(UserRole.parent.displayName, 'Parent');
      expect(UserRole.child.displayName, 'Child');
      expect(UserRole.guardian.displayName, 'Guardian');
      expect(UserRole.other.displayName, 'Other');
    });

    test('isAdmin', () {
      expect(UserRole.parent.isAdmin, true);
      expect(UserRole.guardian.isAdmin, true);
      expect(UserRole.child.isAdmin, false);
      expect(UserRole.other.isAdmin, false);
    });
  });
}
