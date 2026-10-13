import 'package:hoque_family_chores/presentation/sound/sound_player.dart';

/// Records what would have been played; never touches a platform channel.
class FakeSoundPlayer implements SoundPlayer {
  final List<String> played = [];
  bool throwOnPlay = false;

  @override
  Future<void> play(String asset) async {
    if (throwOnPlay) throw StateError('no audio device');
    played.add(asset);
  }
}
