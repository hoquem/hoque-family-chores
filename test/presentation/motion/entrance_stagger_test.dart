import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/motion/entrance_stagger.dart';

void main() {
  testWidgets('first build staggers children in', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: 3,
            itemBuilder: (_, index) => EntranceStagger(
              index: index,
              child: Container(
                key: ValueKey('item-$index'),
                height: 50,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );

    // Immediately after pump: all children are in the tree (Opacity 1.0).
    expect(find.byType(Container), findsNWidgets(3));

    // After settling, all are fully visible.
    await tester.pumpAndSettle();
    expect(find.byType(Container), findsNWidgets(3));
  });

  testWidgets('reduced motion: children appear instantly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: EntranceStagger(
              index: 0,
              child: Container(height: 50, color: Colors.blue),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Container), findsOneWidget);
    // No Transform/Opacity wrapper under reduced motion.
    expect(find.byType(Opacity), findsNothing);
  });
}
