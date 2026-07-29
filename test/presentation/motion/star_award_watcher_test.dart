import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/star_award_watcher.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';

/// A fake auth notifier whose state we can mutate directly.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initial);
  final AuthState _initial;

  @override
  AuthState build() => _initial;

  void setUser(User? user) {
    state = state.copyWith(user: user);
  }
}

User _user(int points) => User(
      id: UserId('u1'),
      name: 'Test',
      familyId: FamilyId('f1'),
      role: UserRole.child,
      points: Points(points),
      joinedAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 20),
    );

void main() {
  test('first emission is baseline — no celebration', () {
    final fake = _FakeAuthNotifier(AuthState(user: _user(50)));
    final container = ProviderContainer(overrides: [
      authNotifierProvider.overrideWith(() => fake),
    ]);
    addTearDown(container.dispose);

    container.read(starAwardWatcherProvider);
    expect(container.read(celebrationQueueProvider), isEmpty);
  });

  test('points increase celebrates the delta', () {
    final fake = _FakeAuthNotifier(AuthState(user: _user(50)));
    final container = ProviderContainer(overrides: [
      authNotifierProvider.overrideWith(() => fake),
    ]);
    addTearDown(container.dispose);

    container.read(starAwardWatcherProvider);
    fake.setUser(_user(60));

    final kinds = container.read(celebrationQueueProvider).map((q) => q.kind);
    expect(kinds, [const StarsAwarded(10)]);
  });

  test('points decrease does not celebrate', () {
    final fake = _FakeAuthNotifier(AuthState(user: _user(60)));
    final container = ProviderContainer(overrides: [
      authNotifierProvider.overrideWith(() => fake),
    ]);
    addTearDown(container.dispose);

    container.read(starAwardWatcherProvider);
    fake.setUser(_user(45));

    expect(container.read(celebrationQueueProvider), isEmpty);
  });

  test('user id change resets baseline', () {
    final fake = _FakeAuthNotifier(AuthState(user: _user(50)));
    final container = ProviderContainer(overrides: [
      authNotifierProvider.overrideWith(() => fake),
    ]);
    addTearDown(container.dispose);

    container.read(starAwardWatcherProvider);
    // First increase — celebrates.
    fake.setUser(_user(60));
    expect(container.read(celebrationQueueProvider).length, 1);

    // New user — baseline resets, no celebration.
    final newUser = User(
      id: UserId('u2'),
      name: 'Other',
      familyId: FamilyId('f1'),
      role: UserRole.child,
      points: Points(100),
      joinedAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 20),
    );
    fake.setUser(newUser);
    expect(container.read(celebrationQueueProvider).length, 1);

    // Increase for new user — celebrates.
    fake.setUser(newUser.copyWith(points: Points(110)));
    expect(container.read(celebrationQueueProvider).length, 2);
  });

  test('same state emitted twice does not duplicate', () {
    final user = _user(50);
    final fake = _FakeAuthNotifier(AuthState(user: user));
    final container = ProviderContainer(overrides: [
      authNotifierProvider.overrideWith(() => fake),
    ]);
    addTearDown(container.dispose);

    container.read(starAwardWatcherProvider);
    fake.setUser(_user(60));
    fake.setUser(_user(60));

    expect(container.read(celebrationQueueProvider).length, 1);
  });

  test('claim sequence: spend does not celebrate from watcher', () {
    // Simulates: points 60 → treat claimed → points 45 → 45 again.
    final fake = _FakeAuthNotifier(AuthState(user: _user(60)));
    final container = ProviderContainer(overrides: [
      authNotifierProvider.overrideWith(() => fake),
    ]);
    addTearDown(container.dispose);

    container.read(starAwardWatcherProvider);
    fake.setUser(_user(45));
    fake.setUser(_user(45));

    expect(container.read(celebrationQueueProvider), isEmpty);
  });
}
