import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Icon or avatar for a notification tile.
///
/// Shows the actor's photo when available, otherwise a type-aware icon on a
/// tinted circle. The photo path should be cached; this widget does not fetch
/// from the network on every rebuild.
class NotificationIcon extends StatelessWidget {
  final bool isRead;
  final String? type;
  final String? imageUrl;

  const NotificationIcon({
    super.key,
    required this.isRead,
    this.type,
    this.imageUrl,
  });

  IconData _icon() => switch (type) {
        'taskCreated' => Icons.add_task_outlined,
        'taskClaimed' => Icons.person_outline,
        'taskCompleted' => Icons.check_circle_outline,
        'taskApproved' => Icons.star_outline,
        'taskSentBack' => Icons.refresh,
        'rewardClaimed' => Icons.card_giftcard,
        'rewardSettled' => Icons.done_all,
        _ => isRead ? Icons.notifications_none : Icons.notifications_active,
      };

  Color _bgColor(BuildContext context) {
    return switch (type) {
      'taskApproved' => context.tokens.starGold.withValues(alpha: 0.12),
      'rewardClaimed' || 'rewardSettled' => context.tokens.sprout.withValues(alpha: 0.12),
      'taskSentBack' => context.tokens.brick.withValues(alpha: 0.12),
      _ => isRead
          ? context.tokens.inkMuted.withValues(alpha: 0.12)
          : context.tokens.amberWarn.withValues(alpha: 0.12),
    };
  }

  Color _fgColor(BuildContext context) {
    return switch (type) {
      'taskApproved' => context.tokens.starGold,
      'rewardClaimed' || 'rewardSettled' => context.tokens.sproutDeep,
      'taskSentBack' => context.tokens.brickDeep,
      _ => isRead ? context.tokens.inkMuted : context.tokens.amberWarnDeep,
    };
  }

  @override
  Widget build(BuildContext context) {
    final photo = imageUrl;
    if (photo != null && photo.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(photo),
        onBackgroundImageError: (_, __) {},
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _bgColor(context),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _icon(),
        size: 20,
        color: _fgColor(context),
      ),
    );
  }
}
