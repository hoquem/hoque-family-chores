import 'package:flutter/material.dart';
import 'package:hoque_family_chores/domain/services/home_stats.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/hero_panel.dart';

/// Level progress bar plus the daily streak: the Home hero, so it owns the
/// one bold region on the screen (gold stars on Lagoon).
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.points,
    required this.streak,
    required this.onTap,
    this.header,
  });

  final int points;
  final int streak;

  /// Called when the progress part is tapped. Stars only mean something next
  /// to what they buy, so this goes to the treats.
  final VoidCallback onTap;

  /// Shown above the progress, inside the panel (the greeting). Kept outside
  /// the tap target so a screen reader does not fold it into the button.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final toNextLevel = 100 - points % 100;
    final tokens = context.tokens;

    return HeroPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header case final header?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: header,
            ),
          InkWell(
            onTap: onTap,
            child: Semantics(
              button: true,
              label: '$points stars. See what they can buy.',
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      // Star Gold on Lagoon Deep is 5.84:1.
                      child: LinearProgressIndicator(
                        value: levelProgress(points),
                        minHeight: 12,
                        color: tokens.starGold,
                        backgroundColor: tokens.lagoonDeep,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('$toNextLevel ⭐ to next level'),
                    const SizedBox(height: 8),
                    Text(
                      streak > 0
                          ? '$streak-day streak 🔥'
                          : 'Start a streak today! 🔥',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
