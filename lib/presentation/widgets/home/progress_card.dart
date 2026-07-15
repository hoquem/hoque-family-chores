import 'package:flutter/material.dart';
import 'package:hoque_family_chores/domain/services/home_stats.dart';

/// Level progress bar plus the daily streak.
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.points,
    required this.streak,
  });

  final int points;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final toNextLevel = 100 - points % 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: levelProgress(points),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text('$toNextLevel ⭐ to next level'),
            const SizedBox(height: 8),
            Text(
              streak > 0 ? '$streak-day streak 🔥' : 'Start a streak today! 🔥',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
