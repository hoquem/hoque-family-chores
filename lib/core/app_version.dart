class AppVersion {
  static String version = 'unknown';
  static String buildNumber = 'unknown';

  static Future<void> init() async {
    // These come from pubspec.yaml via Flutter build system
    version = '1.0.0'; // Will be updated by CI
    buildNumber = '1';
  }

  static String get fullVersion => '$version+$buildNumber';
}
