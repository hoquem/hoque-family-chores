// TASK-454: the onboarding gate routes a signed-in adult by their family state.
//
// The two branches tested here are the new logic:
//  - user == null (profile still streaming) → splash, NOT onboarding. This is
//    the race guard: a restored session reports `authenticated` before the
//    profile arrives, and flashing onboarding at a user who has a family would
//    be wrong.
//  - familyId empty → the onboarding screen (create/join).
//
// The has-family → MainScreen branch is pre-existing behaviour (main.dart
// already routed a live session to MainScreen); MainScreen eagerly builds all
// five tabs against real repositories, so it isn't unit-pumpable without heavy
// fixtures and is covered by the existing app tests, not re-tested here.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/main.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

User _adult({required String familyId}) => User(
      id: UserId('adult_uid'),
      name: 'Ada',
      familyId: familyId.isEmpty ? FamilyId.empty : FamilyId(familyId),
      role: UserRole.parent,
      points: Points(0),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Future<void> _pump(WidgetTester tester, AuthState state) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => _FixedAuthNotifier(state)),
      ],
      child: MaterialApp(theme: appLightTheme, home: const FamilyGate()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('authenticated but profile not yet loaded → splash, not onboarding',
      (tester) async {
    await _pump(
      tester,
      const AuthState(user: null),
    );

    expect(find.text('Connecting...'), findsOneWidget);
    expect(find.text('Set up your family'), findsNothing);

    // Drain the splash's 10s connect-timeout timer so the test doesn't trip
    // Flutter's pending-timer assertion at teardown.
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('signed in with no family → onboarding screen', (tester) async {
    await _pump(
      tester,
      AuthState(user: _adult(familyId: '')),
    );

    expect(find.text('Set up your family'), findsOneWidget);
    expect(find.text('Connecting...'), findsNothing);
  });
}
