// lib/presentation/widgets/leaderboard_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider_base.dart';
import 'package:hoque_family_chores/presentation/providers/leaderboard_provider.dart';
import 'package:hoque_family_chores/models/leaderboard_entry.dart';
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
    final familyId = context.read<AuthProviderBase>().userFamilyId;
    if (familyId != null) {
      await provider.fetchLeaderboard(familyId: familyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('LeaderboardWidget: Building widget');
    return Consumer<LeaderboardProvider>(
      builder: (context, provider, child) {
        _logger.d('LeaderboardWidget: Consumer builder called with state: ${provider.state}');
        _logger.d('LeaderboardWidget: Entries count: ${provider.entries.length}');
        _logger.d('LeaderboardWidget: Error message: "${provider.errorMessage}"');
        
        if (provider.entries.isNotEmpty) {
          _logger.d('LeaderboardWidget: First entry: ${provider.entries.first.member.name} with ${provider.entries.first.points} points');
        }
        
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: IntrinsicHeight(
              child: switch (provider.state) {
                LeaderboardState.loading => _buildLoadingState(),
                LeaderboardState.error => _buildErrorState(provider),
                LeaderboardState.loaded => _buildLeaderboard(provider),
                LeaderboardState.initial => _buildLoadingState(),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    _logger.d('LeaderboardWidget: Building loading state');
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(LeaderboardProvider provider) {
    _logger.d('LeaderboardWidget: Building error state: ${provider.errorMessage}');
    return Center(
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
    );
  }

  Widget _buildLeaderboard(LeaderboardProvider provider) {
    _logger.d('LeaderboardWidget: Building leaderboard with ${provider.entries.length} entries');
    
    if (provider.entries.isEmpty) {
      _logger.w('LeaderboardWidget: No entries to display');
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

    _logger.d('LeaderboardWidget: Building leaderboard list');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.entries.length,
      itemBuilder: (context, index) {
        final entry = provider.entries[index];
        _logger.d('LeaderboardWidget: Building entry $index: ${entry.member.name} with ${entry.points} points');
        
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: entry.member.photoUrl != null
                ? NetworkImage(entry.member.photoUrl!)
                : null,
            child: entry.member.photoUrl == null
                ? Text(entry.member.name[0])
                : null,
          ),
          title: Text(entry.member.name),
          subtitle: Text('${entry.points} points'),
          trailing: Text(
            '#${index + 1}',
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
