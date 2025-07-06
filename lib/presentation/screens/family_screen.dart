import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/widgets/leaderboard_widget.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/leaderboard_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _logger = AppLogger();
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    Future<void> _refreshData() async {
      _logger.d('FamilyScreen: Refreshing data');
      
      try {
        if (currentUser != null) {
          _logger.d('FamilyScreen: Refreshing leaderboard for familyId: ${currentUser.familyId.value}');
          ref.invalidate(leaderboardNotifierProvider(currentUser.familyId));
          _logger.d('FamilyScreen: Leaderboard refresh completed');
        } else {
          _logger.w('FamilyScreen: currentUser is null, cannot refresh leaderboard');
        }
      } catch (e, stackTrace) {
        _logger.e('FamilyScreen: Error in _refreshData: $e', error: e, stackTrace: stackTrace);
      }
    }

    _logger.d('FamilyScreen: Building screen');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _logger.d('FamilyScreen: Manual refresh triggered');
              _refreshData();
            },
          ),
        ],
      ),
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
                  'Family Leaderboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                _logger.d('FamilyScreen: Building LeaderboardWidget'),
                const LeaderboardWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
