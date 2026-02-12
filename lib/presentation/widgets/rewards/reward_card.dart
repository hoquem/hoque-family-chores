import 'package:flutter/material.dart';
import '../../../domain/entities/reward.dart';

/// A card widget displaying a reward with its details and redeem button
class RewardCard extends StatelessWidget {
  final Reward reward;
  final int userStars;
  final VoidCallback onRedeem;

  const RewardCard({
    Key? key,
    required this.reward,
    required this.userStars,
    required this.onRedeem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canAfford = userStars >= reward.costAsInt;
    final isAvailable = reward.isAvailable;

    return Card(
      elevation: canAfford ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: canAfford
            ? BorderSide(color: Colors.amber.shade300, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: canAfford && isAvailable ? onRedeem : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon/Emoji
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: canAfford
                      ? Colors.amber.shade50
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    reward.iconEmoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),

              // Name
              Text(
                reward.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isAvailable ? null : Colors.grey,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Description (if provided)
              if (reward.description != null)
                Text(
                  reward.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              // Star Cost
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: canAfford ? Colors.amber.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '${reward.costAsInt}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: canAfford ? Colors.amber.shade900 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canAfford && isAvailable ? onRedeem : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    foregroundColor: canAfford ? Colors.white : Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _getButtonText(canAfford, isAvailable),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              // Progress bar if can't afford
              if (!canAfford && isAvailable) ...[
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: userStars / reward.costAsInt,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.amber.shade400,
                  ),
                  minHeight: 4,
                ),
                const SizedBox(height: 2),
                Text(
                  '${reward.costAsInt - userStars} more stars',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getButtonText(bool canAfford, bool isAvailable) {
    if (!isAvailable) return 'Unavailable';
    if (!canAfford) return 'Save Up';
    return 'Redeem';
  }
}
