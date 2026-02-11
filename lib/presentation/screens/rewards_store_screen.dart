import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../widgets/rewards/reward_card.dart';
import '../widgets/rewards/star_balance_header.dart';
import '../widgets/rewards/redemption_history_view.dart';
import '../providers/riverpod/rewards_notifier.dart';

part 'rewards_store_screen.g.dart';

/// Main rewards store screen where users can browse and redeem rewards
class RewardsStoreScreen extends ConsumerStatefulWidget {
  final FamilyId familyId;
  final UserId userId;

  const RewardsStoreScreen({
    Key? key,
    required this.familyId,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<RewardsStoreScreen> createState() => _RewardsStoreScreenState();
}

class _RewardsStoreScreenState extends ConsumerState<RewardsStoreScreen>
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
    final rewardsAsync = ref.watch(rewardsNotifierProvider(widget.familyId));
    final userPointsAsync = ref.watch(userPointsProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards Store'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Store', icon: Icon(Icons.store)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStoreTab(rewardsAsync, userPointsAsync),
          RedemptionHistoryView(
            familyId: widget.familyId,
            userId: widget.userId,
          ),
        ],
      ),
    );
  }

  Widget _buildStoreTab(
    AsyncValue rewardsAsync,
    AsyncValue userPointsAsync,
  ) {
    return rewardsAsync.when(
      data: (rewards) {
        final userPoints = userPointsAsync.value ?? 0;
        
        if (rewards.isEmpty) {
          return _buildEmptyState();
        }

        final featured = rewards.where((r) => r.isFeatured).toList();
        final allRewards = rewards.toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(rewardsNotifierProvider(widget.familyId));
          },
          child: CustomScrollView(
            slivers: [
              // Star Balance Header
              SliverToBoxAdapter(
                child: StarBalanceHeader(
                  starBalance: userPoints,
                  nextReward: _findNextAffordableReward(allRewards, userPoints),
                ),
              ),

              // Featured Rewards Section
              if (featured.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: featured.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 160,
                              child: RewardCard(
                                reward: featured[index],
                                userStars: userPoints,
                                onRedeem: () => _handleRedemption(featured[index]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],

              // All Rewards Section
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'All Rewards',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return RewardCard(
                        reward: allRewards[index],
                        userStars: userPoints,
                        onRedeem: () => _handleRedemption(allRewards[index]),
                      );
                    },
                    childCount: allRewards.length,
                  ),
                ),
              ),

              // Bottom padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
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
            Text('Error loading rewards: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(rewardsNotifierProvider(widget.familyId));
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No rewards available yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask your parents to create some rewards!',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String? _findNextAffordableReward(List rewards, int currentStars) {
    final unaffordable = rewards
        .where((r) => r.costAsInt > currentStars)
        .toList()
      ..sort((a, b) => a.costAsInt.compareTo(b.costAsInt));
    
    if (unaffordable.isEmpty) return null;
    return unaffordable.first.name;
  }

  Future<void> _handleRedemption(reward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reward.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${reward.iconEmoji}',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            if (reward.description != null) ...[
              Text(reward.description!),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    '${reward.costAsInt}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Requires parent approval',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm Redemption'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(
          requestRedemptionProvider(
            widget.familyId,
            widget.userId,
            reward.id,
          ).future,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Redemption requested! Waiting for parent approval.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh rewards and user points
          ref.invalidate(rewardsNotifierProvider(widget.familyId));
          ref.invalidate(userPointsProvider(widget.userId));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to redeem: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Provider for user's current points/stars
@riverpod
Future<int> userPoints(Ref ref, UserId userId) async {
  // This should connect to your existing gamification system
  // For now, return a placeholder
  return 500;
}
