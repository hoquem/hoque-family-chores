import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/motion.dart';

/// Shown when every mission of the day is finished.
///
/// The app's one loud moment (the One-Celebration Rule), so it is also the one
/// that most needs gating: the pop is a reward, not information. Under reduced
/// motion the card arrives already at rest — the celebration still happens, it
/// just doesn't move.
class CelebrationCard extends StatelessWidget {
  const CelebrationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // The big emoji is decoration: the heading below already says "All done for
    // today!", so announcing it again as "party popper" adds a contentless stop
    // for a screen-reader user.
    const emoji = ExcludeSemantics(
      child: Text('🎉', style: TextStyle(fontSize: 56)),
    );

    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (context.prefersReducedMotion)
              emoji
            else
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 600),
                // easeOutQuart, not elasticOut: DESIGN.md prohibits elastic and
                // bounce easing. The pop still lands, it just doesn't wobble.
                curve: kMotionCurve,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: emoji,
              ),
            const SizedBox(height: 12),
            Text(
              'All done for today! 🎉',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text('Amazing work!', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
