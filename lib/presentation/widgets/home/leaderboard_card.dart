import 'package:flutter/material.dart';
import 'package:hoque_family_chores/domain/services/home_stats.dart';

/// Top three family members by stars earned this week.
class LeaderboardCard extends StatelessWidget {
  const LeaderboardCard({super.key, required this.ranking});

  /// Pre-sorted, best first (see [weeklyStars]).
  final List<MemberStars> ranking;

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final top = ranking.take(_medals.length).toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              "This Week's Stars",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          for (var i = 0; i < top.length; i++)
            ListTile(
              leading: Text(
                _medals[i],
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(top[i].member.name),
              trailing: Text(
                '${top[i].stars} ⭐',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
