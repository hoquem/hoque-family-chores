import 'package:hoque_family_chores/presentation/motion/celebration.dart';

/// The only moments that make a sound (sound spec §Decisions). Adding one
/// here is a product decision, not a refactor.
enum AppSound {
  choreDone('sounds/chore_done.m4a'),
  starsAwarded('sounds/stars_awarded.m4a'),
  treatRedeemed('sounds/treat_redeemed.m4a'),
  streakMilestone('sounds/streak_milestone.m4a');

  const AppSound(this.asset);

  /// Path relative to `assets/`, the form `audioplayers`' `AssetSource` takes.
  final String asset;

  /// Exhaustive over the sealed [CelebrationKind]: a new celebration fails
  /// to compile here until it is given a sound.
  static AppSound forCelebration(CelebrationKind kind) => switch (kind) {
        StarsAwarded() => AppSound.starsAwarded,
        TreatRedeemed() => AppSound.treatRedeemed,
        StreakMilestone() => AppSound.streakMilestone,
      };
}
