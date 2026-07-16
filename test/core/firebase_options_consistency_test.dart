import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/firebase_options.dart';

/// Extracts a value from the iOS GoogleService-Info.plist by key.
String _plistValue(String plist, String key) {
  final match = RegExp('<key>$key</key>\\s*<string>([^<]+)</string>')
      .firstMatch(plist);
  if (match == null) {
    fail('ios/Runner/GoogleService-Info.plist has no $key entry');
  }
  return match.group(1)!;
}

void main() {
  // The native iOS layer initializes Firebase from the bundled plist while
  // the Dart layer passes DefaultFirebaseOptions. If they disagree, startup
  // dies with core/duplicate-app ("[DEFAULT] already exists"). This test
  // pins the two sources of truth together.
  test('iOS DefaultFirebaseOptions match GoogleService-Info.plist', () {
    final plist =
        File('ios/Runner/GoogleService-Info.plist').readAsStringSync();

    expect(DefaultFirebaseOptions.ios.apiKey, _plistValue(plist, 'API_KEY'));
    expect(DefaultFirebaseOptions.ios.appId,
        _plistValue(plist, 'GOOGLE_APP_ID'));
    expect(DefaultFirebaseOptions.ios.messagingSenderId,
        _plistValue(plist, 'GCM_SENDER_ID'));
    expect(DefaultFirebaseOptions.ios.projectId,
        _plistValue(plist, 'PROJECT_ID'));
    expect(DefaultFirebaseOptions.ios.storageBucket,
        _plistValue(plist, 'STORAGE_BUCKET'));
    expect(DefaultFirebaseOptions.ios.iosBundleId,
        _plistValue(plist, 'BUNDLE_ID'));
  });
}
