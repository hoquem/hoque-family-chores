import 'package:flutter/services.dart';
import 'package:hoque_family_chores/utils/logger.dart';

/// Manages haptic feedback for the application.
/// 
/// Provides different haptic patterns for various user interactions.
class HapticManager {
  final _logger = AppLogger();
  bool _isEnabled = true;

  /// Sets the enabled state for haptic feedback.
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    _logger.d('HapticManager: Enabled set to $enabled');
  }

  /// Gets the current enabled state.
  bool get isEnabled => _isEnabled;

  /// Triggers a haptic pattern.
  /// 
  /// If haptics are disabled, this does nothing.
  Future<void> trigger(HapticPattern pattern) async {
    if (!_isEnabled) {
      _logger.d('HapticManager: Skipping ${pattern.name} (disabled)');
      return;
    }

    try {
      _logger.d('HapticManager: Triggering ${pattern.name}');
      
      switch (pattern) {
        case HapticPattern.light:
          await HapticFeedback.lightImpact();
          break;
          
        case HapticPattern.medium:
          await HapticFeedback.mediumImpact();
          break;
          
        case HapticPattern.heavy:
          await HapticFeedback.heavyImpact();
          break;
          
        case HapticPattern.selection:
          await HapticFeedback.selectionClick();
          break;
          
        case HapticPattern.questComplete:
          // Medium impact for quest completion
          await HapticFeedback.mediumImpact();
          break;
          
        case HapticPattern.approvalCelebration:
          // Medium followed by heavy (100ms gap)
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.heavyImpact();
          break;
          
        case HapticPattern.levelUp:
          // Heavy impact twice (150ms gap)
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 150));
          await HapticFeedback.heavyImpact();
          break;
          
        case HapticPattern.streakMilestone:
          // Light followed by heavy (200ms gap)
          await HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 200));
          await HapticFeedback.heavyImpact();
          break;
      }
    } catch (e) {
      _logger.w('HapticManager: Failed to trigger ${pattern.name}', error: e);
    }
  }
}

/// Enum representing different haptic patterns.
enum HapticPattern {
  light,
  medium,
  heavy,
  selection,
  questComplete,
  approvalCelebration,
  levelUp,
  streakMilestone,
}
