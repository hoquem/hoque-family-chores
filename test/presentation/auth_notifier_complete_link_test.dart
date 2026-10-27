import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_managed_child_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'kid_uid';

User _profile({required bool managed, int points = 5}) => User(
      id: UserId(_uid),
      name: 'Amira',
      familyId: FamilyId('family_1'),
      role: UserRole.child,
      points: Points(points),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isManaged: managed,
    );

/// A container already signed in as [_uid], whose profile is [profile].
Future<(ProviderContainer, MockManagedChildRepository, MockUserRepository)>
    _signedInAs(User profile, {Object? completeLinkError}) async {
  final users = MockUserRepository();
  await users.createUserProfile(profile);
  final managed = MockManagedChildRepository()
    ..completeLinkError = completeLinkError;
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWith(
        (_) => MockAuthRepository(currentUser: FakeFirebaseUser(uid: _uid))),
    userRepositoryProvider.overrideWith((_) => users),
    managedChildRepositoryProvider.overrideWithValue(managed),
    analyticsProvider.overrideWith((_) => Analytics(FakeFirebaseFirestore())),
  ]);
  addTearDown(container.dispose);
  final sub = container.listen(authNotifierProvider, (_, __) {});
  addTearDown(sub.close);
  await _settle();
  return (container, managed, users);
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 300));

void main() {
  // Production fires no auth onCreate event for a first custom-token sign-in
  // (https://firebase.google.com/docs/functions/auth-events), so a linked
  // child stayed `managed: true` for good. The phone now heals it itself.
  test('a signed-in user whose own profile is managed completes the link once',
      () async {
    final (container, managed, users) =
        await _signedInAs(_profile(managed: true));

    expect(container.read(authNotifierProvider).user?.isManaged, isTrue);
    expect(managed.completeLinkCalls, 1);

    // Another update to the still-managed profile (stars changed) must not
    // call again.
    await users.updateUserProfile(_profile(managed: true, points: 9));
    await _settle();
    expect(container.read(authNotifierProvider).user?.points.value, 9);
    expect(managed.completeLinkCalls, 1);
  });

  test('a normal profile never calls completeLink', () async {
    final (_, managed, users) = await _signedInAs(_profile(managed: false));
    await users.updateUserProfile(_profile(managed: false, points: 9));
    await _settle();

    expect(managed.completeLinkCalls, 0);
  });

  test('a failed completeLink keeps the child signed in', () async {
    final (container, managed, _) = await _signedInAs(
      _profile(managed: true),
      completeLinkError: ServerException('offline', code: 'FUNCTION_ERROR'),
    );

    expect(managed.completeLinkCalls, 1);
    final state = container.read(authNotifierProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.name, 'Amira');
  });
}
