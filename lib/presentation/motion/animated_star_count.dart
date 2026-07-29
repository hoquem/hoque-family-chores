import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/motion.dart';

/// A star balance that rolls to its new value instead of teleporting.
///
/// Uses the snappy state tier (220ms, easeOutQuart). Under reduced motion the
/// target is shown instantly.
class AnimatedStarCount extends StatefulWidget {
  const AnimatedStarCount(this.count, {super.key});

  final int count;

  @override
  State<AnimatedStarCount> createState() => _AnimatedStarCountState();
}

class _AnimatedStarCountState extends State<AnimatedStarCount> {
  int? _previous;

  @override
  Widget build(BuildContext context) {
    if (context.prefersReducedMotion) {
      return Text('${widget.count} ⭐');
    }
    final begin = _previous ?? widget.count;
    final end = widget.count;
    _previous = widget.count;
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: begin, end: end),
      duration: kMotionDuration,
      curve: kMotionCurve,
      builder: (_, value, __) => Text('$value ⭐'),
    );
  }
}
