import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoque_family_chores/presentation/sound/app_sound.dart';
import 'package:hoque_family_chores/presentation/sound/sound_service.dart';

import 'fake_sound_player.dart';

void main() {
  group('SoundService', () {
    test('plays the asset when enabled', () async {
      final player = FakeSoundPlayer();
      await SoundService(player: player, isEnabled: () => true)
          .play(AppSound.choreDone);
      expect(player.played, [AppSound.choreDone.asset]);
    });

    test('plays nothing when disabled', () async {
      final player = FakeSoundPlayer();
      await SoundService(player: player, isEnabled: () => false)
          .play(AppSound.starsAwarded);
      expect(player.played, isEmpty);
    });

    test('a failing player does not throw out of play', () async {
      final player = FakeSoundPlayer()..throwOnPlay = true;
      await expectLater(
        SoundService(player: player, isEnabled: () => true)
            .play(AppSound.treatRedeemed),
        completes,
      );
    });
  });

  group('soundEnabledProvider', () {
    test('defaults to on when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(soundEnabledProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(soundEnabledProvider), isTrue);
    });

    test('loads a stored off', () async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(soundEnabledProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(soundEnabledProvider), isFalse);
    });

    test('setEnabled(false) persists', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(soundEnabledProvider.notifier).setEnabled(false);
      expect(container.read(soundEnabledProvider), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sound_effects_enabled'), isFalse);
    });

    test('the service follows the toggle', () async {
      SharedPreferences.setMockInitialValues({});
      final player = FakeSoundPlayer();
      final container = ProviderContainer(
        overrides: [soundPlayerProvider.overrideWithValue(player)],
      );
      addTearDown(container.dispose);
      await container.read(soundEnabledProvider.notifier).setEnabled(false);
      await container.read(soundServiceProvider).play(AppSound.choreDone);
      expect(player.played, isEmpty);
    });
  });
}
