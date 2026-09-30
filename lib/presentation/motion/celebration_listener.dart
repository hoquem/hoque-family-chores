import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/celebration_overlay.dart';
import 'package:hoque_family_chores/presentation/motion/star_award_watcher.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/review_prompt_pending_signal.dart';

/// Bridges the celebration queue to the screen: plays the queue's head as an
/// overlay above [child], advancing when each one finishes. Mounted once,
/// above the tab stack in MainScreen.
///
/// Also the idle point for a review-prompt moment that had nowhere safe to
/// offer its own sheet (an approval — see `review_prompt_positive_moment.dart`):
/// this is where [ReviewPromptPendingSignal] is watched and, once a
/// genuinely safe moment turns up, evaluated. A `ConsumerStatefulWidget`
/// rather than the plain `ConsumerWidget` this used to be, so that check can
/// debounce itself with a private field instead of another provider.
class CelebrationListener extends ConsumerStatefulWidget {
  const CelebrationListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CelebrationListener> createState() =>
      _CelebrationListenerState();
}

class _CelebrationListenerState extends ConsumerState<CelebrationListener> {
  /// How long to wait past a route change before trusting it — a page pop
  /// changes `ModalRoute.isCurrent` immediately, before its exit animation
  /// has actually finished, so offering the instant that flips would show
  /// the system dialog over a screen still visibly sliding away.
  static const _settleDelay = Duration(milliseconds: 300);

  bool _deferredCheckScheduled = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(starAwardWatcherProvider);
    final queue = ref.watch(celebrationQueueProvider);
    final pending = ref.watch(reviewPromptPendingSignalProvider);

    // ModalRoute.of registers a dependency on this route's current-ness, so
    // this widget rebuilds automatically when a dialog/bottom-sheet/pushed
    // screen on top opens or closes — no polling needed for that part.
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    if (pending &&
        queue.isEmpty &&
        isCurrentRoute &&
        !_deferredCheckScheduled) {
      _scheduleDeferredOffer();
    }

    return Stack(
      children: [
        widget.child,
        if (queue.isNotEmpty)
          Positioned.fill(
            child: CelebrationOverlayView(
              // Keyed by the enqueue sequence number: a NEW head (even an
              // identical kind) restarts the show; a mid-show enqueue does
              // not (the head's seq is unchanged).
              key: ValueKey(queue.first.seq),
              kind: queue.first.kind,
              onDone: () => _onCelebrationDone(queue.first.kind),
            ),
          ),
      ],
    );
  }

  /// Waits [_settleDelay], then — only if the moment is *still* safe (the
  /// queue could have gained a new celebration, or a dialog could have
  /// opened, in the meantime) — clears [ReviewPromptPendingSignal] and asks
  /// [ReviewPromptService.offerIfDue] to decide against the current gate.
  ///
  /// Not still safe: does nothing and leaves the signal set, so the next
  /// build() that finds a safe moment schedules another check. Nothing is
  /// lost, just deferred again.
  void _scheduleDeferredOffer() {
    _deferredCheckScheduled = true;
    Future<void>.delayed(_settleDelay, () {
      _deferredCheckScheduled = false;
      if (!mounted) return;

      final stillSafe =
          ref.read(celebrationQueueProvider).isEmpty &&
          (ModalRoute.of(context)?.isCurrent ?? true);
      if (!stillSafe) return;

      ref.read(reviewPromptPendingSignalProvider.notifier).clear();
      final viewerRole = ref.read(authNotifierProvider).user?.role;
      if (viewerRole == null) return;
      ref.read(reviewPromptServiceProvider).offerIfDue(viewerRole);
    });
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
  void _onCelebrationDone(CelebrationKind kind) {
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
