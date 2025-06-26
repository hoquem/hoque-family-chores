// lib/presentation/widgets/rewards_store_widget.dart

import 'package:flutter/material.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/models/user_profile.dart';

class RewardsStoreWidget extends StatefulWidget {
  final UserProfile userProfile;

  // These properties were in your gamification screen; they can be passed here if needed
  final List<Reward> availableRewards;
  final List<Reward> redeemedRewards;
  final bool showPurchaseAnimation;
  final Reward? newlyPurchasedReward;
  final Function(Reward) onRewardRedeem;

  const RewardsStoreWidget({
    super.key,
    required this.userProfile,
    required this.availableRewards,
    required this.redeemedRewards,
    this.showPurchaseAnimation = false,
    this.newlyPurchasedReward,
    required this.onRewardRedeem,
  });

  @override
  State<RewardsStoreWidget> createState() => _RewardsStoreWidgetState();
}

class _RewardsStoreWidgetState extends State<RewardsStoreWidget> {
  // This widget can now be simpler if the provider handles the state.
  // For this fix, we assume the widget handles its own state as implied by errors.

  @override
  Widget build(BuildContext context) {
    if (widget.availableRewards.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No rewards are available at this time. Check back later!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.availableRewards.length,
      itemBuilder: (context, index) {
        final reward = widget.availableRewards[index];
        final isRedeemed = widget.redeemedRewards.any((r) => r.id == reward.id);
        final canAfford = widget.userProfile.points >= reward.pointsCost;

        return RewardTile(
          reward: reward,
          isRedeemed: isRedeemed,
          canAfford: canAfford,
          onRedeemPressed: () {
            // ERROR FIX: Calling the passed-in function from the parent
            // instead of trying to use a provider here directly.
            widget.onRewardRedeem(reward);
          },
        );
      },
    );
  }
}

// A dedicated widget for displaying a single reward.
class RewardTile extends StatelessWidget {
  final Reward reward;
  final bool isRedeemed;
  final bool canAfford;
  final VoidCallback onRedeemPressed;

  const RewardTile({
    super.key,
    required this.reward,
    required this.isRedeemed,
    required this.canAfford,
    required this.onRedeemPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isActionable = !isRedeemed && canAfford;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isActionable ? 3 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: reward.rarity.color.withAlpha((255 * 0.2).round()),
              child: Icon(Icons.star, color: reward.rarity.color), // Placeholder icon
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: isRedeemed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reward.description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: isActionable ? onRedeemPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isActionable ? reward.rarity.color : Colors.grey,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isRedeemed ? 'Claimed' : '${reward.pointsCost}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isRedeemed)
                    const Text('pts', style: TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}