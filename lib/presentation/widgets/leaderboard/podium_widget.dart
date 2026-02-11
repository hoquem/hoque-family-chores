import 'package:flutter/material.dart';
import '../../../domain/entities/leaderboard_entry.dart';

/// Podium widget displaying top 3 leaderboard positions
/// with gold, silver, and bronze styling
class PodiumWidget extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String? currentUserId;

  const PodiumWidget({
    super.key,
    required this.entries,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Handle edge cases
    if (entries.isEmpty) return const SizedBox.shrink();
    
    final first = entries.length > 0 ? entries[0] : null;
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Second place (left)
          if (second != null)
            Expanded(
              child: _buildPodiumPosition(
                context,
                entry: second,
                position: 2,
                height: 96,
                color: const Color(0xFFC0C0C0), // Silver
                badge: '🥈',
              ),
            ),
          
          const SizedBox(width: 12),
          
          // First place (center)
          if (first != null)
            Expanded(
              child: _buildPodiumPosition(
                context,
                entry: first,
                position: 1,
                height: 120,
                color: const Color(0xFFFFD700), // Gold
                badge: '👑',
              ),
            ),
          
          const SizedBox(width: 12),
          
          // Third place (right)
          if (third != null)
            Expanded(
              child: _buildPodiumPosition(
                context,
                entry: third,
                position: 3,
                height: 72,
                color: const Color(0xFFCD7F32), // Bronze
                badge: '🥉',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(
    BuildContext context, {
    required LeaderboardEntry entry,
    required int position,
    required double height,
    required Color color,
    required String badge,
  }) {
    final isCurrentUser = currentUserId != null && entry.userId.value == currentUserId;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge (crown/medal)
        Text(
          badge,
          style: const TextStyle(fontSize: 32),
        ),
        
        const SizedBox(height: 8),
        
        // Avatar with ring
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: position == 1 ? 4 : 3,
            ),
          ),
          child: CircleAvatar(
            radius: position == 1 ? 32 : 28,
            backgroundImage: entry.userPhotoUrl != null
                ? NetworkImage(entry.userPhotoUrl!)
                : null,
            child: entry.userPhotoUrl == null
                ? Text(
                    entry.userName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: position == 1 ? 24 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Name
        Text(
          entry.userName,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: position == 1 ? FontWeight.bold : FontWeight.w600,
                color: isCurrentUser ? Theme.of(context).primaryColor : null,
              ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 4),
        
        // Weekly stars
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              entry.weeklyStars.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Current streak
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              entry.currentStreak.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Podium base
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getPositionText(position),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (entry.hasChampionBadge)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '🏆',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getPositionText(int position) {
    switch (position) {
      case 1:
        return '1ST';
      case 2:
        return '2ND';
      case 3:
        return '3RD';
      default:
        return '${position}TH';
    }
  }
}
