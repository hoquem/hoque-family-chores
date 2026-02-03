// lib/presentation/screens/gamification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/gamification_notifier.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';

class GamificationScreen extends ConsumerStatefulWidget {
  const GamificationScreen({super.key});

  @override
  ConsumerState<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends ConsumerState<GamificationScreen>
    with SingleTickerProviderStateMixin {
  final _logger = AppLogger();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final authState = ref.read(authNotifierProvider);
    final currentUser = authState.user;
    
    if (currentUser != null) {
      // The providers will automatically load data when watched
      _logger.d('GamificationScreen: Data will be loaded by providers');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'Progress'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Badges'),
            Tab(icon: Icon(Icons.redeem), text: 'Rewards'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProgressTab(currentUser),
          _buildBadgesTab(currentUser),
          _buildRewardsTab(currentUser),
        ],
      ),
    );
  }

  Widget _buildProgressTab(User currentUser) {
    final level = (currentUser.points.value / 100).floor() + 1;
    final pointsInCurrentLevel = currentUser.points.value % 100;
    final pointsNeededForNextLevel = 100;
    final progressToNextLevel = pointsInCurrentLevel / pointsNeededForNextLevel;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level Progress Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        'Level $level',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progressToNextLevel,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$pointsInCurrentLevel / $pointsNeededForNextLevel points to next level',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Total Points',
                currentUser.points.value.toString(),
                Icons.attach_money,
                Colors.green,
              ),
              _buildStatCard(
                'Tasks Completed',
                '0', // TODO: Get from task repository
                Icons.check_circle,
                Colors.blue,
              ),
              _buildStatCard(
                'Current Streak',
                'Active', // TODO: Get from user profile
                Icons.local_fire_department,
                Colors.orange,
              ),
              _buildStatCard(
                'Achievements',
                '0', // TODO: Get from achievements
                Icons.emoji_events,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesTab(User currentUser) {
    // TODO: Implement badges tab with new badge notifier
    return const Center(
      child: Text('Badges coming soon!'),
    );
  }

  Widget _buildRewardsTab(User currentUser) {
    // TODO: Implement rewards tab with new reward notifier
    return const Center(
      child: Text('Rewards coming soon!'),
    );
  }

  /// Helper method to redeem a reward
  Future<void> _redeemReward(BuildContext context, String rewardId, User currentUser) async {
    try {
      await ref.read(gamificationNotifierProvider(currentUser.id).notifier).redeemReward(rewardId, currentUser.familyId);
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reward redeemed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to redeem reward: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Helper method to convert icon name string to IconData
  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'star_border':
        return Icons.star_border;
      case 'military_tech':
        return Icons.military_tech;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'theaters':
        return Icons.theaters;
      case 'icecream':
        return Icons.icecream;
      case 'trending_up':
        return Icons.trending_up;
      case 'redeem':
        return Icons.redeem;
      case 'attach_money':
        return Icons.attach_money;
      case 'check_circle':
        return Icons.check_circle;
      case 'star':
        return Icons.star;
      default:
        return Icons.emoji_events; // Default fallback
    }
  }
}
