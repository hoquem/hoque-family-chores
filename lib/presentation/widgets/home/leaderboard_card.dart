import 'package:flutter/material.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/services/home_stats.dart';

/// Top three family members by stars earned this week.
class LeaderboardCard extends StatelessWidget {
  const LeaderboardCard({
    super.key,
    required this.ranking,
    required this.onOpenMember,
  });

  /// Pre-sorted, best first (see [weeklyStars]).
  final List<MemberStars> ranking;

  /// Called when a member's row is tapped. A name and a star count invites
  /// "how did they get those?" — this is the way to the answer.
  final void Function(User member) onOpenMember;

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
              onTap: () => onOpenMember(top[i].member),
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
