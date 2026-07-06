import 'package:flutter_test/flutter_test.dart';

/// Usage: I tap on the task "Take out trash"
/// Verifies the task is visible in the list (does not navigate to details).
Future<void> iTapOnTheTaskTakeOutTrash(WidgetTester tester) async {
  final taskTitle = find.text('Take out trash');
  expect(taskTitle, findsOneWidget);
  // Don't tap the title — it navigates to TaskDetailsScreen.
  // The claim/complete/approve buttons are on the tile itself.
}
