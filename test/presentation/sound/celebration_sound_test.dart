// Wiring test: CelebrationListener plays each celebration's own sound as it
// starts, one after another as the queue drains. A child viewer keeps the
// review-prompt path (parents only) out of the way.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/celebration_listener.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/sound/app_sound.dart';
import 'package:hoque_family_chores/presentation/sound/sound_service.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import 'fake_sound_player.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

final _child = User(
  id: UserId('child_1'),
  name: 'Child',
  familyId: FamilyId('family_1'),
  role: UserRole.child,
  points: Points(0),
  joinedAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  testWidgets('each celebration plays its own sound, in order',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final player = FakeSoundPlayer();
    final container = ProviderContainer(overrides: [
      authNotifierProvider
          .overrideWith(() => _FixedAuthNotifier(AuthState(user: _child))),
      soundPlayerProvider.overrideWithValue(player),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: appLightTheme,
        home: const Scaffold(
          body: CelebrationListener(child: SizedBox.expand()),
        ),
      ),
    ));
    final queue = container.read(celebrationQueueProvider.notifier);
    queue.celebrate(const StarsAwarded(10));
    queue.celebrate(const TreatRedeemed('Bike ride'));
    queue.celebrate(const StreakMilestone(7));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      // Past the overlay's 700ms envelope, so the next one starts.
      await tester.pump(const Duration(milliseconds: 800));
    }

    expect(player.played, [
      AppSound.starsAwarded.asset,
      AppSound.treatRedeemed.asset,
      AppSound.streakMilestone.asset,
    ]);
  });
}
