import 'package:flutter/material.dart';
import 'package:hoque_family_chores/domain/services/home_stats.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

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

  /// Shown above the progress bar, inside the hero panel (the greeting).
  final Widget? header;

  final int points;
  final int streak;

  /// Called when the card is tapped. Stars only mean something next to what
  /// they buy, so this goes to the treats.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final toNextLevel = 100 - points % 100;
    final tokens = context.tokens;
    // Cream on Lagoon is 6.93:1.
    final onHero = TextStyle(color: tokens.cream);

    return Card(
      color: tokens.lagoon,
      // Inside the Card so the ripple is clipped to its rounded corners.
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          label: '$points stars. See what they can buy.',
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (header case final header?) ...[
                  header,
                  const SizedBox(height: 16),
                ],
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: levelProgress(points),
                    minHeight: 12,
                    color: tokens.starGold,
                    backgroundColor: tokens.lagoonDeep,
                  ),
                ),
                const SizedBox(height: 8),
                Text('$toNextLevel ⭐ to next level', style: onHero),
                const SizedBox(height: 8),
                Text(
                  streak > 0
                      ? '$streak-day streak 🔥'
                      : 'Start a streak today! 🔥',
                  style: onHero.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
