import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/utils/home_widget_bridge.dart';

/// The two platforms name the widget differently and the names are NOT
/// interchangeable:
///
///  - iOS wants the WidgetKit ``kind`` string, declared in the widget's Swift
///    source, and reloads timelines by that kind.
///  - Android wants the fully-qualified AppWidgetProvider class. home_widget
///    resolves it with ``Class.forName("$packageName.$androidName")``; a wrong
///    name throws ClassNotFoundException and the widget silently stops
///    refreshing until its 24h ``updatePeriodMillis`` elapses.
///
/// Passing the iOS kind to Android is exactly the bug this pins shut.
void main() {
  test('iOS widget name matches the WidgetKit kind in ChoresStarWidget.swift',
      () {
    final swift =
        File('ios/ChoresStarWidget/ChoresStarWidget.swift').readAsStringSync();

    final match =
        RegExp(r'let kind:\s*String\s*=\s*"([^"]+)"').firstMatch(swift);
    if (match == null) {
      fail('ios/ChoresStarWidget/ChoresStarWidget.swift declares no widget kind');
    }

    expect(HomeWidgetBridgeImpl.iOSWidgetKind, match.group(1));
  });

  test('Android widget name matches the receiver in AndroidManifest.xml', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    final match = RegExp(r'<receiver\s+android:name="\.([A-Za-z0-9_]+)"')
        .firstMatch(manifest);
    if (match == null) {
      fail('android/app/src/main/AndroidManifest.xml declares no widget receiver');
    }

    expect(HomeWidgetBridgeImpl.androidProviderName, match.group(1));
  });

  // Three files must agree on the scheme the widget opens: the widget declares
  // it, Info.plist claims it for the app, and AppDelegate intercepts it before
  // the Flutter plugin chain can hand it to FirebaseAuth and wedge startup.
  // Any one of them drifting is a silent launch bug (cf. commit 379df48).
  test('the widget URL scheme agrees across widget, Info.plist and AppDelegate',
      () {
    final swift =
        File('ios/ChoresStarWidget/ChoresStarWidget.swift').readAsStringSync();
    final scheme = RegExp(r'\.widgetURL\(URL\(string:\s*"([a-z0-9.+-]+)://')
        .firstMatch(swift)
        ?.group(1);
    expect(scheme, isNotNull,
        reason: 'ChoresStarWidget.swift declares no widgetURL');

    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(infoPlist, contains('<string>$scheme</string>'),
        reason: 'ios/Runner/Info.plist does not register the $scheme scheme, '
            'so iOS will not route the widget tap to the app');

    final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(appDelegate, contains('"$scheme"'),
        reason: 'AppDelegate must claim $scheme before the plugin chain sees '
            'it, or FLTFirebaseAuthPlugin blocks the main thread on launch');
  });

  test('the Android provider class exists at the applicationId package', () {
    // home_widget builds the class name from context.packageName, which is the
    // applicationId — not the Kotlin source package. They agree today; this
    // fails loudly if one is ever changed without the other.
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final applicationId = RegExp(r'applicationId\s*=\s*"([^"]+)"')
        .firstMatch(gradle)
        ?.group(1);
    expect(applicationId, isNotNull,
        reason: 'android/app/build.gradle.kts declares no applicationId');

    final source = File(
      'android/app/src/main/kotlin/${applicationId!.replaceAll('.', '/')}/'
      '${HomeWidgetBridgeImpl.androidProviderName}.kt',
    );
    expect(source.existsSync(), isTrue,
        reason: 'no ${source.path} — home_widget will throw '
            'ClassNotFoundException on every updateWidget call');
  });
}
