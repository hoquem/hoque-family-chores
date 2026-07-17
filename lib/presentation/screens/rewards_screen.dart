import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/riverpod_container.dart';
import '../../domain/entities/redemption.dart';
import '../../domain/entities/reward.dart';
import '../../domain/value_objects/user_id.dart';
import '../providers/riverpod/auth_notifier.dart';
import '../providers/riverpod/rewards_notifier.dart';
import '../../utils/logger.dart';
import '../theme/app_tokens.dart';
import 'add_reward_screen.dart';

/// What stars are for.
///
/// Until this existed, points went up forever and bought nothing — a child
/// earned, levelled up, and the loop dead-ended. Rewards are the exit.
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rewards')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final rewards = ref.watch(familyRewardsProvider(user.familyId));
    final owed = ref.watch(outstandingClaimsProvider(user.familyId, user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      floatingActionButton: FloatingActionButton(
        // MainScreen keeps every tab alive in an IndexedStack, so this FAB and
        // the Tasks tab's exist at the same time. Without distinct tags they
        // collide on Flutter's default hero tag and throw.
        heroTag: 'rewards_fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddRewardScreen()),
        ),
        backgroundColor: context.tokens.starGold,
        foregroundColor: context.tokens.ink,
        tooltip: 'Add a reward',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(familyRewardsProvider(user.familyId));
          ref.invalidate(outstandingClaimsProvider(user.familyId, user.id));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _BalanceCard(points: user.points.value),
            const SizedBox(height: 8),
            owed.maybeWhen(
              data: (claims) => claims.isEmpty
                  ? const SizedBox.shrink()
                  : _OwedCard(claims: claims, userId: user.id),
              orElse: () => const SizedBox.shrink(),
            ),
            rewards.when(
              loading: () =>
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )),
              error: (e, stack) {
                // Log the reason. Swallowing it left "Could not load rewards"
                // on screen with nothing anywhere saying why — the first time
                // this failed on a device, the cause (undeployed Firestore
                // rules) was invisible.
                logger.e('[RewardsScreen] rewards stream failed',
                    error: e, stackTrace: stack);
                return _ErrorCard(
                  reason: e.toString(),
                  onRetry: () =>
                      ref.invalidate(familyRewardsProvider(user.familyId)),
                );
              },
              data: (list) => list.isEmpty
                  ? const _EmptyRewards()
                  : Column(
                      children: [
                        for (final reward in list)
                          _RewardTile(reward: reward, balance: user.points.value),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.star, color: t.starGold, size: 32),
            const SizedBox(width: 12),
            Text(
              '$points ⭐',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: t.ink),
            ),
            const Spacer(),
            Text('to spend', style: TextStyle(color: t.inkSoft)),
          ],
        ),
      ),
    );
  }
}

/// Outings the family owes this person. The point of putting it here is that
/// a promise nobody chases is just a lost star.
class _OwedCard extends ConsumerWidget {
  const _OwedCard({required this.claims, required this.userId});

  final List<Redemption> claims;
  final UserId userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              claims.length == 1 ? 'You claimed this' : 'You claimed these',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          for (final claim in claims)
            ListTile(
              leading: Icon(Icons.card_giftcard, color: t.marigoldDeep),
              title: Text(claim.rewardTitle),
              subtitle: Text(
                claim.dueBy == null
                    ? 'Any time'
                    : 'By ${_shortDate(claim.dueBy!)}',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: () => _settle(ref, claim, true),
                    child: const Text('We did it'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: t.brick),
                    onPressed: () => _settle(ref, claim, false),
                    child: const Text('Not yet'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _settle(WidgetRef ref, Redemption claim, bool happened) async {
    await ref.read(settleRedemptionUseCaseProvider)(
      redemption: claim,
      actor: userId,
      happened: happened,
      now: DateTime.now(),
    );
    ref.invalidate(outstandingClaimsProvider(claim.familyId, userId));
    ref.invalidate(authNotifierProvider);
  }

  String _shortDate(DateTime d) => '${d.day}/${d.month}';
}

class _RewardTile extends ConsumerWidget {
  const _RewardTile({required this.reward, required this.balance});

  final Reward reward;
  final int balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final affordable = balance >= reward.cost.value;
    final short = reward.cost.value - balance;

    return Card(
      child: ListTile(
        title: Text(reward.title),
        subtitle: Text(
          affordable
              ? reward.timeframe.label
              // Framed as progress, never as a deficit: PRODUCT.md is explicit
              // that this app is encouraging, not punitive.
              : '$short ⭐ to go · ${reward.timeframe.label}',
          style: TextStyle(color: t.inkSoft),
        ),
        trailing: FilledButton(
          onPressed: affordable ? () => _claim(context, ref) : null,
          child: Text('${reward.cost.value} ⭐'),
        ),
      ),
    );
  }

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    final result = await ref.read(claimRewardUseCaseProvider)(
      reward: reward,
      claimedBy: user.id,
      now: DateTime.now(),
    );

    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: context.tokens.brickDeep,
        ),
      ),
      (_) {
        ref.invalidate(outstandingClaimsProvider(user.familyId, user.id));
        // The balance lives on the user profile, so it has to be re-read or
        // the screen shows stars that are already spent.
        ref.invalidate(authNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claimed! ${reward.title} 🎉'),
            backgroundColor: context.tokens.sproutDeep,
          ),
        );
      },
    );
  }
}

class _EmptyRewards extends StatelessWidget {
  const _EmptyRewards();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.card_giftcard, size: 56, color: t.inkMuted),
          const SizedBox(height: 12),
          Text(
            'No rewards yet',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            // Teaches the feature rather than saying "nothing here": anyone in
            // the family can add one, and the good ones are things you do
            // together.
            'Add something worth working for — a walk in the park, tennis, '
            'a meal out. Anyone in the family can add one.',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry, required this.reason});

  final VoidCallback onRetry;

  /// Shown, not just logged. A parent hitting this can read it to me down the
  /// phone; "Could not load rewards" on its own is unactionable for everyone.
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: context.tokens.brick),
          const SizedBox(height: 8),
          const Text('Could not load rewards'),
          const SizedBox(height: 8),
          Text(
            reason,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.tokens.inkSoft),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
