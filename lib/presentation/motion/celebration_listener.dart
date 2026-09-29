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
  /// — once nothing else is queued behind it — offers a store-review ask.
  ///
  /// This runs after the overlay's full envelope (star-burst, headline,
  /// haptic) rather than at `celebrate()`, so the native review sheet can
  /// never cover the animation the user is meant to see. Checking
  /// `queue.isEmpty` after [advance] (not before) matters too: a second
  /// celebration queued behind this one must play before we ever consider
  /// interrupting with a system dialog.
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
    if (ref.read(celebrationQueueProvider).isNotEmpty) return;

    final viewerRole = ref.read(authNotifierProvider).user?.role;
    if (viewerRole == null) return;

    ref
        .read(reviewPromptServiceProvider)
        .onPositiveMoment(viewerRole: viewerRole);
  }
}
