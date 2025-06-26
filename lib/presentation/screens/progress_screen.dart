import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/widgets/user_level_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/badges_widget.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider_base.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/presentation/widgets/task_summary_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/leaderboard_widget.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _logger = AppLogger();

  Future<void> _refreshData() async {
    _logger.d('ProgressScreen: Refreshing data');
    await context.read<AuthProviderBase>().refreshUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('ProgressScreen: Building screen');
    final userProfile = context.watch<AuthProviderBase>().currentUserProfile;
    if (userProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Level Progress',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                UserLevelWidget(userProfile: userProfile),
                const SizedBox(height: 24.0),
                const Text(
                  'Badges & Achievements',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                BadgesWidget(badges: const []),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
