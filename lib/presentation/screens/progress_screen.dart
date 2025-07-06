import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/widgets/user_level_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/badges_widget.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/presentation/widgets/task_summary_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/leaderboard_widget.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _logger = AppLogger();
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    Future<void> _refreshData() async {
      _logger.d('ProgressScreen: Refreshing data');
      await ref.read(authNotifierProvider.notifier).refresh();
    }

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    _logger.d('ProgressScreen: Building screen');
    
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
                UserLevelWidget(user: currentUser),
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
