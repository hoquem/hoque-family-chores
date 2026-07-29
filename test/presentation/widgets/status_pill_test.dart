import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/status_pill.dart';

void main() {
  testWidgets('cross-fades when status changes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appLightTheme,
        home: Scaffold(
          body: StatusPill(
            status: TaskStatus.available,
            label: 'Up for grabs',
          ),
        ),
      ),
    );

    // First frame shows the available pill.
    expect(find.text('Up for grabs'), findsOneWidget);

    // Change status.
    await tester.pumpWidget(
      MaterialApp(
        theme: appLightTheme,
        home: Scaffold(
          body: StatusPill(
            status: TaskStatus.assigned,
            label: 'Assigned',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Mid-cross-fade: both old and new are in the tree (AnimatedSwitcher
    // stack).
    expect(find.text('Up for grabs'), findsOneWidget);
    expect(find.text('Assigned'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Up for grabs'), findsNothing);
    expect(find.text('Assigned'), findsOneWidget);
  });

  testWidgets('reduced motion: instant snap, no AnimatedSwitcher fade', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appLightTheme,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: StatusPill(
              status: TaskStatus.available,
              label: 'Up for grabs',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Up for grabs'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: appLightTheme,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: StatusPill(
              status: TaskStatus.assigned,
              label: 'Assigned',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Instant swap — no lingering old text.
    expect(find.text('Up for grabs'), findsNothing);
    expect(find.text('Assigned'), findsOneWidget);
  });
}
