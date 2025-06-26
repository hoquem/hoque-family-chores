// lib/services/environment_service.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// A service that determines whether to use mock data or real data
/// based on the current environment (test, development, production).
class EnvironmentService {
  // Singleton instance
  static final EnvironmentService _instance = EnvironmentService._internal();

  // Factory constructor to return the singleton instance
  factory EnvironmentService() => _instance;

  // Private constructor
  EnvironmentService._internal();

  /// Determines if the app should use mock data instead of real Firebase data.
  /// 
  /// Returns true if:
  /// - The USE_MOCK_DATA environment variable is set to true
  /// - The app is running in a test environment
  bool get useMockData {
    // Check for environment variable first (used in CI/CD)
    if (const bool.hasEnvironment('USE_MOCK_DATA')) {
      return const bool.fromEnvironment('USE_MOCK_DATA');
    }
    
    // Always use mock data in tests
    if (isTestEnvironment) {
      return true;
    }
    
    // Default to real data for development and production
    return false;
  }

  /// Determines if the app is running in a test environment.
  bool get isTestEnvironment {
    // Check if running in a test runner
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }
    
    // Check for common CI/CD environment variables
    if (Platform.environment.containsKey('CI') || 
        Platform.environment.containsKey('GITHUB_ACTIONS')) {
      return true;
    }
    
    return false;
  }

  /// Determines if the app is running in debug mode.
  bool get isDebugMode {
    return kDebugMode;
  }

  /// Determines if the app is running in release mode.
  bool get isReleaseMode {
    return kReleaseMode;
  }

  /// Determines if the app is running in profile mode.
  bool get isProfileMode {
    return kProfileMode;
  }
  
  /// Determines if the app should connect to Firebase.
  /// 
  /// Always connects to Firebase except in test environments
  /// where mock data is being used.
  bool get shouldConnectToFirebase {
    return !useMockData;
  }
}
