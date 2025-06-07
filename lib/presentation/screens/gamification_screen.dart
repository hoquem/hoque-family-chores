// lib/presentation/screens/gamification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/models/badge.dart' as app_badge;
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/presentation/providers/gamification_provider.dart';
import 'package:hoque_family_chores/presentation/widgets/user_level_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/badges_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/rewards_store_widget.dart';
import 'package:hoque_family_chores/services/gamification_service.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({Key? key}) : super(key: key);

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isEventsExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load gamification data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGamificationData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadGamificationData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);
    
    if (authProvider.isLoggedIn && authProvider.currentUser != null) {
      gamificationProvider.loadAllData(authProvider.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gamification'),
        ),
        body: const Center(
          child: Text('Please log in to view your gamification progress'),
        ),
      );
    }

    return Consumer<GamificationProvider>(
      builder: (context, gamificationProvider, child) {
        final userProfile = gamificationProvider.userProfile;
        final profileState = gamificationProvider.profileState;
        final recentEvents = gamificationProvider.recentEvents;
        
        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text('Achievements & Rewards'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () {
                  gamificationProvider.loadAllData(authProvider.currentUser!.uid);
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.trending_up),
                  text: 'Progress',
                ),
                Tab(
                  icon: Icon(Icons.emoji_events),
                  text: 'Badges',
                ),
                Tab(
                  icon: Icon(Icons.redeem),
                  text: 'Rewards',
                ),
              ],
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ),
          body: Column(
            children: [
              // User level section (always visible)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16.0),
                child: _buildUserLevelSection(userProfile, profileState, gamificationProvider),
              ),
              
              // Recent events section (expandable)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isEventsExpanded ? 120 : 0,
                child: _isEventsExpanded
                    ? _buildRecentEventsSection(recentEvents)
                    : const SizedBox.shrink(),
              ),
              
              // Toggle button for events
              InkWell(
                onTap: () {
                  setState(() {
                    _isEventsExpanded = !_isEventsExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isEventsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isEventsExpanded ? 'Hide Recent Events' : 'Show Recent Events',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Progress Tab
                    _buildProgressTab(userProfile, profileState, gamificationProvider, authProvider),
                    
                    // Badges Tab
                    _buildBadgesTab(userProfile, gamificationProvider, authProvider),
                    
                    // Rewards Tab
                    _buildRewardsTab(userProfile, gamificationProvider, authProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserLevelSection(
    UserProfile? userProfile, 
    GamificationLoadingState profileState,
    GamificationProvider gamificationProvider,
  ) {
    if (profileState == GamificationLoadingState.loading && userProfile == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (profileState == GamificationLoadingState.error || userProfile == null) {
      return Center(
        child: Column(
          children: [
            const Text('Failed to load user profile'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                if (authProvider.currentUser != null) {
                  gamificationProvider.retryLoadProfile(authProvider.currentUser!.uid);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    return UserLevelWidget(
      userProfile: userProfile,
      showLevelUpAnimation: gamificationProvider.showLevelUpAnimation,
      onAnimationComplete: () {
        gamificationProvider.resetAnimations();
      },
    );
  }

  Widget _buildRecentEventsSection(List<GamificationEvent> events) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Text(
          'No recent events',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Recent Events',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return _buildEventCard(event);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(GamificationEvent event) {
    Color cardColor;
    IconData iconData;
    
    switch (event.type) {
      case GamificationEventType.pointsEarned:
        cardColor = Colors.green.shade100;
        iconData = Icons.stars;
        break;
      case GamificationEventType.levelUp:
        cardColor = Colors.purple.shade100;
        iconData = Icons.trending_up;
        break;
      case GamificationEventType.badgeUnlocked:
        cardColor = Colors.blue.shade100;
        iconData = Icons.emoji_events;
        break;
      case GamificationEventType.rewardRedeemed:
        cardColor = Colors.orange.shade100;
        iconData = Icons.redeem;
        break;
      case GamificationEventType.streakIncreased:
        cardColor = Colors.amber.shade100;
        iconData = Icons.local_fire_department;
        break;
      case GamificationEventType.achievementUnlocked:
        cardColor = Colors.indigo.shade100;
        iconData = Icons.workspace_premium;
        break;
    }
    
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(right: 12.0, bottom: 8.0),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, size: 16),
                const SizedBox(width: 8),
                Text(
                  _getEventTypeText(event.type),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                event.message,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatEventTime(event.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEventTypeText(GamificationEventType type) {
    switch (type) {
      case GamificationEventType.pointsEarned:
        return 'Points Earned';
      case GamificationEventType.levelUp:
        return 'Level Up';
      case GamificationEventType.badgeUnlocked:
        return 'Badge Unlocked';
      case GamificationEventType.rewardRedeemed:
        return 'Reward Redeemed';
      case GamificationEventType.streakIncreased:
        return 'Streak Increased';
      case GamificationEventType.achievementUnlocked:
        return 'Achievement Unlocked';
    }
  }

  String _formatEventTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildProgressTab(
    UserProfile? userProfile,
    GamificationLoadingState profileState,
    GamificationProvider gamificationProvider,
    AuthProvider authProvider,
  ) {
    if (profileState == GamificationLoadingState.loading && userProfile == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (profileState == GamificationLoadingState.error || userProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Failed to load progress data'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                if (authProvider.currentUser != null) {
                  gamificationProvider.retryLoadProfile(authProvider.currentUser!.uid);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats cards
          _buildStatsGrid(userProfile),
          
          const SizedBox(height: 24),
          
          // Level progression
          const Text(
            'Level Progression',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildLevelProgressionChart(userProfile),
          
          const SizedBox(height: 24),
          
          // Achievements summary
          const Text(
            'Achievements Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildAchievementsSummary(userProfile, gamificationProvider),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(UserProfile userProfile) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Tasks Completed',
          '${userProfile.completedTasks}',
          Icons.task_alt,
          Colors.green,
        ),
        _buildStatCard(
          'Current Streak',
          '${userProfile.currentStreak} days',
          Icons.local_fire_department,
          Colors.orange,
        ),
        _buildStatCard(
          'Longest Streak',
          '${userProfile.longestStreak} days',
          Icons.emoji_events,
          Colors.amber,
        ),
        _buildStatCard(
          'Member Since',
          _formatDate(userProfile.joinedAt),
          Icons.calendar_today,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelProgressionChart(UserProfile userProfile) {
    // This is a simplified level progression chart
    // In a real app, you might want to use a charting library
    
    final levelColors = [
      Colors.grey,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.red,
    ];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Level ${userProfile.currentLevel}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Level ${userProfile.currentLevel + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: userProfile.levelProgressPercentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  levelColors[userProfile.currentLevel % levelColors.length],
                ),
                minHeight: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${userProfile.levelProgressPercentage}% complete - ${userProfile.pointsToNextLevel} points to next level',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Keep completing tasks to earn points and level up!',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSummary(UserProfile userProfile, GamificationProvider gamificationProvider) {
    final badgesState = gamificationProvider.badgesState;
    final userBadges = gamificationProvider.userBadges;
    final allBadges = gamificationProvider.allBadges;
    
    if (badgesState == GamificationLoadingState.loading && userBadges.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (badgesState == GamificationLoadingState.error) {
      return Center(
        child: Text(
          'Failed to load badges: ${gamificationProvider.badgesError}',
          textAlign: TextAlign.center,
        ),
      );
    }
    
    final badgeProgress = allBadges.isEmpty ? 0.0 : userBadges.length / allBadges.length;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Badges Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${userBadges.length}/${allBadges.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: badgeProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recently Earned Badges',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: userBadges.isEmpty
                  ? const Center(
                      child: Text(
                        'No badges earned yet',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: userBadges.length > 5 ? 5 : userBadges.length,
                      itemBuilder: (context, index) {
                        final badge = userBadges[index];
                        return _buildBadgeItem(badge);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeItem(app_badge.Badge badge) {
    final color = badge.rarity.color;
    
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8.0),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(int.parse(badge.color.replaceFirst('#', '0xff'))),
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _getBadgeIcon(badge.iconName),
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesTab(
    UserProfile? userProfile,
    GamificationProvider gamificationProvider,
    AuthProvider authProvider,
  ) {
    if (userProfile == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    final badgesState = gamificationProvider.badgesState;
    final userBadges = gamificationProvider.userBadges;
    final allBadges = gamificationProvider.allBadges;
    
    if (badgesState == GamificationLoadingState.loading && userBadges.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (badgesState == GamificationLoadingState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Failed to load badges: ${gamificationProvider.badgesError}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                if (authProvider.currentUser != null) {
                  gamificationProvider.retryLoadBadges(authProvider.currentUser!.uid);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    return BadgesWidget(
      userProfile: userProfile,
      allBadges: allBadges,
      unlockedBadges: userBadges,
      showUnlockAnimation: gamificationProvider.showBadgeUnlockAnimation,
      newlyUnlockedBadge: gamificationProvider.newlyUnlockedBadge,
    );
  }

  Widget _buildRewardsTab(
    UserProfile? userProfile,
    GamificationProvider gamificationProvider,
    AuthProvider authProvider,
  ) {
    if (userProfile == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    final rewardsState = gamificationProvider.rewardsState;
    final userRewards = gamificationProvider.userRewards;
    final allRewards = gamificationProvider.allRewards;
    
    if (rewardsState == GamificationLoadingState.loading && userRewards.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (rewardsState == GamificationLoadingState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Failed to load rewards: ${gamificationProvider.rewardsError}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                if (authProvider.currentUser != null) {
                  gamificationProvider.retryLoadRewards(authProvider.currentUser!.uid);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    return RewardsStoreWidget(
      userProfile: userProfile,
      availableRewards: allRewards,
      redeemedRewards: userRewards,
      showPurchaseAnimation: gamificationProvider.showRewardPurchaseAnimation,
      newlyPurchasedReward: gamificationProvider.newlyPurchasedReward,
      onRewardRedeem: (reward) async {
        if (authProvider.currentUser != null) {
          final success = await gamificationProvider.redeemReward(
            authProvider.currentUser!.uid,
            reward.id,
          );
          
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully redeemed "${reward.title}"!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to redeem reward. Try again later.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper method to get badge icon
  IconData _getBadgeIcon(String iconName) {
    switch (iconName) {
      case 'task_beginner': return Icons.assignment_outlined;
      case 'task_apprentice': return Icons.assignment;
      case 'task_expert': return Icons.assignment_turned_in_outlined;
      case 'task_master': return Icons.assignment_turned_in;
      case 'task_legend': return Icons.workspace_premium;
      case 'weekend_warrior': return Icons.weekend;
      case 'week_warrior': return Icons.calendar_view_week;
      case 'month_warrior': return Icons.calendar_month;
      case 'helping_hand': return Icons.handshake;
      case 'super_helper': return Icons.volunteer_activism;
      case 'neat_freak': return Icons.cleaning_services;
      case 'cleaning_champion': return Icons.cleaning_services_outlined;
      case 'early_bird': return Icons.wb_sunny;
      case 'night_owl': return Icons.nightlight_round;
      case 'overachiever': return Icons.emoji_events;
      case 'family_hero': return Icons.military_tech;
      default: return Icons.star;
    }
  }
}
