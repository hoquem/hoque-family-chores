import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/star_burst_painter.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/theme/motion.dart';

/// Plays one celebration (spec §2): star-burst + headline + one haptic, then
/// calls [onDone]. One-shot by construction — the controller never repeats.
class CelebrationOverlayView extends StatefulWidget {
  const CelebrationOverlayView({super.key, required this.kind, required this.onDone});

  final CelebrationKind kind;
  final VoidCallback onDone;

  @override
  State<CelebrationOverlayView> createState() => _CelebrationOverlayViewState();
}

class _CelebrationOverlayViewState extends State<CelebrationOverlayView>
    with SingleTickerProviderStateMixin {
  static const _envelope = Duration(milliseconds: 700);
  late final AnimationController _controller;

  String get _headline => switch (widget.kind) {
        StarsAwarded(:final count) => '+$count ⭐',
        TreatRedeemed(:final treatName) => '$treatName 🎉',
        StreakMilestone(:final days) => '$days-day streak! 🔥',
      };

  String get _announcement => switch (widget.kind) {
        StarsAwarded(:final count) => 'You earned $count stars!',
        TreatRedeemed(:final treatName) => 'You got $treatName!',
        StreakMilestone(:final days) => '$days day streak!',
      };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _envelope);
    // Post-frame: prefersReducedMotion needs MediaQuery, unavailable in initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.announce(_announcement, TextDirection.ltr);
      if (context.prefersReducedMotion) {
        // Static variant: the information, a beat to read it, no movement.
        Future<void>.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) widget.onDone();
        });
      } else {
        HapticFeedback.mediumImpact();
        _controller.forward().whenComplete(widget.onDone);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = context.prefersReducedMotion;
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!.copyWith(
          color: context.tokens.ink,
          fontWeight: FontWeight.bold,
        );

    if (reduced) {
      return IgnorePointer(
        child: Center(child: Text(_headline, style: headlineStyle)),
      );
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final pop = kCelebrationOvershoot
              .transform(Interval(0.0, 0.55).transform(t));
          final fadeOut = t < 0.8 ? 1.0 : 1.0 - (t - 0.8) / 0.2;
          return Opacity(
            opacity: fadeOut.clamp(0.0, 1.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // RepaintBoundary per spec §4: the burst repaints every frame;
                // nothing outside it should.
                RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(320, 320),
                    painter: StarBurstPainter(
                      progress: t,
                      colors: [
                        context.tokens.starGold,
                        context.tokens.sprout,
                        context.tokens.brick,
                      ],
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.6 + 0.4 * pop,
                  child: Text(_headline, style: headlineStyle),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
