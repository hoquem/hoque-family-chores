import 'package:flutter_test/flutter_test.dart';
import '../test_helpers.dart';

/// Usage: I am logged in as a child
Future<void> iAmLoggedInAsAChild(WidgetTester tester) async {
  await switchUser(tester, testChildUser);
}
