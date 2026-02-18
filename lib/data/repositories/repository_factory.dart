import '../../core/environment_service.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/family_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/task_completion_repository.dart';

// Firebase implementations
import 'firebase_task_repository.dart';
import 'firebase_auth_repository.dart';
import 'firebase_user_repository.dart';
import 'firebase_family_repository.dart';
import 'firebase_notification_repository.dart';
import 'firebase_task_completion_repository.dart';

/// Factory for creating repository implementations based on environment
class RepositoryFactory {
  final EnvironmentService environment;

  RepositoryFactory(this.environment);

  /// Creates all repositories based on the environment
  Map<Type, dynamic> createRepositories() {
    final repositories = <Type, dynamic>{};

    try {
      repositories[TaskRepository] = FirebaseTaskRepository();
      repositories[AuthRepository] = FirebaseAuthRepository();
      repositories[UserRepository] = FirebaseUserRepository();
      repositories[FamilyRepository] = FirebaseFamilyRepository();
      repositories[NotificationRepository] = FirebaseNotificationRepository();
      repositories[TaskCompletionRepository] = FirebaseTaskCompletionRepository();
    } catch (e) {
      throw Exception('Failed to create repositories: $e');
    }

    return repositories;
  }
}
