import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/services/sound_manager.dart';

void main() {
  group('SoundManager', () {
    late SoundManager soundManager;

    setUp(() {
      soundManager = SoundManager();
    });

    tearDown(() {
      soundManager.dispose();
    });

    test('should be unmuted by default', () {
      expect(soundManager.isMuted, false);
    });

    test('should update muted state when setMuted is called', () {
      soundManager.setMuted(true);
      expect(soundManager.isMuted, true);

      soundManager.setMuted(false);
      expect(soundManager.isMuted, false);
    });

    test('should not throw when playing sound while muted', () async {
      soundManager.setMuted(true);
      expect(
        () => soundManager.play(SoundEffect.questComplete),
        returnsNormally,
      );
    });

    test('should gracefully handle missing sound files', () async {
      // Even with missing files, should not throw
      expect(
        () => soundManager.play(SoundEffect.questComplete),
        returnsNormally,
      );
    });
  });

  group('SoundEffect', () {
    test('should have correct filenames', () {
      expect(SoundEffect.questComplete.filename, 'quest_complete.mp3');
      expect(SoundEffect.approvalCelebrate.filename, 'approval_celebrate.mp3');
      expect(SoundEffect.levelUp.filename, 'level_up.mp3');
      expect(SoundEffect.streakMilestone.filename, 'streak_milestone.mp3');
    });

    test('should have valid volume levels', () {
      for (var effect in SoundEffect.values) {
        expect(effect.volume, greaterThanOrEqualTo(0.0));
        expect(effect.volume, lessThanOrEqualTo(1.0));
      }
    });
  });
}
