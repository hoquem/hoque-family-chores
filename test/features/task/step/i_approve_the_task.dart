import 'package:flutter_test/flutter_test.dart';

/// Usage: I approve the task
Future<void> iApproveTheTask(WidgetTester tester) async {
  final approveButton = find.text('Approve');
  expect(approveButton, findsOneWidget);
  await tester.tap(approveButton);
  await tester.pumpAndSettle();
}
