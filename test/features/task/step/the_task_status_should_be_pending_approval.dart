import 'package:flutter_test/flutter_test.dart';

/// Usage: the task status should be "pending_approval"
Future<void> theTaskStatusShouldBePendingApproval(WidgetTester tester) async {
  expect(find.text('Pending Approval'), findsOneWidget);
}
