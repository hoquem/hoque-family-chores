import 'package:flutter/material.dart';
import '../../../domain/entities/leaderboard_entry.dart';

/// Widget displaying leaderboard entries as a list (for ranks 4+)
class LeaderboardListWidget extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String? currentUserId;
  final bool showWeeklyStats;

  const LeaderboardListWidget({
    super.key,
    required this.entries,
    this.currentUserId,
    this.showWeeklyStats = true,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showWeeklyStats)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Rest of the Pack',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
            ),
          ),
        ...entries.map((entry) => _buildListItem(context, entry)),
      ],
    );
  }

  Widget _buildListItem(BuildContext context, LeaderboardEntry entry) {
    final isCurrentUser = currentUserId != null && entry.userId.value == currentUserId;
    final rankChange = entry.rankChange;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank number
            SizedBox(
              width: 32,
              child: Text(
                entry.rank.toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundImage: entry.userPhotoUrl != null
                  ? NetworkImage(entry.userPhotoUrl!)
                  : null,
              child: entry.userPhotoUrl == null
                  ? Text(
                      entry.userName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.userName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (entry.hasChampionBadge)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('🏆', style: TextStyle(fontSize: 16)),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            // Streak indicator
            const Text('🔥', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              '${entry.currentStreak} day streak',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            
            // Rank change indicator
            if (rankChange != RankChange.none) ...[
              const SizedBox(width: 12),
              _buildRankChangeIndicator(context, rankChange),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  showWeeklyStats
                      ? entry.weeklyStars.toString()
                      : entry.allTimeStars.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankChangeIndicator(BuildContext context, RankChange rankChange) {
    IconData icon;
    Color color;
    
    switch (rankChange) {
      case RankChange.up:
        icon = Icons.arrow_upward;
        color = Colors.green;
        break;
      case RankChange.down:
        icon = Icons.arrow_downward;
        color = Colors.grey;
        break;
      case RankChange.same:
        icon = Icons.remove;
        color = Colors.grey;
        break;
      case RankChange.none:
        return const SizedBox.shrink();
    }
    
    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }
}
