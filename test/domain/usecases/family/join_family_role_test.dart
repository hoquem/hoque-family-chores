// TASK-454: an adult joins an existing family and gets the role they picked.
//
// JoinFamilyUseCase is already role-parameterised and auth-agnostic — this locks
// that both picker values (parent AND guardian) actually land, so the onboarding
// gate's join card has proven backend behind it.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/usecases/family/join_family_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

import '../../../mocks/mock_family_repository.dart';
import '../../../mocks/mock_user_repository.dart';

FamilyEntity _family() => FamilyEntity(
      id: FamilyId('fam_1'),
      name: 'Hoque Family',
      description: '',
      creatorId: UserId('parent_uid'),
      memberIds: [UserId('parent_uid')],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      inviteCode: 'ABC234',
    );

/// An OAuth adult right after sign-in: real profile, no family yet.
User _adult(UserId id) => User(
      id: id,
      name: 'Ada',
      familyId: FamilyId.empty,
      role: UserRole.parent, // provisional; the join overwrites it
      points: Points(0),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  // The onboarding picker produces parent (the "parent or guardian" choice) and
  // child; guardian stays a valid backend role, so all three are covered.
  for (final role in [UserRole.parent, UserRole.guardian, UserRole.child]) {
    test('a user joins by code as ${role.name}', () async {
      final users = MockUserRepository();
      final families = MockFamilyRepository();
      await families.createFamily(_family());
      final me = UserId('adult_uid');
      await users.createUserProfile(_adult(me));

      final result = await JoinFamilyUseCase(families, users)(
        inviteCode: 'abc234', // lower-case: the use case normalises it
        userId: me,
        role: role,
      );

      expect(result.isRight(), isTrue);
      final profile = await users.getUserProfile(me);
      expect(profile!.familyId.value, 'fam_1');
      expect(profile.role, role);
      final family = await families.getFamily(FamilyId('fam_1'));
      expect(family!.memberIds.map((id) => id.value), contains('adult_uid'));
    });
  }
}
