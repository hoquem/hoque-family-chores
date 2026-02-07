// lib/presentation/widgets/rewards_store_widget.dart

import 'package:flutter/material.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';

class RewardsStoreWidget extends StatefulWidget {
  final User user;

  // These properties were in your gamification screen; they can be passed here if needed
  final List<Reward> availableRewards;
  final List<Reward> redeemedRewards;
  final bool showPurchaseAnimation;
  final Reward? newlyPurchasedReward;
  final Function(Reward) onRewardRedeem;

  const RewardsStoreWidget({
    super.key,
    required this.user,
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
        final canAfford = widget.user.points.value >= reward.pointsCost.value;

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
              backgroundColor: Colors.blue.withAlpha((255 * 0.2).round()),
              child: const Icon(Icons.star, color: Colors.blue), // Placeholder icon
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.name,
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
                backgroundColor: isActionable ? Colors.blue : Colors.grey,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isRedeemed ? 'Claimed' : '${reward.pointsCost.value}',
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
