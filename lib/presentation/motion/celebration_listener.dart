import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/celebration_overlay.dart';
import 'package:hoque_family_chores/presentation/motion/star_award_watcher.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';

/// Bridges the celebration queue to the screen: plays the queue's head as an
/// overlay above [child], advancing when each one finishes. Mounted once,
/// above the tab stack in MainScreen.
class CelebrationListener extends ConsumerWidget {
  const CelebrationListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(starAwardWatcherProvider);
    final queue = ref.watch(celebrationQueueProvider);
    return Stack(
      children: [
        child,
        if (queue.isNotEmpty)
          Positioned.fill(
            child: CelebrationOverlayView(
              // Keyed by the enqueue sequence number: a NEW head (even an
              // identical kind) restarts the show; a mid-show enqueue does
              // not (the head's seq is unchanged).
              key: ValueKey(queue.first.seq),
              kind: queue.first.kind,
              onDone: () => _onCelebrationDone(ref, queue.first.kind),
            ),
          ),
      ],
    );
  }

  /// Advances the queue past the celebration that just finished playing, and
  /// records a review-prompt positive moment for it.
  ///
  /// This runs after the overlay's full envelope (star-burst, headline,
  /// haptic) rather than at `celebrate()`, so the native review sheet — if
  /// [ReviewPromptService] decides to show one — can never cover the
  /// animation the user is meant to see.
  ///
  /// The moment is always recorded, even when another celebration is already
  /// queued behind this one; only *whether the sheet may appear right now*
  /// depends on the queue having drained (`canShowSheetNow`). Gating the
  /// count itself on an empty queue would silently drop moments whenever two
  /// celebrations land back to back — exactly the parents who claim a treat
  /// right after their stars land are the ones this would undercount.
  ///
  /// Only [StarsAwarded] and [TreatRedeemed] count as the "just been
  /// rewarded" moment the review prompt looks for (spec: ask after a
  /// positive moment); [StreakMilestone] is a nice one but not a reward, so
  /// it does not feed the counter.
  void _onCelebrationDone(WidgetRef ref, CelebrationKind kind) {
    final notifier = ref.read(celebrationQueueProvider.notifier);
    notifier.advance();

    final isRewardMoment = kind is StarsAwarded || kind is TreatRedeemed;
    if (!isRewardMoment) return;

    final viewerRole = ref.read(authNotifierProvider).user?.role;
    if (viewerRole == null) return;

    final canShowSheetNow = ref.read(celebrationQueueProvider).isEmpty;
    ref
        .read(reviewPromptServiceProvider)
        .onPositiveMoment(
          viewerRole: viewerRole,
          canShowSheetNow: canShowSheetNow,
        );
  }
}
