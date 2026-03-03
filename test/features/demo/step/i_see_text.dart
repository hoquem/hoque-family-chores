import 'package:flutter_test/flutter_test.dart';

/// Usage: I see {text} text
Future<void> iSeeText(WidgetTester tester, String text) async {
  expect(find.text(text), findsOneWidget);
}
