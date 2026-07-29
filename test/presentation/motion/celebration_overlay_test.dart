import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/celebration_overlay.dart';
import 'package:hoque_family_chores/presentation/motion/star_burst_painter.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

Future<void> _pump(WidgetTester tester, CelebrationKind kind,
    {bool reducedMotion = false, VoidCallback? onDone}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: appLightTheme,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: Scaffold(
          body: CelebrationOverlayView(kind: kind, onDone: onDone ?? () {}),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('stars awarded shows +N and finishes', (tester) async {
    var done = false;
    await _pump(tester, const StarsAwarded(10), onDone: () => done = true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('+10'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(done, isTrue, reason: 'the overlay must end and report completion');
  });

  testWidgets('treat redeemed shows the treat name, no +N', (tester) async {
    await _pump(tester, const TreatRedeemed('Movie night'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Movie night'), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  });

  testWidgets('streak milestone shows the day count', (tester) async {
    await _pump(tester, const StreakMilestone(7));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('7-day streak'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  });

  testWidgets('reduced motion: information without the burst', (tester) async {
    var done = false;
    await _pump(tester, const StarsAwarded(5),
        reducedMotion: true, onDone: () => done = true);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('+5'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is StarBurstPainter),
      findsNothing,
      reason: 'reduced motion renders the static variant — no burst painter',
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(done, isTrue);
  });
}
