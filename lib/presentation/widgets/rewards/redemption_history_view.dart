import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/reward_redemption.dart';
import '../../../domain/value_objects/family_id.dart';
import '../../../domain/value_objects/user_id.dart';
import '../../providers/riverpod/rewards_notifier.dart';
import 'package:intl/intl.dart';

/// Widget displaying user's redemption history
class RedemptionHistoryView extends ConsumerWidget {
  final FamilyId familyId;
  final UserId userId;

  const RedemptionHistoryView({
    Key? key,
    required this.familyId,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final redemptionsAsync = ref.watch(
      userRedemptionsNotifierProvider(familyId, userId),
    );

    return redemptionsAsync.when(
      data: (redemptions) {
        if (redemptions.isEmpty) {
          return _buildEmptyState(context);
        }

        // Group by month
        final grouped = <String, List<RewardRedemption>>{};
        for (final redemption in redemptions) {
          final monthYear = DateFormat('MMMM yyyy').format(redemption.requestedAt);
          grouped.putIfAbsent(monthYear, () => []).add(redemption);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userRedemptionsNotifierProvider(familyId, userId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length * 2, // Header + items for each month
            itemBuilder: (context, index) {
              if (index.isEven) {
                final monthIndex = index ~/ 2;
                final monthYear = grouped.keys.elementAt(monthIndex);
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    monthYear,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                );
              } else {
                final monthIndex = index ~/ 2;
                final monthYear = grouped.keys.elementAt(monthIndex);
                final monthRedemptions = grouped[monthYear]!;
                
                return Column(
                  children: monthRedemptions.map((redemption) {
                    return _RedemptionListItem(redemption: redemption);
                  }).toList(),
                );
              }
            },
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
            Text('Error loading history: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(userRedemptionsNotifierProvider(familyId, userId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No redemptions yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Start redeeming rewards to see your history here!',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RedemptionListItem extends StatelessWidget {
  final RewardRedemption redemption;

  const _RedemptionListItem({
    Key? key,
    required this.redemption,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  redemption.rewardIconEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    redemption.rewardName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${redemption.starCost}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        DateFormat('MMM d').format(redemption.requestedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (redemption.rejectionReason != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        redemption.rejectionReason!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Status Badge
            _buildStatusBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final icon = _getStatusIcon();
    final color = _getStatusColor();
    final text = redemption.status.displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (redemption.status) {
      case RedemptionStatus.pending:
        return Icons.hourglass_empty;
      case RedemptionStatus.approved:
        return Icons.check_circle;
      case RedemptionStatus.rejected:
        return Icons.cancel;
    }
  }

  Color _getStatusColor() {
    switch (redemption.status) {
      case RedemptionStatus.pending:
        return Colors.orange;
      case RedemptionStatus.approved:
        return Colors.green;
      case RedemptionStatus.rejected:
        return Colors.red;
    }
  }
}
