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

// Snappy tier (spec §1). Everyday actions only — the bouncy tier is defined
// inside lib/presentation/motion/ and must never appear here (see
// motion_carveout_test.dart). Existing call sites keep [kMotionDuration];
// new snappy-tier work uses the named consts below.

/// Press feedback: near-instant, so taps feel wired to the finger.
const Duration kMotionTapDuration = Duration(milliseconds: 120);

/// Entrances take the top of the 150-250ms budget: arrive gently.
const Duration kMotionEntranceDuration = Duration(milliseconds: 250);

/// Exits are faster than entrances: things leave quickly, arrive gently.
const Duration kMotionExitDuration = Duration(milliseconds: 150);

/// Tap easing: ease-out, so feedback lands immediately and settles.
const Curve kMotionTapCurve = Curves.easeOutCubic;

/// Entrance easing: ease-out — arriving elements decelerate into place.
const Curve kMotionEntranceCurve = Curves.easeOutCubic;

/// Exit easing: ease-in — leaving elements accelerate away, pairing with
/// [kMotionExitDuration] (leave quickly, arrive gently).
const Curve kMotionExitCurve = Curves.easeInCubic;

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
