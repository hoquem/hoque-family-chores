import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

/// uid that [MockAuthRepository.signInWithGoogle] reports.
const _googleUid = 'mock_google_uid';

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

  // authNotifierProvider is auto-dispose. Without a live listener it is torn
  // down between reads and rebuilt, so the state asserted below would come
  // from build() re-reading the mock rather than from the call under test.
  final subscription = container.listen(authNotifierProvider, (_, __) {});
  addTearDown(subscription.close);

  return container;
}

void main() {
  test('a first-time OAuth adult becomes a parent and is authenticated',
      () async {
    final users = MockUserRepository();
    final container = _makeContainer(auth: MockAuthRepository(), users: users);

    await container.read(authNotifierProvider.notifier).signInWithGoogle();

    final state = container.read(authNotifierProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.errorMessage, isNull);

    final profile = await users.getUserProfile(UserId(_googleUid));
    expect(profile, isNotNull, reason: 'a profile doc must be created');
    expect(profile!.role, UserRole.parent);
    expect(profile.email.value, 'oauth@example.com');
    expect(profile.familyId.isEmpty, isTrue);
  });

  test('an OAuth provider with no email fails loudly and creates no profile',
      () async {
    final users = MockUserRepository();
    final container = _makeContainer(
      auth: MockAuthRepository(oauthEmail: null),
      users: users,
    );

    await container.read(authNotifierProvider.notifier).signInWithGoogle();

    final state = container.read(authNotifierProvider);
    expect(state.status, AuthStatus.error);
    expect(state.errorMessage, contains('email'));
    expect(await users.getUserProfile(UserId(_googleUid)), isNull);
  });

  test('an existing profile keeps its role and is not recreated', () async {
    final users = MockUserRepository();
    await users.createUserProfile(
      User(
        id: UserId(_googleUid),
        name: 'Returning Kid',
        email: Email('oauth@example.com'),
        familyId: FamilyId('family_1'),
        role: UserRole.child,
        points: Points(10),
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    final container = _makeContainer(auth: MockAuthRepository(), users: users);

    await container.read(authNotifierProvider.notifier).signInWithGoogle();

    final state = container.read(authNotifierProvider);
    expect(state.status, AuthStatus.authenticated);

    final profile = await users.getUserProfile(UserId(_googleUid));
    expect(profile!.role, UserRole.child,
        reason: 'an existing user must not be promoted to parent');
  });

  test('cancelling the provider sheet is not an error', () async {
    final container = _makeContainer(
      auth: MockAuthRepository(oauthCancels: true),
      users: MockUserRepository(),
    );

    await container.read(authNotifierProvider.notifier).signInWithApple();

    final state = container.read(authNotifierProvider);
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.errorMessage, isNull);
    expect(state.isLoading, isFalse);
  });
}
