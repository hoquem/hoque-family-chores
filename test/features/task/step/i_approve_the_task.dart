import 'package:flutter_test/flutter_test.dart';

/// Usage: I approve the task
Future<void> iApproveTheTask(WidgetTester tester) async {
  final approveButton = find.text('Give stars ⭐');
  expect(approveButton, findsOneWidget);
  await tester.tap(approveButton);
  await tester.pumpAndSettle();
}
