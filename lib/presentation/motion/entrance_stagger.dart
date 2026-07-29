import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/motion.dart';

/// Snappy entrance animation: opacity 0→1 and slight upward slide.
///
/// Runs once per widget lifetime; rebuilds do not re-fire. Under reduced motion
/// the child is returned directly.
class EntranceStagger extends StatefulWidget {
  const EntranceStagger({
    super.key,
    required this.index,
    required this.child,
  });

  /// Index used to compute stagger delay. Each item starts slightly after the
  /// previous one for a cascading entrance effect.
  final int index;
  final Widget child;

  @override
  State<EntranceStagger> createState() => _EntranceStaggerState();
}

class _EntranceStaggerState extends State<EntranceStagger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kMotionEntranceDuration,
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: kMotionEntranceCurve),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: kMotionEntranceCurve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.prefersReducedMotion) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: _opacity.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: _slide.value,
          child: widget.child,
        ),
      ),
    );
  }
}
