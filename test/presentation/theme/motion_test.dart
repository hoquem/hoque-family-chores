// PRODUCT.md requires reduced-motion support: "the perpetual pulse badge and
// any bounce / elastic easing must be gated". These pin the gate itself, so
// every widget that reaches for it inherits the behaviour.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/theme/motion.dart';

/// Reads [MotionContext.prefersReducedMotion] under the given MediaQuery.
Future<bool> _readUnder(WidgetTester tester, MediaQueryData data) async {
  late bool result;
  await tester.pumpWidget(
    MediaQuery(
      data: data,
      child: Builder(
        builder: (context) {
          result = context.prefersReducedMotion;
          return const SizedBox();
        },
      ),
    ),
  );
  return result;
}

void main() {
  testWidgets('still by default', (tester) async {
    expect(await _readUnder(tester, const MediaQueryData()), isFalse);
  });

  testWidgets('honours the OS reduce-motion setting', (tester) async {
    expect(
      await _readUnder(tester, const MediaQueryData(disableAnimations: true)),
      isTrue,
    );
  });

  testWidgets('honours a screen reader being active', (tester) async {
    // Movement under a screen reader is noise; treat it as reduced motion.
    expect(
      await _readUnder(
          tester, const MediaQueryData(accessibleNavigation: true)),
      isTrue,
    );
  });

  test('the motion vocabulary is ease-out, never elastic or bounce', () {
    // DESIGN.md prohibits elasticOut/bounceOut outright.
    expect(kMotionCurve, isNot(Curves.elasticOut));
    expect(kMotionCurve, isNot(Curves.bounceOut));
    expect(kMotionCurve, Curves.easeOutQuart);
  });

  test('transitions stay in the 150-250ms band', () {
    expect(kMotionDuration.inMilliseconds, inInclusiveRange(150, 250));
  });
}
