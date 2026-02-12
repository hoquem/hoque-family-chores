import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/value_objects/family_id.dart';
import '../providers/riverpod/weekly_leaderboard_notifier.dart';
import '../providers/riverpod/alltime_leaderboard_notifier.dart';
import '../widgets/leaderboard/podium_widget.dart';
import '../widgets/leaderboard/weekly_countdown_widget.dart';
import '../widgets/leaderboard/leaderboard_list_widget.dart';
import '../widgets/leaderboard/alltime_stats_widget.dart';

/// Main leaderboard screen with weekly and all-time tabs
class LeaderboardScreen extends ConsumerStatefulWidget {
  final FamilyId familyId;
  final String? currentUserId;

  const LeaderboardScreen({
    super.key,
    required this.familyId,
    this.currentUserId,
  });

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Leaderboard'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'This Week'),
            Tab(text: 'All Time'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWeeklyTab(),
          _buildAllTimeTab(),
        ],
      ),
    );
  }

  Widget _buildWeeklyTab() {
    final weeklyLeaderboardAsync = ref.watch(
      weeklyLeaderboardNotifierProvider(widget.familyId),
    );

    return weeklyLeaderboardAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _buildEmptyState();
        }

        // Split into podium (top 3) and rest
        final podiumEntries = entries.take(3).toList();
        final remainingEntries = entries.length > 3 
            ? List<LeaderboardEntry>.from(entries.skip(3)) 
            : <LeaderboardEntry>[];

        final notifier = ref.read(
          weeklyLeaderboardNotifierProvider(widget.familyId).notifier,
        );

        return RefreshIndicator(
          onRefresh: () async {
            await notifier.refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // Week date range header
                Text(
                  'Week of ${notifier.getWeekDateRange()}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                
                const SizedBox(height: 24),
                
                // Podium for top 3
                if (podiumEntries.isNotEmpty)
                  PodiumWidget(
                    entries: podiumEntries,
                    currentUserId: widget.currentUserId,
                  ),
                
                const SizedBox(height: 24),
                
                // Weekly countdown timer
                WeeklyCountdownWidget(
                  weekStart: notifier.getWeekStart(),
                  weekEnd: notifier.getWeekEnd(),
                ),
                
                const SizedBox(height: 24),
                
                // Remaining entries (4th place and below)
                if (remainingEntries.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LeaderboardListWidget(
                      entries: remainingEntries,
                      currentUserId: widget.currentUserId,
                      showWeeklyStats: true,
                    ),
                  ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading leaderboard'),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(weeklyLeaderboardNotifierProvider(widget.familyId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTimeTab() {
    final allTimeLeaderboardAsync = ref.watch(
      allTimeLeaderboardNotifierProvider(widget.familyId),
    );

    return allTimeLeaderboardAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return _buildEmptyState();
        }

        final notifier = ref.read(
          allTimeLeaderboardNotifierProvider(widget.familyId).notifier,
        );

        return RefreshIndicator(
          onRefresh: () async {
            await notifier.refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // All-time statistics
                AllTimeStatsWidget(
                  entries: entries,
                  currentUserId: widget.currentUserId,
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading all-time leaderboard'),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(allTimeLeaderboardNotifierProvider(widget.familyId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'Let the games begin!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete chores to earn your spot\non the family leaderboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.task_alt),
              label: const Text('Start First Quest'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Winner announced every Sunday!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
