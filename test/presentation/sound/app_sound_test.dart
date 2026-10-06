import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/sound/app_sound.dart';

void main() {
  test('every sound has a bundled asset file', () {
    for (final sound in AppSound.values) {
      expect(File('assets/${sound.asset}').existsSync(), isTrue,
          reason: '${sound.name} -> assets/${sound.asset} is missing');
    }
  });

  test('each celebration kind maps to its own sound', () {
    expect(AppSound.forCelebration(const StarsAwarded(5)),
        AppSound.starsAwarded);
    expect(AppSound.forCelebration(const TreatRedeemed('Bike ride')),
        AppSound.treatRedeemed);
    expect(AppSound.forCelebration(const StreakMilestone(7)),
        AppSound.streakMilestone);
  });
}
