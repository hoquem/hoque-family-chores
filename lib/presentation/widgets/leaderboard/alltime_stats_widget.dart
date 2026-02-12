import 'package:flutter/material.dart';
import '../../../domain/entities/leaderboard_entry.dart';

/// Widget displaying all-time statistics leaderboard
class AllTimeStatsWidget extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String? currentUserId;

  const AllTimeStatsWidget({
    super.key,
    required this.entries,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No statistics available yet.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '🏆 ALL-TIME CHAMPIONS',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Records section
        _buildRecordsSection(context),
        
        const SizedBox(height: 24),
        
        // All-time leaderboard
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: entries.map((entry) => _buildStatCard(context, entry)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsSection(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    
    // Calculate records
    final highestAllTimeStars = entries.first.allTimeStars;
    final longestStreak = entries.map((e) => e.longestStreak).reduce((a, b) => a > b ? a : b);
    final mostQuests = entries.map((e) => e.questsCompleted).reduce((a, b) => a > b ? a : b);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏅 FAMILY RECORDS',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRecordTile(
                  context,
                  icon: '⭐',
                  value: highestAllTimeStars.toString(),
                  label: 'Highest Stars',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRecordTile(
                  context,
                  icon: '🔥',
                  value: '$longestStreak days',
                  label: 'Longest Streak',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRecordTile(
                  context,
                  icon: '✅',
                  value: mostQuests.toString(),
                  label: 'Most Quests',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(), // Placeholder for symmetry
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordTile(
    BuildContext context, {
    required String icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, LeaderboardEntry entry) {
    final isCurrentUser = currentUserId != null && entry.userId.value == currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with rank, avatar, name
          Row(
            children: [
              // Rank
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: entry.rank <= 3
                      ? _getRankColor(entry.rank)
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    entry.rank.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
              
              const SizedBox(width: 12),
              
              // Name and champion badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.userName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (entry.hasChampionBadge)
                      const Text(
                        '🏆 Last Week\'s Champion',
                        style: TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
              
              // Total stars
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        entry.allTimeStars.toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                    ],
                  ),
                  Text(
                    'total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ],
          ),
          
          const Divider(height: 24),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                context,
                icon: '✅',
                value: entry.questsCompleted.toString(),
                label: 'Quests',
              ),
              _buildStatColumn(
                context,
                icon: '🔥',
                value: entry.longestStreak.toString(),
                label: 'Best Streak',
              ),
              _buildStatColumn(
                context,
                icon: '⚡',
                value: entry.currentStreak.toString(),
                label: 'Current',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required String icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }
}
