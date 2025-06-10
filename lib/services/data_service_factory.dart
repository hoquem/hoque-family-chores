// lib/services/data_service_factory.dart
import 'package:hoque_family_chores/services/data_service_interface.dart';
import 'package:hoque_family_chores/services/firebase_data_service.dart';
import 'package:hoque_family_chores/services/mock_data_service.dart';
import 'package:hoque_family_chores/services/environment_service.dart'; // To check environment
import 'package:hoque_family_chores/services/logging_service.dart';

class DataServiceFactory {
  static DataServiceInterface? _instance; // Singleton instance

  static DataServiceInterface getDataService() {
    if (_instance == null) {
      final environmentService = EnvironmentService(); // Access environment
      if (environmentService.useMockData) {
        _instance = MockDataService();
        logger.i("DataServiceFactory: Providing MockDataService.");
      } else {
        _instance = FirebaseDataService();
        logger.i("DataServiceFactory: Providing FirebaseDataService.");
      }
    }
    return _instance!;
  }
}