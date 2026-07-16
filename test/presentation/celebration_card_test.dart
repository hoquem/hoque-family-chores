// The celebration is the app's loudest moment, so it is the one that most
// needs gating: PRODUCT.md requires reduced-motion support, and DESIGN.md
// prohibits elastic easing outright.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/home/celebration_card.dart';

Future<void> _pump(WidgetTester tester, {required bool reducedMotion}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: appLightTheme,
      // Inside MaterialApp: it builds its own MediaQuery from the window and
      // would discard an outer override.
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: const Scaffold(body: CelebrationCard()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('does not animate under reduced motion', (tester) async {
    await _pump(tester, reducedMotion: true);

    expect(find.byType(TweenAnimationBuilder<double>), findsNothing,
        reason: 'reduced motion means the celebration arrives already there');

    // The information must survive the gate: still a celebration, just still.
    expect(find.text('All done for today! 🎉'), findsOneWidget);

    // Nothing should be driving a frame.
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('animates by default', (tester) async {
    await _pump(tester, reducedMotion: false);
    expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
  });

  testWidgets('the decorative emoji is not announced on its own',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, reducedMotion: true);

    // The big 🎉 is decoration; the heading already says "All done for today!".
    // Left alone a screen reader announces it as a second, contentless node
    // ("party popper"), so it is excluded rather than labelled.
    expect(find.bySemanticsLabel('🎉'), findsNothing,
        reason: 'the decorative emoji should not be its own semantics node');

    // The meaning still has to be announced.
    expect(find.bySemanticsLabel(RegExp(r'all done', caseSensitive: false)),
        findsWidgets);
    handle.dispose();
  });
}
