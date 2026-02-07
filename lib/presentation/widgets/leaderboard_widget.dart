// lib/presentation/widgets/leaderboard_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/leaderboard_notifier.dart';
import 'package:hoque_family_chores/domain/entities/leaderboard_entry.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class LeaderboardWidget extends ConsumerWidget {
  const LeaderboardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = AppLogger();
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    Future<void> refreshData() async {
      logger.d('LeaderboardWidget: Refreshing data');
      if (currentUser != null) {
        ref.invalidate(leaderboardNotifierProvider(currentUser.familyId));
      }
    }

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final leaderboardAsync = ref.watch(leaderboardNotifierProvider(currentUser.familyId));

    logger.d('LeaderboardWidget: Building widget');
    
    return RefreshIndicator(
      onRefresh: refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: IntrinsicHeight(
          child: leaderboardAsync.when(
            data: (entries) => _buildLeaderboard(entries),
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildErrorState(error.toString()),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final logger = AppLogger();
    logger.d('LeaderboardWidget: Building loading state');
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String error) {
    final logger = AppLogger();
    logger.d('LeaderboardWidget: Building error state: $error');
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          ElevatedButton(
            onPressed: () {
              // Refresh will be handled by the parent
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(List<LeaderboardEntry> entries) {
    final logger = AppLogger();
    logger.d('LeaderboardWidget: Building leaderboard with ${entries.length} entries');
    
    if (entries.isEmpty) {
      logger.w('LeaderboardWidget: No entries to display');
      return const Card(
        margin: EdgeInsets.all(16.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No Leaderboard Data',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    logger.d('LeaderboardWidget: Building leaderboard list');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        logger.d('LeaderboardWidget: Building entry $index: ${entry.userName} with ${entry.points.value} points');
        
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: entry.userPhotoUrl != null
                ? NetworkImage(entry.userPhotoUrl!)
                : null,
            child: entry.userPhotoUrl == null
                ? Text(entry.userName[0])
                : null,
          ),
          title: Text(entry.userName),
          subtitle: Text('${entry.points.value} points'),
          trailing: Text(
            '#${entry.rank}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
