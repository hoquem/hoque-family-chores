import Flutter
import UIKit

/// URL scheme the home-screen widget opens (see ChoresStarWidget.swift's
/// .widgetURL and the CFBundleURLTypes entry in Info.plist). Pinned to those two
/// by home_widget_names_consistency_test.
private let widgetURLScheme = "hoquefamilychores"

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Claims the widget's own scheme before the Flutter plugin chain sees it.
  ///
  /// Without this, `super` walks the registered plugins until one accepts the
  /// URL. home_widget declines it (it only claims URLs carrying a `homeWidget`
  /// query item), so it reaches FLTFirebaseAuthPlugin, which answers *every*
  /// incoming URL with `[[FIRAuth auth] canHandleURL:]`. Registering the plugins
  /// above already configured the default FirebaseApp, so that line is the
  /// process's *first* access to Auth: it builds the Auth instance on the main
  /// thread and then blocks it in `kAuthGlobalWorkQueue.sync` behind the
  /// keychain restore that Auth's own init just enqueued. The app never comes
  /// back — authStateChanges is never delivered, so the splash sits on
  /// "Connecting..." and then offers to sign out. Launching from the app icon
  /// never calls this method, which is why only the widget hung.
  ///
  /// Google's OAuth callback uses the reverse-client-id scheme, so it still
  /// reaches the plugins via `super`.
  ///
  /// Nothing consumes the widget URL yet. If it is later made addressable,
  /// capture it here and forward it to Dart — do not hand it back to the plugin
  /// chain, and note that home_widget's `initiallyLaunchedFromHomeWidget()`
  /// cannot see it from here.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == widgetURLScheme {
      return true
    }
    return super.application(app, open: url, options: options)
  }
}
