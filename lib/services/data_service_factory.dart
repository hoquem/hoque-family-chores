// lib/services/data_service_factory.dart

import 'package:hoque_family_chores/services/data_service.dart';
import 'package:hoque_family_chores/services/environment_service.dart';
import 'package:hoque_family_chores/services/firebase_data_service.dart';
import 'package:hoque_family_chores/services/mock_data_service.dart';

/// Factory class that provides the appropriate DataService implementation
/// based on the current environment.
///
/// During tests and CI/CD builds, it will return a MockDataService.
/// During normal app execution on devices and simulators, it will return a FirebaseDataService.
class DataServiceFactory {
  // Private constructor to prevent direct instantiation
  DataServiceFactory._();
  
  // Cached instances of services
  static final DataService _mockDataService = MockDataService();
  static final DataService _firebaseDataService = FirebaseDataService();
  
  // The environment service to determine which implementation to use
  static final EnvironmentService _environmentService = EnvironmentService();
  
  /// Returns the appropriate DataService implementation based on the current environment.
  ///
  /// If [forceMock] is true, it will always return a MockDataService regardless of environment.
  /// If [forceFirebase] is true, it will always return a FirebaseDataService regardless of environment.
  /// Otherwise, it uses the EnvironmentService to determine which service to return.
  static DataService getDataService({
    bool? forceMock,
    bool? forceFirebase,
  }) {
    // Handle explicit overrides
    if (forceMock == true) {
      return _mockDataService;
    }
    
    if (forceFirebase == true) {
      return _firebaseDataService;
    }
    
    // Use environment service to determine which service to use
    if (_environmentService.useMockData) {
      return _mockDataService;
    } else {
      return _firebaseDataService;
    }
  }
  
  /// Returns a MockDataService regardless of environment.
  /// Useful for testing specific components with mock data.
  static DataService getMockDataService() {
    return _mockDataService;
  }
  
  /// Returns a FirebaseDataService regardless of environment.
  /// Useful when real data is needed even in test environments.
  static DataService getFirebaseDataService() {
    return _firebaseDataService;
  }
}
