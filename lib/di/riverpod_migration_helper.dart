import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/environment_service.dart';

// Domain repositories
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/family_repository.dart';
import '../domain/repositories/gamification_repository.dart';
import '../domain/repositories/leaderboard_repository.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/repositories/achievement_repository.dart';
import '../domain/repositories/badge_repository.dart';
import '../domain/repositories/reward_repository.dart';
import '../domain/repositories/user_repository.dart';

// Use cases
import '../domain/usecases/usecases.dart';

/// Helper class to migrate from GetIt to Riverpod
/// This provides easy access to dependencies during the migration period
class RiverpodMigrationHelper {
  final ProviderContainer _container;

  RiverpodMigrationHelper(this._container);

  /// Get a dependency from Riverpod container
  T get<T>(ProviderBase<T> provider) {
    return _container.read(provider);
  }

  /// Watch a dependency from Riverpod container
  T watch<T>(ProviderBase<T> provider) {
    return _container.read(provider);
  }

  /// Get environment service
  EnvironmentService get environmentService => get(environmentServiceProvider);

  /// Get repository factory
  RepositoryFactory get repositoryFactory => get(repositoryFactoryProvider);

  // Clean Architecture Repositories
  TaskRepository get taskRepository => get(taskRepositoryProvider);
  AuthRepository get authRepository => get(authRepositoryProvider);
  UserRepository get userRepository => get(userRepositoryProvider);
  FamilyRepository get familyRepository => get(familyRepositoryProvider);
  BadgeRepository get badgeRepository => get(badgeRepositoryProvider);
  RewardRepository get rewardRepository => get(rewardRepositoryProvider);
  LeaderboardRepository get leaderboardRepository => get(leaderboardRepositoryProvider);
  AchievementRepository get achievementRepository => get(achievementRepositoryProvider);
  NotificationRepository get notificationRepository => get(notificationRepositoryProvider);
  GamificationRepository get gamificationRepository => get(gamificationRepositoryProvider);

  // Clean Architecture Use Cases
  CreateTaskUseCase get createTaskUseCase => get(createTaskUseCaseProvider);
  ClaimTaskUseCase get claimTaskUseCase => get(claimTaskUseCaseProvider);
  CompleteTaskUseCase get completeTaskUseCase => get(completeTaskUseCaseProvider);
  ApproveTaskUseCase get approveTaskUseCase => get(approveTaskUseCaseProvider);
  GetTasksUseCase get getTasksUseCase => get(getTasksUseCaseProvider);
  SignInUseCase get signInUseCase => get(signInUseCaseProvider);
  SignUpUseCase get signUpUseCase => get(signUpUseCaseProvider);
  CreateFamilyUseCase get createFamilyUseCase => get(createFamilyUseCaseProvider);
  AddMemberUseCase get addMemberUseCase => get(addMemberUseCaseProvider);
  GetUserProfileUseCase get getUserProfileUseCase => get(getUserProfileUseCaseProvider);
  UpdateUserProfileUseCase get updateUserProfileUseCase => get(updateUserProfileUseCaseProvider);
  AwardPointsUseCase get awardPointsUseCase => get(awardPointsUseCaseProvider);
  RedeemRewardUseCase get redeemRewardUseCase => get(redeemRewardUseCaseProvider);
  GetLeaderboardUseCase get getLeaderboardUseCase => get(getLeaderboardUseCaseProvider);

  // Additional Task Use Cases
  UpdateTaskUseCase get updateTaskUseCase => get(updateTaskUseCaseProvider);
  DeleteTaskUseCase get deleteTaskUseCase => get(deleteTaskUseCaseProvider);
  AssignTaskUseCase get assignTaskUseCase => get(assignTaskUseCaseProvider);
  UnassignTaskUseCase get unassignTaskUseCase => get(unassignTaskUseCaseProvider);
  UncompleteTaskUseCase get uncompleteTaskUseCase => get(uncompleteTaskUseCaseProvider);
  RejectTaskUseCase get rejectTaskUseCase => get(rejectTaskUseCaseProvider);
  StreamTasksUseCase get streamTasksUseCase => get(streamTasksUseCaseProvider);
  StreamAvailableTasksUseCase get streamAvailableTasksUseCase => get(streamAvailableTasksUseCaseProvider);
  StreamTasksByAssigneeUseCase get streamTasksByAssigneeUseCase => get(streamTasksByAssigneeUseCaseProvider);

  // Additional Family Use Cases
  GetFamilyUseCase get getFamilyUseCase => get(getFamilyUseCaseProvider);
  UpdateFamilyUseCase get updateFamilyUseCase => get(updateFamilyUseCaseProvider);
  DeleteFamilyUseCase get deleteFamilyUseCase => get(deleteFamilyUseCaseProvider);
  RemoveMemberUseCase get removeMemberUseCase => get(removeMemberUseCaseProvider);
  GetFamilyMembersUseCase get getFamilyMembersUseCase => get(getFamilyMembersUseCaseProvider);
  UpdateFamilyMemberUseCase get updateFamilyMemberUseCase => get(updateFamilyMemberUseCaseProvider);

  // Additional User Use Cases
  DeleteUserUseCase get deleteUserUseCase => get(deleteUserUseCaseProvider);
  StreamUserProfileUseCase get streamUserProfileUseCase => get(streamUserProfileUseCaseProvider);
  InitializeUserDataUseCase get initializeUserDataUseCase => get(initializeUserDataUseCaseProvider);

  // Additional Gamification Use Cases
  AwardBadgeUseCase get awardBadgeUseCase => get(awardBadgeUseCaseProvider);
  RevokeBadgeUseCase get revokeBadgeUseCase => get(revokeBadgeUseCaseProvider);
  GrantAchievementUseCase get grantAchievementUseCase => get(grantAchievementUseCaseProvider);
  CreateBadgeUseCase get createBadgeUseCase => get(createBadgeUseCaseProvider);
  CreateRewardUseCase get createRewardUseCase => get(createRewardUseCaseProvider);
  GetBadgesUseCase get getBadgesUseCase => get(getBadgesUseCaseProvider);
  GetRewardsUseCase get getRewardsUseCase => get(getRewardsUseCaseProvider);

  // Notification Use Cases
  GetNotificationsUseCase get getNotificationsUseCase => get(getNotificationsUseCaseProvider);
  CreateNotificationUseCase get createNotificationUseCase => get(createNotificationUseCaseProvider);
  MarkNotificationAsReadUseCase get markNotificationAsReadUseCase => get(markNotificationAsReadUseCaseProvider);
  DeleteNotificationUseCase get deleteNotificationUseCase => get(deleteNotificationUseCaseProvider);
  StreamNotificationsUseCase get streamNotificationsUseCase => get(streamNotificationsUseCaseProvider);
}

/// Global instance for easy access during migration
/// This will be replaced with proper Riverpod usage in the future
RiverpodMigrationHelper? _globalHelper;

/// Initialize the global migration helper
void initializeRiverpodMigration(ProviderContainer container) {
  _globalHelper = RiverpodMigrationHelper(container);
}

/// Get the global migration helper
RiverpodMigrationHelper get riverpodHelper {
  if (_globalHelper == null) {
    throw StateError('RiverpodMigrationHelper not initialized. Call initializeRiverpodMigration first.');
  }
  return _globalHelper!;
}

/// Extension to make it easier to access dependencies from anywhere
extension RiverpodHelperExtension on ProviderContainer {
  RiverpodMigrationHelper get migrationHelper => RiverpodMigrationHelper(this);
} 