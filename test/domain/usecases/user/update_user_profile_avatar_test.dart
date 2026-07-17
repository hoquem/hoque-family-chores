// TASK-455: the profile update persists the chosen emoji, and clears it.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/usecases/user/update_user_profile_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

import '../../../mocks/mock_user_repository.dart';

final _me = UserId('me');

User _seed({String? emoji}) => User(
      id: _me,
      name: 'Ada',
      avatarEmoji: emoji,
      familyId: FamilyId('fam1'),
      role: UserRole.parent,
      points: Points(0),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  test('setting an emoji persists it', () async {
    final users = MockUserRepository();
    await users.createUserProfile(_seed());

    final result =
        await UpdateUserProfileUseCase(users)(userId: _me, avatarEmoji: '🦊');

    expect(result.isRight(), isTrue);
    expect((await users.getUserProfile(_me))!.avatarEmoji, '🦊');
  });

  test('passing an empty string clears it back to the initial', () async {
    final users = MockUserRepository();
    await users.createUserProfile(_seed(emoji: '🦊'));

    await UpdateUserProfileUseCase(users)(userId: _me, avatarEmoji: '');

    expect((await users.getUserProfile(_me))!.avatarEmoji, '');
  });
}
