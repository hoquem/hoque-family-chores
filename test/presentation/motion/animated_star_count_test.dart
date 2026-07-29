import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/motion/animated_star_count.dart';

void main() {
  testWidgets('shows target on first build', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedStarCount(5),
      ),
    );

    expect(find.text('5 ⭐'), findsOneWidget);
  });

  testWidgets('rolls when count changes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedStarCount(5),
      ),
    );
    await tester.pumpAndSettle();

    // Change count.
    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedStarCount(10),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Should show an intermediate value (not yet 10).
    final text = tester.widget<Text>(find.byType(Text)).data;
    expect(text, isNot('10 ⭐'));

    await tester.pumpAndSettle();
    expect(find.text('10 ⭐'), findsOneWidget);
  });

  testWidgets('reduced motion: instant target', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: AnimatedStarCount(10),
        ),
      ),
    );

    // No animation — instant target.
    expect(find.text('10 ⭐'), findsOneWidget);
  });
}
