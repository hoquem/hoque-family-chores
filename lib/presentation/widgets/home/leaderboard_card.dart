import 'package:flutter/material.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/services/home_stats.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/user_avatar.dart';

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
      color: context.tokens.sunshineTint,
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
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: switch (i) {
                      0 => '1st place',
                      1 => '2nd place',
                      2 => '3rd place',
                      _ => '${i + 1}th place',
                    },
                    child: Text(
                      _medals[i],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  UserAvatar(user: top[i].member, radius: 16),
                ],
              ),
              title: Text(top[i].member.name),
              trailing: Semantics(
                label: '${top[i].stars} stars',
                child: Text(
                  '${top[i].stars} ⭐',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
