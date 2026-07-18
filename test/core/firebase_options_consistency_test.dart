import 'dart:convert';
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

  // The Android google-services plugin auto-initializes Firebase from
  // google-services.json BEFORE Dart runs; if DefaultFirebaseOptions.android
  // disagrees, startup dies with core/duplicate-app. This is the exact drift
  // that shipped and crashed Android (the iOS-only check above missed it).
  test('Android DefaultFirebaseOptions match google-services.json', () {
    final json = jsonDecode(
      File('android/app/google-services.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final projectInfo = json['project_info'] as Map<String, dynamic>;
    final client = (json['client'] as List).first as Map<String, dynamic>;
    final appId =
        (client['client_info'] as Map)['mobilesdk_app_id'] as String;
    final apiKey =
        ((client['api_key'] as List).first as Map)['current_key'] as String;

    expect(DefaultFirebaseOptions.android.apiKey, apiKey);
    expect(DefaultFirebaseOptions.android.appId, appId);
    expect(DefaultFirebaseOptions.android.projectId,
        projectInfo['project_id']);
    expect(DefaultFirebaseOptions.android.storageBucket,
        projectInfo['storage_bucket']);
    expect(DefaultFirebaseOptions.android.messagingSenderId,
        projectInfo['project_number']);
  });
}
