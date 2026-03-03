import 'package:flutter_test/flutter_test.dart';

/// Usage: I tap on the task "Take out trash"
Future<void> iTapOnTheTaskTakeOutTrash(WidgetTester tester) async {
  final taskTile = find.text('Take out trash');
  expect(taskTile, findsOneWidget);
  await tester.tap(taskTile);
  await tester.pumpAndSettle();
}
