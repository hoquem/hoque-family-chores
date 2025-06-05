// lib/presentation/widgets/leaderboard_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/leaderboard_provider.dart';

class LeaderboardWidget extends StatelessWidget {
  const LeaderboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaderboardProvider>(
      builder: (context, provider, child) {
        switch (provider.state) {
          case LeaderboardState.loading:
          case LeaderboardState.initial:
            return const Center(child: CircularProgressIndicator());
          case LeaderboardState.error:
            return Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Could not load leaderboard: ${provider.errorMessage}'),
              ),
            );
          case LeaderboardState.loaded:
            if (provider.entries.isEmpty) {
              return const Card(child: ListTile(title: Text('Leaderboard data is not available yet.')));
            }

            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: provider.entries.length,
              itemBuilder: (context, index) {
                final entry = provider.entries[index];
                final rank = index + 1;
                return _buildLeaderboardTile(entry, rank);
              },
            );
        }
      },
    );
  }

  Widget _buildLeaderboardTile(dynamic entry, int rank) {
    Icon rankIcon;
    Color tileColor = Colors.white;

    switch (rank) {
      case 1:
        rankIcon = const Icon(Icons.emoji_events, color: Color(0xFFFFD700)); // Gold
        tileColor = const Color(0xFFFFF8E1);
        break;
      case 2:
        rankIcon = const Icon(Icons.emoji_events, color: Color(0xFFC0C0C0)); // Silver
        tileColor = Colors.grey.shade100;
        break;
      case 3:
        rankIcon = const Icon(Icons.emoji_events, color: Color(0xFFCD7F32)); // Bronze
        tileColor = const Color(0xFFFBE9E7);
        break;
      default:
        rankIcon = Icon(Icons.circle, color: Colors.transparent, size: 24); // Placeholder for alignment
    }

    return Card(
      elevation: rank <= 3 ? 4 : 1,
      color: tileColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$rank',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            rankIcon,
          ],
        ),
        title: Text(
          entry.member.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.points} pts',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            Text('${entry.tasksCompleted} tasks'),
          ],
        ),
      ),
    );
  }
}