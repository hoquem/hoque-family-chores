import 'package:flutter/foundation.dart';

/// Service that provides environment-specific configuration
///
/// There is deliberately no mock-data switch here. `useMockData`,
/// `isTestEnvironment` and `shouldConnectToFirebase` used to live in this class
/// and nothing ever read them: `RepositoryFactory` builds the Firebase
/// repositories unconditionally. `useMockData` did not even consult the
/// `USE_MOCK_DATA` define four different docs told you to pass — it returned
/// true for every debug build and was ignored anyway. Removed under TASK-496.
/// Running against fakes would be a real feature; it was never this one.
class EnvironmentService {
  /// Whether we're in debug mode
  bool get isDebugMode => kDebugMode;

  /// Whether we're in release mode
  bool get isReleaseMode => kReleaseMode;

  /// Whether we're in profile mode
  bool get isProfileMode => kProfileMode;

  /// Whether AI rating feature is enabled
  /// Can be disabled via feature flag for gradual rollout
  bool get enablePhotoProofAi {
    const enabled = String.fromEnvironment('ENABLE_PHOTO_PROOF_AI', defaultValue: 'true');
    return enabled.toLowerCase() == 'true';
  }
} 