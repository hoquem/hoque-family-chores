import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hoque_family_chores/presentation/sound/app_sound.dart';
import 'package:hoque_family_chores/presentation/sound/sound_player.dart';
import 'package:hoque_family_chores/utils/logger.dart';

/// Plays an [AppSound] if the device's toggle allows it.
///
/// A playback failure is logged and swallowed: a missing sound must never
/// block completing a chore or a celebration (sound spec §2).
class SoundService {
  SoundService({
    required SoundPlayer player,
    required bool Function() isEnabled,
  })  : _player = player,
        _isEnabled = isEnabled;

  final SoundPlayer _player;
  final bool Function() _isEnabled;

  Future<void> play(AppSound sound) async {
    if (!_isEnabled()) return;
    try {
      await _player.play(sound.asset);
    } catch (e, st) {
      AppLogger()
          .e('[Sound] could not play ${sound.name}', error: e, stackTrace: st);
    }
  }
}

/// The per-device "Sound effects" toggle. On by default; corrects to the
/// stored value once SharedPreferences has loaded.
///
/// Hand-written rather than `@riverpod`: build_runner is broken on this
/// toolchain.
class SoundEnabled extends Notifier<bool> {
  static const _key = 'sound_effects_enabled';
  static const _onByDefault = true;

  @override
  bool build() {
    _load();
    return _onByDefault;
  }

  Future<void> _load() async {
    // Fire-and-forget from build(): log a prefs failure rather than throw an
    // unhandled async error; sound simply stays on.
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? _onByDefault;
    } catch (e) {
      AppLogger().w('[Sound] could not read the toggle: $e');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}

final soundEnabledProvider =
    NotifierProvider<SoundEnabled, bool>(SoundEnabled.new);

final soundPlayerProvider =
    Provider<SoundPlayer>((ref) => AudioplayersSoundPlayer());

final soundServiceProvider = Provider<SoundService>(
  (ref) => SoundService(
    player: ref.watch(soundPlayerProvider),
    isEnabled: () => ref.read(soundEnabledProvider),
  ),
);
