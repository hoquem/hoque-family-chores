// lib/presentation/screens/gamification_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/presentation/providers/badge_provider.dart';
import 'package:hoque_family_chores/presentation/providers/reward_provider.dart';
import 'package:hoque_family_chores/models/user_profile.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final badgeProvider = context.read<BadgeProvider>();
    final rewardProvider = context.read<RewardProvider>();
    final familyId = authProvider.userFamilyId;
    if (familyId != null) {
      await badgeProvider.fetchBadges(familyId);
      await rewardProvider.fetchRewards(familyId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProfile = authProvider.currentUserProfile;
    final badgeProvider = context.watch<BadgeProvider>();
    final rewardProvider = context.watch<RewardProvider>();

    if (userProfile == null) {
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
          _buildProgressTab(userProfile),
          _buildBadgesTab(userProfile, badgeProvider),
          _buildRewardsTab(userProfile, rewardProvider),
        ],
      ),
    );
  }

  Widget _buildProgressTab(UserProfile userProfile) {
    final level = UserProfile.calculateLevelFromPoints(userProfile.points);
    final pointsInCurrentLevel = userProfile.pointsInCurrentLevel;
    final pointsNeededForNextLevel = userProfile.pointsNeededForNextLevel;
    final progressToNextLevel = userProfile.progressToNextLevel;

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
                userProfile.points.toString(),
                Icons.attach_money,
                Colors.green,
              ),
              _buildStatCard(
                'Tasks Completed',
                userProfile.completedTasks.length.toString(),
                Icons.check_circle,
                Colors.blue,
              ),
              _buildStatCard(
                'Current Streak',
                userProfile.isOnStreak ? 'Active' : 'Inactive',
                Icons.local_fire_department,
                Colors.orange,
              ),
              _buildStatCard(
                'Achievements',
                userProfile.achievements.length.toString(),
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

  Widget _buildBadgesTab(UserProfile userProfile, BadgeProvider badgeProvider) {
    if (badgeProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (badgeProvider.errorMessage != null) {
      return Center(
        child: Text(
          'Error: ${badgeProvider.errorMessage}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final badges = badgeProvider.badges;
    final userBadgeIds = userProfile.badges;

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isUnlocked = userBadgeIds.contains(badge.id);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: isUnlocked ? null : Colors.grey[200],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  IconData(
                    int.parse(badge.iconName),
                    fontFamily: 'MaterialIcons',
                  ),
                  size: 48,
                  color:
                      isUnlocked ? Theme.of(context).primaryColor : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  badge.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isUnlocked ? null : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isUnlocked ? null : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardsTab(
    UserProfile userProfile,
    RewardProvider rewardProvider,
  ) {
    if (rewardProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rewardProvider.errorMessage != null) {
      return Center(
        child: Text(
          'Error: ${rewardProvider.errorMessage}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final rewards = rewardProvider.rewards;
    final userPoints = userProfile.points;

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final canAfford = userPoints >= reward.pointsCost;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Icon(
              IconData(int.parse(reward.iconName), fontFamily: 'MaterialIcons'),
              size: 32,
              color: canAfford ? Theme.of(context).primaryColor : Colors.grey,
            ),
            title: Text(
              reward.name,
              style: TextStyle(color: canAfford ? null : Colors.grey),
            ),
            subtitle: Text(
              reward.description,
              style: TextStyle(color: canAfford ? null : Colors.grey),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${reward.pointsCost} points',
                  style: TextStyle(
                    color: canAfford ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (canAfford)
                  TextButton(
                    onPressed: () {
                      // TODO: Implement reward redemption
                    },
                    child: const Text('Redeem'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
