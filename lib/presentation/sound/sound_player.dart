import 'package:audioplayers/audioplayers.dart';

/// Plays one bundled clip. The seam that keeps tests off platform channels.
abstract interface class SoundPlayer {
  Future<void> play(String asset);
}

/// Production player: one low-latency `AudioPlayer`, created on first use so
/// nothing touches the platform until a sound is actually wanted.
class AudioplayersSoundPlayer implements SoundPlayer {
  /// Ambient: the iOS silent switch mutes it and it mixes with whatever the
  /// parent is already listening to (ambient mixes by default, so no
  /// `mixWithOthers` option, which the package rejects for this category).
  /// On Android no audio focus is requested, so other audio keeps playing.
  static final _ambient = AudioContext(
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  AudioPlayer? _player;

  @override
  Future<void> play(String asset) async {
    final player = _player ??= await _create();
    await player.play(AssetSource(asset));
  }

  Future<AudioPlayer> _create() async {
    final player = AudioPlayer();
    await player.setAudioContext(_ambient);
    await player.setPlayerMode(PlayerMode.lowLatency);
    return player;
  }
}
