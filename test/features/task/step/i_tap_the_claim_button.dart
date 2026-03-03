import 'package:flutter_test/flutter_test.dart';

/// Usage: I tap the claim button
Future<void> iTapTheClaimButton(WidgetTester tester) async {
  final claimButton = find.text('Claim');
  expect(claimButton, findsOneWidget);
  await tester.tap(claimButton);
  await tester.pumpAndSettle();
}
