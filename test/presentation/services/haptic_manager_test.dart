import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/services/haptic_manager.dart';

void main() {
  group('HapticManager', () {
    late HapticManager hapticManager;

    setUp(() {
      hapticManager = HapticManager();
    });

    test('should be enabled by default', () {
      expect(hapticManager.isEnabled, true);
    });

    test('should update enabled state when setEnabled is called', () {
      hapticManager.setEnabled(false);
      expect(hapticManager.isEnabled, false);

      hapticManager.setEnabled(true);
      expect(hapticManager.isEnabled, true);
    });

    test('should not throw when triggering haptic while disabled', () async {
      hapticManager.setEnabled(false);
      expect(
        () => hapticManager.trigger(HapticPattern.questComplete),
        returnsNormally,
      );
    });

    test('should not throw for any haptic pattern', () async {
      for (var pattern in HapticPattern.values) {
        expect(
          () => hapticManager.trigger(pattern),
          returnsNormally,
        );
      }
    });
  });

  group('HapticPattern', () {
    test('should have all expected patterns', () {
      expect(HapticPattern.values, contains(HapticPattern.light));
      expect(HapticPattern.values, contains(HapticPattern.medium));
      expect(HapticPattern.values, contains(HapticPattern.heavy));
      expect(HapticPattern.values, contains(HapticPattern.selection));
      expect(HapticPattern.values, contains(HapticPattern.questComplete));
      expect(HapticPattern.values, contains(HapticPattern.approvalCelebration));
      expect(HapticPattern.values, contains(HapticPattern.levelUp));
      expect(HapticPattern.values, contains(HapticPattern.streakMilestone));
    });
  });
}
