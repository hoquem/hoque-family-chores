import 'package:flutter_test/flutter_test.dart';
import '../test_helpers.dart';

/// Usage: I am a parent user
Future<void> iAmAParentUser(WidgetTester tester) async {
  await switchUser(tester, testParentUser);
}
