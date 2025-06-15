import 'package:get_it/get_it.dart';
import 'package:hoque_family_chores/services/base/environment_service.dart';
import 'package:hoque_family_chores/services/interfaces/auth_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/family_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/gamification_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/leaderboard_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/task_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/task_summary_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/notification_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/achievement_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/badge_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/reward_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/user_profile_service_interface.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_auth_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_family_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_gamification_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_leaderboard_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_task_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_task_summary_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_notification_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_achievement_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_badge_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_reward_service.dart';
import 'package:hoque_family_chores/services/implementations/firebase/firebase_user_profile_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_auth_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_family_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_gamification_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_leaderboard_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_task_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_task_summary_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_notification_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_achievement_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_badge_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_reward_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_user_profile_service.dart';

final getIt = GetIt.instance;

/// Initialize the service locator with all dependencies
Future<void> initializeServiceLocator() async {
  // Register environment service
  getIt.registerSingleton<EnvironmentService>(EnvironmentService());

  // Register services based on environment
  if (getIt<EnvironmentService>().useMockData) {
    // Register mock services for development
    getIt.registerSingleton<AuthServiceInterface>(MockAuthService());
    getIt.registerSingleton<FamilyServiceInterface>(MockFamilyService());
    getIt.registerSingleton<GamificationServiceInterface>(
      MockGamificationService(),
    );
    getIt.registerSingleton<LeaderboardServiceInterface>(
      MockLeaderboardService(),
    );
    getIt.registerSingleton<TaskServiceInterface>(MockTaskService());
    getIt.registerSingleton<TaskSummaryServiceInterface>(
      MockTaskSummaryService(),
    );
    getIt.registerSingleton<NotificationServiceInterface>(
      MockNotificationService(),
    );
    getIt.registerSingleton<AchievementServiceInterface>(
      MockAchievementService(),
    );
    getIt.registerSingleton<BadgeServiceInterface>(MockBadgeService());
    getIt.registerSingleton<RewardServiceInterface>(MockRewardService());
    getIt.registerSingleton<UserProfileServiceInterface>(
      MockUserProfileService(),
    );
  } else {
    // Register Firebase services for production
    getIt.registerSingleton<AuthServiceInterface>(FirebaseAuthService());
    getIt.registerSingleton<FamilyServiceInterface>(FirebaseFamilyService());
    getIt.registerSingleton<GamificationServiceInterface>(
      FirebaseGamificationService(),
    );
    getIt.registerSingleton<LeaderboardServiceInterface>(
      FirebaseLeaderboardService(),
    );
    getIt.registerSingleton<TaskServiceInterface>(FirebaseTaskService());
    getIt.registerSingleton<TaskSummaryServiceInterface>(
      FirebaseTaskSummaryService(),
    );
    getIt.registerSingleton<NotificationServiceInterface>(
      FirebaseNotificationService(),
    );
    getIt.registerSingleton<AchievementServiceInterface>(
      FirebaseAchievementService(),
    );
    getIt.registerSingleton<BadgeServiceInterface>(FirebaseBadgeService());
    getIt.registerSingleton<RewardServiceInterface>(FirebaseRewardService());
    getIt.registerSingleton<UserProfileServiceInterface>(
      FirebaseUserProfileService(),
    );
  }
}
