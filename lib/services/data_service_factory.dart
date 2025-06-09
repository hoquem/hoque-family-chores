// lib/services/data_service_factory.dart

// ADDED: The necessary imports so the factory knows what all the services are.
import 'package:hoque_family_chores/services/data_service_interface.dart';
import 'package:hoque_family_chores/services/environment_service.dart';
import 'package:hoque_family_chores/services/firebase_data_service.dart';
import 'package:hoque_family_chores/services/mock_data_service.dart';

/// Factory class that provides the appropriate DataServiceInterface implementation
/// based on the current environment.
class DataServiceFactory {
  DataServiceFactory._();

  // These lines now work because the files are imported above.
  static final DataServiceInterface _mockDataService = MockDataService();
  static final DataServiceInterface _firebaseDataService = FirebaseDataService();

  static final EnvironmentService _environmentService = EnvironmentService();

  static DataServiceInterface getDataService({
    bool? forceMock,
    bool? forceFirebase,
  }) {
    if (forceMock == true) {
      return _mockDataService;
    }
    if (forceFirebase == true) {
      return _firebaseDataService;
    }
    if (_environmentService.useMockData) {
      return _mockDataService;
    } else {
      return _firebaseDataService;
    }
  }
}