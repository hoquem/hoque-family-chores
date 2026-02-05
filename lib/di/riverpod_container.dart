import 'package:riverpod_annotation/riverpod_annotation.dart';
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

// Data repository implementations - used via RepositoryFactory
import '../data/repositories/repository_factory.dart';

// Use cases
import '../domain/usecases/usecases.dart';

part 'riverpod_container.g.dart';

/// Environment Service Provider
@riverpod
EnvironmentService environmentService(Ref ref) {
  return EnvironmentService();
}

/// Repository Factory Provider
@riverpod
RepositoryFactory repositoryFactory(Ref ref) {
  final environmentService = ref.watch(environmentServiceProvider);
  return RepositoryFactory(environmentService);
}

/// Repository Providers (Clean Architecture)
@riverpod
TaskRepository taskRepository(Ref ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[TaskRepository] as TaskRepository;
}

@riverpod
AuthRepository authRepository(Ref ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[AuthRepository] as AuthRepository;
}

@riverpod
UserRepository userRepository(Ref ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[UserRepository] as UserRepository;
}

@riverpod
FamilyRepository familyRepository(Ref ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[FamilyRepository] as FamilyRepository;
}

@riverpod
BadgeRepository badgeRepository(Ref ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[BadgeRepository] as BadgeRepository;
}

@riverpod
RewardRepository rewardRepository(Ref ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[RewardRepository] as RewardRepository;
}

@riverpod
LeaderboardRepository leaderboardRepository(Ref ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[LeaderboardRepository] as LeaderboardRepository;
}

@riverpod
AchievementRepository achievementRepository(Ref ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[AchievementRepository] as AchievementRepository;
}

@riverpod
NotificationRepository notificationRepository(Ref ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[NotificationRepository] as NotificationRepository;
}

@riverpod
GamificationRepository gamificationRepository(Ref ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[GamificationRepository] as GamificationRepository;
}

/// Use Case Providers (Clean Architecture)
@riverpod
CreateTaskUseCase createTaskUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return CreateTaskUseCase(taskRepository);
}

@riverpod
ClaimTaskUseCase claimTaskUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return ClaimTaskUseCase(taskRepository);
}

@riverpod
CompleteTaskUseCase completeTaskUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return CompleteTaskUseCase(taskRepository);
}

@riverpod
ApproveTaskUseCase approveTaskUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return ApproveTaskUseCase(taskRepository);
}

@riverpod
GetTasksUseCase getTasksUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return GetTasksUseCase(taskRepository);
}

@riverpod
SignInUseCase signInUseCase(Ref ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return SignInUseCase(authRepository);
}

@riverpod
SignUpUseCase signUpUseCase(Ref ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return SignUpUseCase(authRepository);
}

@riverpod
CreateFamilyUseCase createFamilyUseCase(Ref ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return CreateFamilyUseCase(familyRepository);
}

@riverpod
AddMemberUseCase addMemberUseCase(Ref ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return AddMemberUseCase(familyRepository);
}

@riverpod
GetUserProfileUseCase getUserProfileUseCase(Ref ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return GetUserProfileUseCase(userRepository);
}

@riverpod
UpdateUserProfileUseCase updateUserProfileUseCase(Ref ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return UpdateUserProfileUseCase(userRepository);
}

@riverpod
AwardPointsUseCase awardPointsUseCase(Ref ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return AwardPointsUseCase(userRepository);
}

@riverpod
RedeemRewardUseCase redeemRewardUseCase(Ref ref) {
  final rewardRepository = ref.watch(rewardRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return RedeemRewardUseCase(rewardRepository, userRepository);
}

@riverpod
GetLeaderboardUseCase getLeaderboardUseCase(Ref ref) {
  final leaderboardRepository = ref.watch(leaderboardRepositoryProvider);
  return GetLeaderboardUseCase(leaderboardRepository);
}

// Additional Task Use Cases
@riverpod
UpdateTaskUseCase updateTaskUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return UpdateTaskUseCase(taskRepository);
}

@riverpod
DeleteTaskUseCase deleteTaskUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return DeleteTaskUseCase(taskRepository);
}

@riverpod
AssignTaskUseCase assignTaskUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return AssignTaskUseCase(taskRepository);
}

@riverpod
UnassignTaskUseCase unassignTaskUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return UnassignTaskUseCase(taskRepository);
}

