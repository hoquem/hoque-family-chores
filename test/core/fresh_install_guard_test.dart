import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/fresh_install_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first launch signs out any keychain-persisted session', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var signOutCalls = 0;

    await FreshInstallGuard.run(
      prefs: prefs,
      signOut: () async => signOutCalls++,
    );

    expect(signOutCalls, 1,
        reason: 'iOS keychain survives app deletion; a fresh install must '
            'not resurrect the old session');
  });

  test('subsequent launches leave the session alone', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var signOutCalls = 0;
    Future<void> signOut() async => signOutCalls++;

    await FreshInstallGuard.run(prefs: prefs, signOut: signOut);
    await FreshInstallGuard.run(prefs: prefs, signOut: signOut);
    await FreshInstallGuard.run(prefs: prefs, signOut: signOut);

    expect(signOutCalls, 1);
  });
}
