import 'package:shared_preferences/shared_preferences.dart';

/// Ensures a freshly installed app starts signed out.
///
/// Firebase Auth stores its session in the iOS keychain, which survives app
/// deletion. Without this guard a reinstall silently resurrects the old
/// session and boots into the main screen instead of the login screen.
class FreshInstallGuard {
  static const _hasLaunchedKey = 'has_launched_before';

  FreshInstallGuard._();

  /// Signs out via [signOut] if this is the first launch since install,
  /// then marks the install as launched.
  static Future<void> run({
    required SharedPreferences prefs,
    required Future<void> Function() signOut,
  }) async {
    if (prefs.getBool(_hasLaunchedKey) ?? false) return;
    await signOut();
    await prefs.setBool(_hasLaunchedKey, true);
  }
}
