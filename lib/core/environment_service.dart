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
  /// TODO: Replace with actual API key or load from .env file
  String get geminiApiKey {
    // In production, this should come from a secure source
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isNotEmpty) {
      return apiKey;
    }
    // Fallback for development (replace with actual key)
    return 'YOUR_GEMINI_API_KEY_HERE';
  }
} 