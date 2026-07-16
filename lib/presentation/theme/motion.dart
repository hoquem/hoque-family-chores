import 'package:flutter/material.dart';

/// Motion vocabulary for the "Fridge Door" system (DESIGN.md §5).
///
/// Motion conveys state — progress, completion, feedback — never decoration.

/// The standard transition duration. 150-250ms: users are in a task, not
/// waiting for choreography.
const Duration kMotionDuration = Duration(milliseconds: 220);

/// The standard easing. Ease-out, exponential. Never bounce, never elastic:
/// DESIGN.md prohibits `Curves.elasticOut` / `Curves.bounceOut`.
const Curve kMotionCurve = Curves.easeOutQuart;

extension MotionContext on BuildContext {
  /// Whether the platform has asked for reduced motion.
  ///
  /// PRODUCT.md makes this a product requirement: animation conveys state, and
  /// a user who has turned motion off must still get the state — just without
  /// the movement. Gate the animation, never the information.
  ///
  /// Two signals, because they mean different things and both want stillness:
  ///
  /// - [MediaQueryData.disableAnimations] is the actual reduce-motion setting
  ///   (iOS "Reduce Motion", Android "Remove animations"). This is the one
  ///   DESIGN.md's Flutter note should have named.
  /// - [MediaQueryData.accessibleNavigation] means a screen reader is driving.
  ///   Movement under a screen reader is noise at best and disruptive at worst.
  bool get prefersReducedMotion {
    final mq = MediaQuery.of(this);
    return mq.disableAnimations || mq.accessibleNavigation;
  }
}
