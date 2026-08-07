import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/main.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';

/// Auth notifier that returns a seeded state and counts how often it is built,
/// so a test can prove the gate rebuilt it rather than just redrawing.
class _SeededAuthNotifier extends AuthNotifier {
  _SeededAuthNotifier(this._state, this._builds);

  final AuthState _state;
  final List<AuthState> _builds;

  @override
  AuthState build() {
    _builds.add(_state);
    return _state;
  }
}

Widget _gate(AuthState state, List<AuthState> builds) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => _SeededAuthNotifier(state, builds)),
    ],
    child: const MaterialApp(home: FamilyGate()),
  );
}

void main() {
  group('FamilyGate', () {
    testWidgets('surfaces a profile stream failure instead of the generic '
        'connection message', (tester) async {
      final builds = <AuthState>[];
      await tester.pumpWidget(_gate(
        const AuthState(
          status: AuthStatus.error,
          errorMessage: 'PERMISSION_DENIED: Missing or insufficient permissions',
        ),
        builds,
      ));
      await tester.pump();

      expect(
        find.textContaining('Missing or insufficient permissions'),
        findsOneWidget,
      );
      expect(find.textContaining('Still setting things up'), findsNothing);
    });

    testWidgets('shows a real error without waiting out the splash timeout',
        (tester) async {
      final builds = <AuthState>[];
      await tester.pumpWidget(_gate(
        const AuthState(status: AuthStatus.error, errorMessage: 'boom'),
        builds,
      ));
      await tester.pump();

      // No 10-second wait: the failure is already known.
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('still offers sign out as the escape hatch on error',
        (tester) async {
      final builds = <AuthState>[];
      await tester.pumpWidget(_gate(
        const AuthState(status: AuthStatus.error, errorMessage: 'boom'),
        builds,
      ));
      await tester.pump();

      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('Retry rebuilds the auth notifier rather than only re-arming '
        'the timer', (tester) async {
      final builds = <AuthState>[];
      await tester.pumpWidget(_gate(const AuthState(), builds));
      await tester.pump();

      expect(builds, hasLength(1));
      expect(find.textContaining('Connecting'), findsOneWidget);

      // The splash only offers Retry after it gives up waiting.
      await tester.pump(const Duration(seconds: 11));
      expect(find.textContaining('Still setting things up'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(builds, hasLength(2),
          reason: 'Retry must re-run AuthNotifier.build so the profile stream '
              'is re-subscribed');
      expect(find.textContaining('Connecting'), findsOneWidget);
    });
  });
}
