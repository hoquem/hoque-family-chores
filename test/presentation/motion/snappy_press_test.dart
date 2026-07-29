import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/motion/snappy_press.dart';

void main() {
  testWidgets('builds normally and has a GestureDetector', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SnappyPress(
          onTap: () {},
          child: Container(width: 100, height: 100, color: Colors.blue),
        ),
      ),
    );

    expect(find.byType(SnappyPress), findsOneWidget);
    expect(find.byType(GestureDetector), findsOneWidget);
    expect(find.byType(Container), findsOneWidget);
  });

  testWidgets('reduced motion: no Transform wrapper', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SnappyPress(
            onTap: () {},
            child: Container(width: 100, height: 100, color: Colors.blue),
          ),
        ),
      ),
    );

    // Under reduced motion the child is returned directly — no Transform wrapper.
    expect(find.byType(Transform), findsNothing);
  });

  testWidgets('onTap callback fires', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SnappyPress(
          onTap: () => tapped = true,
          child: Container(width: 100, height: 100, color: Colors.blue),
        ),
      ),
    );

    await tester.tap(find.byType(Container));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
