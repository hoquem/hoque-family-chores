import 'package:hoque_family_chores/presentation/services/sound_manager.dart';
import 'package:hoque_family_chores/presentation/services/haptic_manager.dart';
import 'package:hoque_family_chores/presentation/services/preferences_service.dart';
import 'package:hoque_family_chores/utils/logger.dart';

/// Central service for triggering celebrations.
/// 
/// Orchestrates sound effects, haptic feedback, and confetti animations
/// for various achievement events.
class CelebrationService {
  final SoundManager _soundManager;
  final HapticManager _hapticManager;
  final PreferencesService _preferencesService;
  final _logger = AppLogger();

  CelebrationService({
    required SoundManager soundManager,
    required HapticManager hapticManager,
    required PreferencesService preferencesService,
  })  : _soundManager = soundManager,
        _hapticManager = hapticManager,
        _preferencesService = preferencesService;

  /// Initializes the service by loading preferences.
  Future<void> initialize() async {
    _logger.d('CelebrationService: Initializing');
    
    final soundEnabled = await _preferencesService.getSoundEnabled();
    final hapticsEnabled = await _preferencesService.getHapticsEnabled();
    
    _soundManager.setMuted(!soundEnabled);
    _hapticManager.setEnabled(hapticsEnabled);
    
    _logger.d('CelebrationService: Initialized (sound=$soundEnabled, haptics=$hapticsEnabled)');
  }

  /// Celebrates quest completion.
  /// 
  /// Plays a satisfying ding sound and medium haptic feedback.
  Future<void> celebrateQuestComplete() async {
    _logger.d('CelebrationService: Quest complete');
    
    await Future.wait([
      _soundManager.play(SoundEffect.questComplete),
      _hapticManager.trigger(HapticPattern.questComplete),
    ]);
  }

  /// Celebrates quest approval.
  /// 
  /// Plays a celebration chime and success haptic pattern.
  Future<void> celebrateQuestApproval() async {
    _logger.d('CelebrationService: Quest approval');
    
    await Future.wait([
      _soundManager.play(SoundEffect.approvalCelebrate),
      _hapticManager.trigger(HapticPattern.approvalCelebration),
    ]);
  }

  /// Celebrates level up.
  /// 
  /// Plays an epic fanfare and heavy haptic pattern.
  Future<void> celebrateLevelUp() async {
    _logger.d('CelebrationService: Level up');
    
    await Future.wait([
      _soundManager.play(SoundEffect.levelUp),
      _hapticManager.trigger(HapticPattern.levelUp),
    ]);
  }

  /// Celebrates streak milestone.
  /// 
  /// Plays an achievement sound and streak haptic pattern.
  Future<void> celebrateStreakMilestone() async {
    _logger.d('CelebrationService: Streak milestone');
    
    await Future.wait([
      _soundManager.play(SoundEffect.streakMilestone),
      _hapticManager.trigger(HapticPattern.streakMilestone),
    ]);
  }

  /// Triggers light haptic feedback (e.g., button taps).
  Future<void> lightHaptic() async {
    await _hapticManager.trigger(HapticPattern.light);
  }

  /// Triggers selection haptic feedback (e.g., chip selections).
  Future<void> selectionHaptic() async {
    await _hapticManager.trigger(HapticPattern.selection);
  }

  /// Updates sound enabled preference.
  Future<void> setSoundEnabled(bool enabled) async {
    await _preferencesService.setSoundEnabled(enabled);
    _soundManager.setMuted(!enabled);
    
    // Play preview sound if enabling
    if (enabled) {
      await _soundManager.play(SoundEffect.questComplete);
    }
  }

  /// Updates haptics enabled preference.
  Future<void> setHapticsEnabled(bool enabled) async {
    await _preferencesService.setHapticsEnabled(enabled);
    _hapticManager.setEnabled(enabled);
    
    // Play preview haptic if enabling
    if (enabled) {
      await _hapticManager.trigger(HapticPattern.light);
    }
  }

  /// Updates reduce motion preference.
  Future<void> setReduceMotionEnabled(bool enabled) async {
    await _preferencesService.setReduceMotionEnabled(enabled);
  }

  /// Gets current sound enabled state.
  Future<bool> getSoundEnabled() => _preferencesService.getSoundEnabled();

  /// Gets current haptics enabled state.
  Future<bool> getHapticsEnabled() => _preferencesService.getHapticsEnabled();

  /// Gets current reduce motion state.
  Future<bool> getReduceMotionEnabled() => _preferencesService.getReduceMotionEnabled();

  /// Disposes of resources.
  void dispose() {
    _soundManager.dispose();
    _logger.d('CelebrationService: Disposed');
  }
}
