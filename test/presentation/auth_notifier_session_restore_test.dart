import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'restored_uid';

User _profile() => User(
      id: UserId(_uid),
      name: 'Amira',
      email: Email('amira@example.com'),
      familyId: FamilyId('fam_restore'),
      role: UserRole.child,
      points: Points(20),
      joinedAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 20),
    );

(ProviderContainer, MockAuthRepository, MockUserRepository) _make({
  FakeFirebaseUser? currentUser,
}) {
  final auth = MockAuthRepository(currentUser: currentUser);
  final users = MockUserRepository();
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWith((_) => auth),
    userRepositoryProvider.overrideWith((_) => users),
    analyticsProvider.overrideWith((_) => Analytics(FakeFirebaseFirestore())),
  ]);
  addTearDown(container.dispose);
  return (container, auth, users);
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 300));

void main() {
  // AuthNotifier used to read currentUser exactly once, in build(). Firebase
  // restores a persisted session asynchronously, so anything that built the
  // notifier before the restore landed — LoginScreen watches it — left
  // state.user null forever: FamilyGate then held the splash open with no way
  // out but signing out.
  test('a session restored after build populates the profile', () async {
    final (container, auth, users) = _make();
    await users.createUserProfile(_profile());
    final sub = container.listen(authNotifierProvider, (_, __) {});
    addTearDown(sub.close);

    expect(container.read(authNotifierProvider).user, isNull);

    auth.emitSession(FakeFirebaseUser(uid: _uid));
    await _settle();

    final state = container.read(authNotifierProvider);
    expect(state.user?.name, 'Amira');
    expect(state.status, AuthStatus.authenticated);
  });

  test('a session revoked elsewhere clears the profile', () async {
    final (container, auth, users) =
        _make(currentUser: FakeFirebaseUser(uid: _uid));
    await users.createUserProfile(_profile());
    final sub = container.listen(authNotifierProvider, (_, __) {});
    addTearDown(sub.close);
    await _settle();
    expect(container.read(authNotifierProvider).user?.name, 'Amira');

    // Firebase drops the session without the notifier's signOut() being called
    // — a revoked token, or a sign-out from another surface.
    auth.emitSession(null);
    await _settle();

    final state = container.read(authNotifierProvider);
    expect(state.user, isNull);
    expect(state.status, AuthStatus.unauthenticated);
  });

  test('a repeat emission for the session already streaming is ignored',
      () async {
    final (container, auth, users) =
        _make(currentUser: FakeFirebaseUser(uid: _uid));
    await users.createUserProfile(_profile());
    final sub = container.listen(authNotifierProvider, (_, __) {});
    addTearDown(sub.close);
    await _settle();

    // Firebase re-emits the same user on token refresh; that must not tear
    // down and rebuild the profile subscription.
    auth.emitSession(FakeFirebaseUser(uid: _uid));
    await _settle();

    final state = container.read(authNotifierProvider);
    expect(state.user?.name, 'Amira');
    expect(state.status, AuthStatus.authenticated);
  });

  test('an in-flight OAuth profile completion is not overwritten', () async {
    final (container, auth, _) = _make();
    final sub = container.listen(authNotifierProvider, (_, __) {});
    addTearDown(sub.close);

    // OAuth signed in but the profile could not be created: the flow parks on
    // needsProfileCompletion and deliberately does NOT stream a profile.
    final notifier = container.read(authNotifierProvider.notifier);
    notifier.state = const AuthState(
      status: AuthStatus.needsProfileCompletion,
      errorMessage: 'Could not finish setting up your account',
    );

    auth.emitSession(FakeFirebaseUser(uid: _uid));
    await _settle();

    final state = container.read(authNotifierProvider);
    expect(state.status, AuthStatus.needsProfileCompletion,
        reason: 'the auth listener must not hijack a sign-in flow that is '
            'still deciding what to do with the session');
    expect(state.errorMessage, 'Could not finish setting up your account');
  });
}
