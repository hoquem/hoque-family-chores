import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:hoque_family_chores/main.dart' as app;
import 'package:hoque_family_chores/presentation/screens/main_screen.dart';

/// Pumps until [finder] matches, failing after [timeout].
///
/// :param tester: the widget tester driving the app.
/// :param finder: the finder to wait for.
/// :param timeout: maximum time to wait before failing.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'email/password sign-up creates a profile doc and lands on MainScreen',
    (tester) async {
      app.main();
      await pumpUntilFound(
        tester,
        find.text("Don't have an account? Sign Up"),
        timeout: const Duration(seconds: 60),
      );

      await tester.tap(find.text("Don't have an account? Sign Up"));
      await pumpUntilFound(tester, find.text('Register'));

      final email =
          'smoke.${DateTime.now().millisecondsSinceEpoch}@example.com';
      const password = 'Sm0ke-test!';
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Smoke Tester');
      await tester.enterText(fields.at(1), email);
      await tester.enterText(fields.at(2), password);
      await tester.enterText(fields.at(3), password);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));

      // Auth + profile-doc creation + navigation via authStateChanges.
      await pumpUntilFound(
        tester,
        find.byType(MainScreen),
        timeout: const Duration(seconds: 60),
      );

      final user = FirebaseAuth.instance.currentUser;
      expect(user, isNotNull, reason: 'sign-up should leave a signed-in user');
      expect(user!.email, email);

      // The bug fixed in 20862ae: this doc was never created because
      // FamilyId('') threw inside InitializeUserDataUseCase.
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      expect(doc.exists, isTrue,
          reason: 'profile doc must be created on sign-up');
      expect(doc.data()!['familyId'], '',
          reason: 'fresh user should carry the FamilyId.empty sentinel');

      // Let MainScreen sit with the family-less profile: any unguarded
      // family-scoped read would throw/crash here.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(find.byType(MainScreen), findsOneWidget);

      // Cleanup: remove the throwaway account (doc first, then auth user).
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
      } catch (_) {
        // Rules may forbid self-delete; orphan doc is acceptable for smoke.
      }
      await user.delete();
    },
  );
}
