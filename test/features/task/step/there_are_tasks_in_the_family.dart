import 'package:flutter_test/flutter_test.dart';

/// Usage: there are tasks in the family
Future<void> thereAreTasksInTheFamily(WidgetTester tester) async {
  // MockTaskRepository already initialises with 3 tasks in family_1.
  await tester.pumpAndSettle();
}
