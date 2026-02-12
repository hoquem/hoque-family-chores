import 'package:audioplayers/audioplayers.dart';
import 'package:hoque_family_chores/utils/logger.dart';

/// Manages sound effects for the application.
/// 
/// Handles playback of celebration sounds with proper volume control
/// and mute functionality.
class SoundManager {
  final _logger = AppLogger();
  final AudioPlayer _player = AudioPlayer();
  bool _isMuted = false;

  /// Sets the muted state for all sound effects.
  void setMuted(bool muted) {
    _isMuted = muted;
    _logger.d('SoundManager: Muted set to $muted');
  }

  /// Gets the current muted state.
  bool get isMuted => _isMuted;

  /// Plays a sound effect.
  /// 
  /// If sounds are muted or the file cannot be loaded, fails gracefully.
  Future<void> play(SoundEffect effect) async {
    if (_isMuted) {
      _logger.d('SoundManager: Skipping ${effect.filename} (muted)');
      return;
    }

    try {
      _logger.d('SoundManager: Playing ${effect.filename} at ${effect.volume}');
      final source = AssetSource('sounds/${effect.filename}');
      
      // Stop any currently playing sound
      await _player.stop();
      
      // Play the new sound
      await _player.play(source, volume: effect.volume);
    } catch (e) {
      // Graceful degradation - log but don't throw
      _logger.w('SoundManager: Failed to play ${effect.filename}', error: e);
    }
  }

  /// Disposes of the audio player resources.
  void dispose() {
    _player.dispose();
    _logger.d('SoundManager: Disposed');
  }
}

/// Enum representing available sound effects.
enum SoundEffect {
  questComplete('quest_complete.mp3', 0.7),
  approvalCelebrate('approval_celebrate.mp3', 0.8),
  levelUp('level_up.mp3', 0.85),
  streakMilestone('streak_milestone.mp3', 0.75);

  final String filename;
  final double volume;
  
  const SoundEffect(this.filename, this.volume);
}
