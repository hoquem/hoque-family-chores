import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: a success message should be displayed
Future<void> aSuccessMessageShouldBeDisplayed(WidgetTester tester) async {
  expect(find.byType(SnackBar), findsOneWidget);
}