@riverpod
UncompleteTaskUseCase uncompleteTaskUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return UncompleteTaskUseCase(taskRepository);
}

@riverpod
RejectTaskUseCase rejectTaskUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return RejectTaskUseCase(taskRepository);
}

@riverpod
StreamTasksUseCase streamTasksUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return StreamTasksUseCase(taskRepository);
}

@riverpod
StreamAvailableTasksUseCase streamAvailableTasksUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return StreamAvailableTasksUseCase(taskRepository);
}

@riverpod
StreamTasksByAssigneeUseCase streamTasksByAssigneeUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return StreamTasksByAssigneeUseCase(taskRepository);
}

// Additional Family Use Cases
@riverpod
GetFamilyUseCase getFamilyUseCase(Ref ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return GetFamilyUseCase(familyRepository);
}

@riverpod
UpdateFamilyUseCase updateFamilyUseCase(Ref ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return UpdateFamilyUseCase(familyRepository);
}

@riverpod
DeleteFamilyUseCase deleteFamilyUseCase(Ref ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return DeleteFamilyUseCase(familyRepository);
}

@riverpod
RemoveMemberUseCase removeMemberUseCase(Ref ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return RemoveMemberUseCase(familyRepository);
}

@riverpod
GetFamilyMembersUseCase getFamilyMembersUseCase(Ref ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return GetFamilyMembersUseCase(familyRepository);
}

@riverpod
UpdateFamilyMemberUseCase updateFamilyMemberUseCase(Ref ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return UpdateFamilyMemberUseCase(familyRepository);
}

// Additional User Use Cases
@riverpod
DeleteUserUseCase deleteUserUseCase(Ref ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return DeleteUserUseCase(userRepository);
}

@riverpod
StreamUserProfileUseCase streamUserProfileUseCase(Ref ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return StreamUserProfileUseCase(userRepository);
}

@riverpod
InitializeUserDataUseCase initializeUserDataUseCase(Ref ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return InitializeUserDataUseCase(userRepository);
}

// Additional Gamification Use Cases
@riverpod
AwardBadgeUseCase awardBadgeUseCase(Ref ref) {
  final badgeRepository = ref.watch(badgeRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return AwardBadgeUseCase(badgeRepository, userRepository);
}

@riverpod
RevokeBadgeUseCase revokeBadgeUseCase(Ref ref) {
  final badgeRepository = ref.watch(badgeRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return RevokeBadgeUseCase(badgeRepository, userRepository);
}

@riverpod
GrantAchievementUseCase grantAchievementUseCase(Ref ref) {
  final achievementRepository = ref.watch(achievementRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return GrantAchievementUseCase(achievementRepository, userRepository);
}

@riverpod
CreateBadgeUseCase createBadgeUseCase(Ref ref) {
  final badgeRepository = ref.watch(badgeRepositoryProvider);
  return CreateBadgeUseCase(badgeRepository);
}

@riverpod
CreateRewardUseCase createRewardUseCase(Ref ref) {
  final rewardRepository = ref.watch(rewardRepositoryProvider);
  return CreateRewardUseCase(rewardRepository);
}

@riverpod
GetBadgesUseCase getBadgesUseCase(Ref ref) {
  final badgeRepository = ref.watch(badgeRepositoryProvider);
  return GetBadgesUseCase(badgeRepository);
}

@riverpod
GetRewardsUseCase getRewardsUseCase(Ref ref) {
  final rewardRepository = ref.watch(rewardRepositoryProvider);
  return GetRewardsUseCase(rewardRepository);
}

// Notification Use Cases
@riverpod
GetNotificationsUseCase getNotificationsUseCase(Ref ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return GetNotificationsUseCase(notificationRepository);
}

@riverpod
CreateNotificationUseCase createNotificationUseCase(Ref ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return CreateNotificationUseCase(notificationRepository);
}

@riverpod
MarkNotificationAsReadUseCase markNotificationAsReadUseCase(Ref ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return MarkNotificationAsReadUseCase(notificationRepository);
}

@riverpod
DeleteNotificationUseCase deleteNotificationUseCase(Ref ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return DeleteNotificationUseCase(notificationRepository);
}

@riverpod
StreamNotificationsUseCase streamNotificationsUseCase(Ref ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return StreamNotificationsUseCase(notificationRepository);
}

@riverpod
ResetPasswordUseCase resetPasswordUseCase(Ref ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return ResetPasswordUseCase(authRepository);
}