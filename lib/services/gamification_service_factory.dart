// lib/services/gamification_service_factory.dart
import 'package:hoque_family_chores/services/environment_service.dart';
import 'package:hoque_family_chores/services/gamification_service_interface.dart';
import 'package:hoque_family_chores/services/mock_gamification_service.dart';
// import 'package:hoque_family_chores/services/firebase_gamification_service.dart'; 

class GamificationServiceFactory {
  static GamificationServiceInterface getGamificationService() {
    final environment = EnvironmentService();
    
    // ALIGNED: Uses the 'useMockData' getter from your EnvironmentService.
    if (environment.useMockData) {
      return MockGamificationService();
    } else {
      // return FirebaseGamificationService(); // Your real implementation
      return MockGamificationService(); // Fallback for now
    }
  }
}