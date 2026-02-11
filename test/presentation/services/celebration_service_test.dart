import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/services/celebration_service.dart';
import 'package:hoque_family_chores/presentation/services/sound_manager.dart';
import 'package:hoque_family_chores/presentation/services/haptic_manager.dart';
import 'package:hoque_family_chores/presentation/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CelebrationService', () {
    late CelebrationService celebrationService;
    late SoundManager soundManager;
    late HapticManager hapticManager;
    late PreferencesService preferencesService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      soundManager = SoundManager();
      hapticManager = HapticManager();
      preferencesService = PreferencesService();

      celebrationService = CelebrationService(
        soundManager: soundManager,
        hapticManager: hapticManager,
        preferencesService: preferencesService,
      );

      await celebrationService.initialize();
    });

    tearDown(() {
      celebrationService.dispose();
    });

    test('should initialize with default settings', () async {
      final soundEnabled = await celebrationService.getSoundEnabled();
      final hapticsEnabled = await celebrationService.getHapticsEnabled();
      final reduceMotion = await celebrationService.getReduceMotionEnabled();

      expect(soundEnabled, true);
      expect(hapticsEnabled, true);
      expect(reduceMotion, false);
    });

    test('should update sound enabled setting', () async {
      await celebrationService.setSoundEnabled(false);
      final enabled = await celebrationService.getSoundEnabled();
      expect(enabled, false);
      expect(soundManager.isMuted, true);
    });

    test('should update haptics enabled setting', () async {
      await celebrationService.setHapticsEnabled(false);
      final enabled = await celebrationService.getHapticsEnabled();
      expect(enabled, false);
      expect(hapticManager.isEnabled, false);
    });

    test('should update reduce motion setting', () async {
      await celebrationService.setReduceMotionEnabled(true);
      final enabled = await celebrationService.getReduceMotionEnabled();
      expect(enabled, true);
    });

    test('should not throw when celebrating quest complete', () async {
      expect(
        () => celebrationService.celebrateQuestComplete(),
        returnsNormally,
      );
    });

    test('should not throw when celebrating quest approval', () async {
      expect(
        () => celebrationService.celebrateQuestApproval(),
        returnsNormally,
      );
    });

    test('should not throw when celebrating level up', () async {
      expect(
        () => celebrationService.celebrateLevelUp(),
        returnsNormally,
      );
    });

    test('should not throw when celebrating streak milestone', () async {
      expect(
        () => celebrationService.celebrateStreakMilestone(),
        returnsNormally,
      );
    });

    test('should not throw when triggering light haptic', () async {
      expect(
        () => celebrationService.lightHaptic(),
        returnsNormally,
      );
    });

    test('should not throw when triggering selection haptic', () async {
      expect(
        () => celebrationService.selectionHaptic(),
        returnsNormally,
      );
    });
  });
}
