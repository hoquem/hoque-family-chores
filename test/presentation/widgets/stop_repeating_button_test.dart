import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/widgets/stop_repeating_button.dart';

void main() {
  testWidgets('confirms before calling onStop', (tester) async {
    var stopped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StopRepeatingButton(
          onStop: () async {
            stopped = true;
          },
        ),
      ),
    ));

    await tester.tap(find.text('Stop repeating'));
    await tester.pumpAndSettle();
    // The confirm dialog is asking, not yet acting.
    expect(stopped, isFalse);
    expect(find.text('Stop this recurring chore?'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();

    expect(stopped, isTrue);
    expect(find.text('Recurring series stopped'), findsOneWidget);
  });

  testWidgets('cancelling the dialog does nothing', (tester) async {
    var stopped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StopRepeatingButton(
          onStop: () async {
            stopped = true;
          },
        ),
      ),
    ));

    await tester.tap(find.text('Stop repeating'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(stopped, isFalse);
  });

  testWidgets('a failing onStop shows the error and no success snackbar',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StopRepeatingButton(
          onStop: () async => throw Exception('boom'),
        ),
      ),
    ));

    await tester.tap(find.text('Stop repeating'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();

    expect(find.text('Recurring series stopped'), findsNothing);
    expect(find.textContaining('Could not stop'), findsOneWidget);
  });
}
