import 'package:flutter/foundation.dart';

/// Service that provides environment-specific configuration
class EnvironmentService {
  /// Whether to use mock data instead of Firebase
  bool get useMockData {
    // In debug mode, default to mock data for faster development
    if (kDebugMode) {
      return true;
    }
    // In release mode, always use Firebase
    return false;
  }

  /// Whether we're in a test environment
  bool get isTestEnvironment => kDebugMode && useMockData;

  /// Whether we're in debug mode
  bool get isDebugMode => kDebugMode;

  /// Whether we're in release mode
  bool get isReleaseMode => kReleaseMode;

  /// Whether we're in profile mode
  bool get isProfileMode => kProfileMode;

  /// Whether we should connect to Firebase
  bool get shouldConnectToFirebase => !useMockData;

  /// Gemini API key from environment
  /// Must be set via --dart-define=GEMINI_API_KEY=your_key or environment variable
  String get geminiApiKey {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw StateError(
        'GEMINI_API_KEY must be set via --dart-define or environment variable. '
        'Example: flutter run --dart-define=GEMINI_API_KEY=your_key_here',
      );
    }
    return apiKey;
  }

  /// Whether AI rating feature is enabled
  /// Can be disabled via feature flag for gradual rollout
  bool get enablePhotoProofAi {
    const enabled = String.fromEnvironment('ENABLE_PHOTO_PROOF_AI', defaultValue: 'true');
    return enabled.toLowerCase() == 'true';
  }
} 