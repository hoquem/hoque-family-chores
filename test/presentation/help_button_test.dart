// TASK-453: tapping the ? button opens that screen's help sheet.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/widgets/help_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestBar extends StatelessWidget implements PreferredSizeWidget {
  const _TestBar();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) =>
      AppBar(actions: const [HelpButton(content: kRewardsHelp)]);
}

void main() {
  setUp(() {
    // Seed "seen" so the one-time pulse animation isn't running (a repeating
    // animation would stop pumpAndSettle from ever settling).
    SharedPreferences.setMockInitialValues({'help_hint_seen': true});
  });

  testWidgets('the button opens a sheet with the screen help', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            appBar: _TestBar(),
            body: SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump(); // let the seen flag load

    expect(find.text('Spend your stars 🎁'), findsNothing,
        reason: 'sheet is closed until tapped');

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    expect(find.text('Spend your stars 🎁'), findsOneWidget);
    expect(find.textContaining('Turn stars into fun family things'),
        findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('a first-timer sees the dot; it clears after opening help',
      (tester) async {
    SharedPreferences.setMockInitialValues({}); // never opened help
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(appBar: _TestBar(), body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pump(); // seen flag loads → false

    expect(find.byType(Badge), findsOneWidget, reason: 'the dot is showing');

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.byType(Badge), findsNothing, reason: 'dot cleared once opened');
  });
}
