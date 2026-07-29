import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/celebration_overlay.dart';

/// Bridges the celebration queue to the screen: plays the queue's head as an
/// overlay above [child], advancing when each one finishes. Mounted once,
/// above the tab stack in MainScreen.
class CelebrationListener extends ConsumerWidget {
  const CelebrationListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              onDone: () =>
                  ref.read(celebrationQueueProvider.notifier).advance(),
            ),
          ),
      ],
    );
  }
}
