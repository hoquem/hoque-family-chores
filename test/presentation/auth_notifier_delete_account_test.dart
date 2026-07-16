import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';

ProviderContainer _makeContainer({
  required MockAuthRepository auth,
  required MockUserRepository users,
}) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => auth),
      userRepositoryProvider.overrideWith((_) => users),
    ],
  );
  addTearDown(container.dispose);

  // authNotifierProvider is auto-dispose: hold a listener or the notifier is
  // rebuilt between reads and assertions observe build(), not the calls below.
  final subscription = container.listen(authNotifierProvider, (_, __) {});
  addTearDown(subscription.close);

  return container;
}

/// Signs in via Google and pushes the created profile through the stream so
/// `state.user` is populated, as deleteAccount requires.
Future<void> _signInWithProfile(
  ProviderContainer container,
  MockUserRepository users,
) async {
  await container.read(authNotifierProvider.notifier).signInWithGoogle();
  final profile = await users.getUserProfile(UserId(_uid));
  await users.updateUserProfile(profile!);
  await Future<void>.delayed(const Duration(milliseconds: 50));
  expect(container.read(authNotifierProvider).user, isNotNull,
      reason: 'test setup: profile stream must have delivered the user');
}

void main() {
  test('deleteAccount removes profile + auth user and unauthenticates',
      () async {
    final users = MockUserRepository();
    final auth = MockAuthRepository();
    final container = _makeContainer(auth: auth, users: users);
    await _signInWithProfile(container, users);

    await container.read(authNotifierProvider.notifier).deleteAccount();

    final state = container.read(authNotifierProvider);
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.user, isNull);
    expect(state.errorMessage, isNull);
    expect(await users.getUserProfile(UserId(_uid)), isNull);
    expect(auth.deleteUserCalled, isTrue);
  });

  test('deleteAccount surfaces requires-recent-login and stays signed in',
      () async {
    final users = MockUserRepository();
    final auth = MockAuthRepository(
      deleteUserError: const AuthException(
        'needs recent login',
        code: 'REQUIRES_RECENT_LOGIN',
      ),
    );
    final container = _makeContainer(auth: auth, users: users);
    await _signInWithProfile(container, users);

    await container.read(authNotifierProvider.notifier).deleteAccount();

    final state = container.read(authNotifierProvider);
    expect(state.status, AuthStatus.authenticated,
        reason: 'the auth user still exists; the session must survive');
    expect(state.errorMessage, isNotNull);
    expect(await users.getUserProfile(UserId(_uid)), isNotNull,
        reason: 'profile doc must be restored');
  });
}
