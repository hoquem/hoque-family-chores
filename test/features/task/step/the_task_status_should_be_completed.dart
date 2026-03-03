import 'package:flutter_test/flutter_test.dart';

/// Usage: the task status should be "completed"
Future<void> theTaskStatusShouldBeCompleted(WidgetTester tester) async {
  expect(find.text('Completed'), findsOneWidget);
}
