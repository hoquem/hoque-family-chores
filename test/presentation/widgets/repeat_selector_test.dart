import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/services/recurrence.dart';
import 'package:hoque_family_chores/presentation/widgets/repeat_selector.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows the four presets and reports selection', (tester) async {
    RepeatPreset? chosen;
    await tester.pumpWidget(wrap(RepeatSelector(
      value: RepeatPreset.never,
      visible: true,
      onChanged: (p) => chosen = p,
    )));

    expect(find.text('Repeat'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<RepeatPreset>));
    await tester.pumpAndSettle();

    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);

    await tester.tap(find.text('Weekly').last);
    await tester.pumpAndSettle();

    expect(chosen, RepeatPreset.weekly);
  });

  testWidgets('renders nothing when hidden (children)', (tester) async {
    await tester.pumpWidget(wrap(RepeatSelector(
      value: RepeatPreset.never,
      visible: false,
      onChanged: (_) {},
    )));

    expect(find.text('Repeat'), findsNothing);
  });
}
