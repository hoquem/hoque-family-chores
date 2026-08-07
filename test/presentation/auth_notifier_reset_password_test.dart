import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';

import '../mocks/mock_auth_repository.dart';

ProviderContainer _make() {
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
    analyticsProvider.overrideWith((_) => Analytics(FakeFirebaseFirestore())),
  ]);
  addTearDown(container.dispose);
  return container;
}

/// Anything a user should never be shown. These are the words that leak when a
/// thrown ArgumentError is stringified straight into the UI.
void _expectNoInternals(String? message) {
  expect(message, isNotNull);
  expect(message, isNot(contains('Invalid argument')));
  expect(message, isNot(contains('Exception')));
  expect(message, isNot(contains('ArgumentError')));
}

void main() {
  // Tapping "Forgot Password?" with an empty field put
  // "An unexpected error occurred: Invalid argument(s): Invalid email format:"
  // on the login screen — Email's ArgumentError stringified into the UI. The
  // login screen is the first thing App Review touches.
  group('resetPassword', () {
    test('an empty address asks for one instead of throwing', () async {
      final container = _make();
      final sub = container.listen(authNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(authNotifierProvider.notifier).resetPassword('');

      final state = container.read(authNotifierProvider);
      _expectNoInternals(state.errorMessage);
      expect(state.errorMessage!.toLowerCase(), contains('email'));
      expect(state.isLoading, isFalse);
    });

    test('a malformed address is reported in plain words', () async {
      final container = _make();
      final sub = container.listen(authNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      await container
          .read(authNotifierProvider.notifier)
          .resetPassword('not-an-email');

      final state = container.read(authNotifierProvider);
      _expectNoInternals(state.errorMessage);
      expect(state.errorMessage!.toLowerCase(), contains('email'));
    });

    test('a valid address still sends and clears the error', () async {
      final container = _make();
      final sub = container.listen(authNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      await container
          .read(authNotifierProvider.notifier)
          .resetPassword('parent@example.com');

      final state = container.read(authNotifierProvider);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, isFalse);
    });
  });

  // Sign-in guarded the empty case but never the format, so a typo took the
  // same route to the same leaked ArgumentError.
  group('signIn', () {
    test('a malformed address is reported in plain words', () async {
      final container = _make();
      final sub = container.listen(authNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(authNotifierProvider.notifier).signIn(
            email: 'not-an-email',
            password: 'hunter2222',
          );

      final state = container.read(authNotifierProvider);
      _expectNoInternals(state.errorMessage);
      expect(state.errorMessage!.toLowerCase(), contains('email'));
    });
  });
}
