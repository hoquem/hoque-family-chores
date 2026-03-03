import 'package:flutter_test/flutter_test.dart';

/// Usage: I should see {text} text
Future<void> iShouldSeeText(WidgetTester tester, String text) async {
  expect(find.text(text), findsOneWidget);
}
