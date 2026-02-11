import '../../core/environment_service.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/family_repository.dart';
import '../../domain/repositories/badge_repository.dart';
import '../../domain/repositories/reward_repository.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../domain/repositories/task_completion_repository.dart';
import '../../domain/repositories/ai_rating_service.dart';

// Firebase implementations
import 'firebase_task_repository.dart';
import 'firebase_auth_repository.dart';
import 'firebase_user_repository.dart';
import 'firebase_family_repository.dart';
import 'firebase_badge_repository.dart';
import 'firebase_reward_repository.dart';
import 'firebase_leaderboard_repository.dart';
import 'firebase_achievement_repository.dart';
import 'firebase_notification_repository.dart';
import 'firebase_gamification_repository.dart';
import 'firebase_task_completion_repository.dart';
import 'gemini_ai_rating_service.dart';

// Mock implementations
import 'mock_task_repository.dart';
import 'mock_auth_repository.dart';
import 'mock_user_repository.dart';
import 'mock_family_repository.dart';
import 'mock_badge_repository.dart';
import 'mock_reward_repository.dart';
import 'mock_leaderboard_repository.dart';
import 'mock_achievement_repository.dart';
import 'mock_notification_repository.dart';
import 'mock_gamification_repository.dart';
import 'mock_task_completion_repository.dart';
import 'mock_ai_rating_service.dart';

/// Factory for creating repository implementations based on environment
class RepositoryFactory {
  final EnvironmentService _environment;

  RepositoryFactory(this._environment);

  /// Creates all repositories based on the environment
  Map<Type, dynamic> createRepositories() {
    final repositories = <Type, dynamic>{};

    try {
      // Create task repository
      repositories[TaskRepository] = _environment.useMockData 
          ? MockTaskRepository() 
          : FirebaseTaskRepository();

      // Create auth repository
      repositories[AuthRepository] = _environment.useMockData 
          ? MockAuthRepository() 
          : FirebaseAuthRepository();

      // Create user repository
      repositories[UserRepository] = _environment.useMockData 
          ? MockUserRepository() 
          : FirebaseUserRepository();

      // Create family repository
      repositories[FamilyRepository] = _environment.useMockData 
          ? MockFamilyRepository() 
          : FirebaseFamilyRepository();

      // Create badge repository
      repositories[BadgeRepository] = _environment.useMockData 
          ? MockBadgeRepository() 
          : FirebaseBadgeRepository();

      // Create reward repository
      repositories[RewardRepository] = _environment.useMockData 
          ? MockRewardRepository() 
          : FirebaseRewardRepository();

      // Create leaderboard repository
      repositories[LeaderboardRepository] = _environment.useMockData 
          ? MockLeaderboardRepository() 
          : FirebaseLeaderboardRepository();

      // Create achievement repository
      repositories[AchievementRepository] = _environment.useMockData 
          ? MockAchievementRepository() 
          : FirebaseAchievementRepository();

      // Create notification repository
      repositories[NotificationRepository] = _environment.useMockData 
          ? MockNotificationRepository() 
          : FirebaseNotificationRepository();

      // Create gamification repository
      repositories[GamificationRepository] = _environment.useMockData 
          ? MockGamificationRepository() 
          : FirebaseGamificationRepository();

      // Create task completion repository
      repositories[TaskCompletionRepository] = _environment.useMockData 
          ? MockTaskCompletionRepository() 
          : FirebaseTaskCompletionRepository();

      // Create AI rating service
      repositories[AiRatingService] = _environment.useMockData 
          ? MockAiRatingService() 
          : GeminiAiRatingService(apiKey: _environment.geminiApiKey);

    } catch (e) {
      throw Exception('Failed to create repositories: $e');
    }

    return repositories;
  }
} 