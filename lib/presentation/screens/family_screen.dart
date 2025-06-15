import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/widgets/leaderboard_widget.dart';
import 'package:hoque_family_chores/presentation/providers/leaderboard_provider.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _logger = AppLogger();

  Future<void> _refreshData() async {
    _logger.d('FamilyScreen: Refreshing data');
    final leaderboardProvider = context.read<LeaderboardProvider>();
    final familyId = context.read<AuthProvider>().userFamilyId;

    if (familyId != null) {
      await leaderboardProvider.fetchLeaderboard(familyId: familyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('FamilyScreen: Building screen');
    return Scaffold(
      appBar: AppBar(title: const Text('Family')),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: LeaderboardWidget(),
          ),
        ),
      ),
    );
  }
}
