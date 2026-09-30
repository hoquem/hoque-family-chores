// FamilyOnboardingNotifier drives both halves of onboarding: creating a
// family and joining one. Creating one is also where the post-create
// "Invite your family" step (see FamilyGate) gets armed, and joining one is
// where the memberJoined growth event is logged, on the joiner's side.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_onboarding_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/just_created_family_notifier.dart';

import '../../mocks/mock_family_repository.dart';
import '../../mocks/mock_user_repository.dart';

User _adultWithNoFamily(String uid) => User(
      id: UserId(uid),
      name: 'Ada',
      email: Email('ada@example.com'),
      familyId: FamilyId.empty,
      role: UserRole.parent,
      points: Points(0),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  late MockFamilyRepository families;
  late MockUserRepository users;
  late FakeFirebaseFirestore firestore;
  late ProviderContainer container;

  setUp(() {
    families = MockFamilyRepository();
    users = MockUserRepository();
    firestore = FakeFirebaseFirestore();
    container = ProviderContainer(
      overrides: [
        familyRepositoryProvider.overrideWith((_) => families),
        userRepositoryProvider.overrideWith((_) => users),
        analyticsProvider.overrideWith((_) => Analytics(firestore)),
      ],
    );
    addTearDown(container.dispose);
  });

  test('creating a family arms the invite step with the new family',
      () async {
    await users.createUserProfile(_adultWithNoFamily('creator_uid'));

    final success = await container
        .read(familyOnboardingNotifierProvider.notifier)
        .createFamily(name: 'The Hoques', creatorId: UserId('creator_uid'));

    expect(success, isTrue);
    final justCreated = container.read(justCreatedFamilyProvider);
    expect(justCreated, isNotNull);
    expect(justCreated!.name, 'The Hoques');
  });

  test('joining a family logs memberJoined and never arms the invite step',
      () async {
    await users.createUserProfile(_adultWithNoFamily('joiner_uid'));
    final family = FamilyEntity(
      id: FamilyId('fam_join'),
      name: 'The Owners',
      description: '',
      creatorId: UserId('owner_uid'),
      memberIds: [UserId('owner_uid')],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      inviteCode: 'ABCDEFGHJKMN',
    );
    families.addTestFamily(family);

    final success = await container
        .read(familyOnboardingNotifierProvider.notifier)
        .joinFamily(
          inviteCode: family.inviteCode,
          userId: UserId('joiner_uid'),
          role: UserRole.parent,
        );

    expect(success, isTrue);
    expect(container.read(justCreatedFamilyProvider), isNull);

    final events =
        await firestore.collection('analyticsEvents').get();
    expect(events.docs.map((d) => d['name']), contains('memberJoined'));
  });
}
