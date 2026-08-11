import '../../core/environment_service.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/family_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/push_notification_repository.dart';
import '../../domain/repositories/task_completion_repository.dart';
import '../../domain/repositories/reward_repository.dart';

// Firebase implementations
import 'firebase_task_repository.dart';
import 'firebase_auth_repository.dart';
import 'firebase_user_repository.dart';
import 'firebase_family_repository.dart';
import 'firebase_notification_repository.dart';
import 'firebase_push_notification_repository.dart';
import 'firebase_task_completion_repository.dart';
import 'firebase_reward_repository.dart';

/// Factory for creating the app's repository implementations.
///
/// It used to take an [EnvironmentService] and was described as choosing
/// implementations "based on environment". It never did — every repository
/// below is a Firebase one, on every build. The parameter is gone rather than
/// left in place suggesting a choice that does not exist (TASK-496).
class RepositoryFactory {
  RepositoryFactory();

  /// Creates all repositories.
  Map<Type, dynamic> createRepositories() {
    final repositories = <Type, dynamic>{};

    try {
      repositories[TaskRepository] = FirebaseTaskRepository();
      repositories[AuthRepository] = FirebaseAuthRepository();
      repositories[UserRepository] = FirebaseUserRepository();
      repositories[FamilyRepository] = FirebaseFamilyRepository();
      repositories[NotificationRepository] = FirebaseNotificationRepository();
      repositories[PushNotificationRepository] = FirebasePushNotificationRepository();
      repositories[TaskCompletionRepository] = FirebaseTaskCompletionRepository();
      repositories[RewardRepository] = FirebaseRewardRepository();
    } catch (e) {
      throw Exception('Failed to create repositories: $e');
    }

    return repositories;
  }
}
