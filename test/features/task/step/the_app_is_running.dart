import 'package:flutter_test/flutter_test.dart';
import '../test_helpers.dart';

/// Usage: the app is running
Future<void> theAppIsRunning(WidgetTester tester) async {
  TaskTestContext.reset();
  await pumpTestApp(tester);
}
