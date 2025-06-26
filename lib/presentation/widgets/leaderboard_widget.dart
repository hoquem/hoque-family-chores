// lib/presentation/widgets/leaderboard_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/leaderboard_provider.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class LeaderboardWidget extends StatefulWidget {
  const LeaderboardWidget({super.key});

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  final _logger = AppLogger();

  Future<void> _refreshData() async {
    _logger.d('LeaderboardWidget: Refreshing data');
    final provider = context.read<LeaderboardProvider>();
    final familyId = context.read<AuthProvider>().userFamilyId;
    if (familyId != null) {
      await provider.fetchLeaderboard(familyId: familyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaderboardProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: IntrinsicHeight(
              child: switch (provider.state) {
                LeaderboardState.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                LeaderboardState.error => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Error: ${provider.errorMessage}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8.0),
                      ElevatedButton(
                        onPressed: _refreshData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                LeaderboardState.loaded => _buildLeaderboard(provider),
                LeaderboardState.initial => const Center(
                  child: CircularProgressIndicator(),
                ),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboard(LeaderboardProvider provider) {
    if (provider.entries.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16.0),
              Text(
                'No Leaderboard Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Complete tasks to appear on the leaderboard!',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
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

  Widget _buildLeaderboardTile(dynamic entry, int rank) {
    Icon rankIcon;
    Color tileColor = Colors.white;

    switch (rank) {
      case 1:
        rankIcon = const Icon(
          Icons.emoji_events,
          color: Color(0xFFFFD700),
        ); // Gold
        tileColor = const Color(0xFFFFF8E1);
        break;
      case 2:
        rankIcon = const Icon(
          Icons.emoji_events,
          color: Color(0xFFC0C0C0),
        ); // Silver
        tileColor = Colors.grey.shade100;
        break;
      case 3:
        rankIcon = const Icon(
          Icons.emoji_events,
          color: Color(0xFFCD7F32),
        ); // Bronze
        tileColor = const Color(0xFFFBE9E7);
        break;
      default:
        rankIcon = Icon(
          Icons.circle,
          color: Colors.transparent,
          size: 24,
        ); // Placeholder for alignment
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            Text('${entry.tasksCompleted} tasks'),
          ],
        ),
      ),
    );
  }
}
