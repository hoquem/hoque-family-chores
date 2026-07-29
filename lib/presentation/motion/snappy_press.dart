import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/motion.dart';

/// Snappy press feedback: ~4% scale-down on pointer down, restored on up.
///
/// Uses the snappy tap tier (120ms, easeOutCubic). Under reduced motion the
/// child is returned unchanged — the feedback is decorative, not informational.
class SnappyPress extends StatefulWidget {
  const SnappyPress({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<SnappyPress> createState() => _SnappyPressState();
}

class _SnappyPressState extends State<SnappyPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kMotionTapDuration,
      value: 1.0,
    );
    _animation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: kMotionTapCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.reverse(from: 1.0);
  void _onTapUp(TapUpDetails _) => _controller.forward();
  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    if (context.prefersReducedMotion) {
      return GestureDetector(
        onTap: widget.onTap,
        child: widget.child,
      );
    }
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, __) => Transform.scale(
          scale: _animation.value,
          child: widget.child,
        ),
      ),
    );
  }
}
