import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoque_family_chores/utils/logger.dart';

/// Service for managing user preferences related to celebrations.
/// 
/// Persists settings for sound effects, haptics, and reduced motion.
class PreferencesService {
  final _logger = AppLogger();
  
  static const String _soundKey = 'audio_sound_enabled';
  static const String _hapticsKey = 'audio_haptics_enabled';
  static const String _reduceMotionKey = 'accessibility_reduce_motion';

  /// Gets whether sound effects are enabled (defaults to true).
  Future<bool> getSoundEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_soundKey) ?? true;
      _logger.d('PreferencesService: Sound enabled = $enabled');
      return enabled;
    } catch (e) {
      _logger.e('PreferencesService: Error getting sound preference', error: e);
      return true; // Default to enabled
    }
  }

  /// Sets whether sound effects are enabled.
  Future<void> setSoundEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundKey, enabled);
      _logger.d('PreferencesService: Sound enabled set to $enabled');
    } catch (e) {
      _logger.e('PreferencesService: Error setting sound preference', error: e);
    }
  }

  /// Gets whether haptic feedback is enabled (defaults to true).
  Future<bool> getHapticsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_hapticsKey) ?? true;
      _logger.d('PreferencesService: Haptics enabled = $enabled');
      return enabled;
    } catch (e) {
      _logger.e('PreferencesService: Error getting haptics preference', error: e);
      return true; // Default to enabled
    }
  }

  /// Sets whether haptic feedback is enabled.
  Future<void> setHapticsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticsKey, enabled);
      _logger.d('PreferencesService: Haptics enabled set to $enabled');
    } catch (e) {
      _logger.e('PreferencesService: Error setting haptics preference', error: e);
    }
  }

  /// Gets whether reduced motion is enabled (defaults to false).
  Future<bool> getReduceMotionEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_reduceMotionKey) ?? false;
      _logger.d('PreferencesService: Reduce motion enabled = $enabled');
      return enabled;
    } catch (e) {
      _logger.e('PreferencesService: Error getting reduce motion preference', error: e);
      return false; // Default to disabled
    }
  }

  /// Sets whether reduced motion is enabled.
  Future<void> setReduceMotionEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reduceMotionKey, enabled);
      _logger.d('PreferencesService: Reduce motion enabled set to $enabled');
    } catch (e) {
      _logger.e('PreferencesService: Error setting reduce motion preference', error: e);
    }
  }
}
