import 'package:flutter_test/flutter_test.dart';
import '../test_helpers.dart';

/// Usage: I am logged in as a parent
Future<void> iAmLoggedInAsAParent(WidgetTester tester) async {
  await switchUser(tester, testParentUser);
}
