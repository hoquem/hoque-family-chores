import 'package:flutter_test/flutter_test.dart';

/// Usage: the task status should be "assigned"
Future<void> theTaskStatusShouldBeAssigned(WidgetTester tester) async {
  expect(find.text('Assigned'), findsOneWidget);
}
