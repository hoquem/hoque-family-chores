import 'package:riverpod_annotation/riverpod_annotation.dart';
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
EnvironmentService environmentService(EnvironmentServiceRef ref) {
  return EnvironmentService();
}

/// Repository Factory Provider
@riverpod
RepositoryFactory repositoryFactory(RepositoryFactoryRef ref) {
  final environmentService = ref.watch(environmentServiceProvider);
  return RepositoryFactory(environmentService);
}

/// Repository Providers (Clean Architecture)
@riverpod
TaskRepository taskRepository(TaskRepositoryRef ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[TaskRepository] as TaskRepository;
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[AuthRepository] as AuthRepository;
}

@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[UserRepository] as UserRepository;
}

@riverpod
FamilyRepository familyRepository(FamilyRepositoryRef ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[FamilyRepository] as FamilyRepository;
}

@riverpod
BadgeRepository badgeRepository(BadgeRepositoryRef ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[BadgeRepository] as BadgeRepository;
}

@riverpod
RewardRepository rewardRepository(RewardRepositoryRef ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[RewardRepository] as RewardRepository;
}

@riverpod
LeaderboardRepository leaderboardRepository(LeaderboardRepositoryRef ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[LeaderboardRepository] as LeaderboardRepository;
}

@riverpod
AchievementRepository achievementRepository(AchievementRepositoryRef ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[AchievementRepository] as AchievementRepository;
}

@riverpod
NotificationRepository notificationRepository(NotificationRepositoryRef ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[NotificationRepository] as NotificationRepository;
}

@riverpod
GamificationRepository gamificationRepository(GamificationRepositoryRef ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[GamificationRepository] as GamificationRepository;
}

/// Use Case Providers (Clean Architecture)
@riverpod
CreateTaskUseCase createTaskUseCase(CreateTaskUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return CreateTaskUseCase(taskRepository);
}

@riverpod
ClaimTaskUseCase claimTaskUseCase(ClaimTaskUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return ClaimTaskUseCase(taskRepository);
}

@riverpod
CompleteTaskUseCase completeTaskUseCase(CompleteTaskUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return CompleteTaskUseCase(taskRepository);
}

@riverpod
ApproveTaskUseCase approveTaskUseCase(ApproveTaskUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return ApproveTaskUseCase(taskRepository);
}

@riverpod
GetTasksUseCase getTasksUseCase(GetTasksUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return GetTasksUseCase(taskRepository);
}

@riverpod
SignInUseCase signInUseCase(SignInUseCaseRef ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return SignInUseCase(authRepository);
}

@riverpod
SignUpUseCase signUpUseCase(SignUpUseCaseRef ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return SignUpUseCase(authRepository);
}

@riverpod
CreateFamilyUseCase createFamilyUseCase(CreateFamilyUseCaseRef ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return CreateFamilyUseCase(familyRepository);
}

@riverpod
AddMemberUseCase addMemberUseCase(AddMemberUseCaseRef ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return AddMemberUseCase(familyRepository);
}

@riverpod
GetUserProfileUseCase getUserProfileUseCase(GetUserProfileUseCaseRef ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return GetUserProfileUseCase(userRepository);
}

@riverpod
UpdateUserProfileUseCase updateUserProfileUseCase(UpdateUserProfileUseCaseRef ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return UpdateUserProfileUseCase(userRepository);
}

@riverpod
AwardPointsUseCase awardPointsUseCase(AwardPointsUseCaseRef ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return AwardPointsUseCase(userRepository);
}

@riverpod
RedeemRewardUseCase redeemRewardUseCase(RedeemRewardUseCaseRef ref) {
  final rewardRepository = ref.watch(rewardRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return RedeemRewardUseCase(rewardRepository, userRepository);
}

@riverpod
GetLeaderboardUseCase getLeaderboardUseCase(GetLeaderboardUseCaseRef ref) {
  final leaderboardRepository = ref.watch(leaderboardRepositoryProvider);
  return GetLeaderboardUseCase(leaderboardRepository);
}

// Additional Task Use Cases
@riverpod
UpdateTaskUseCase updateTaskUseCase(UpdateTaskUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return UpdateTaskUseCase(taskRepository);
}

@riverpod
DeleteTaskUseCase deleteTaskUseCase(DeleteTaskUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return DeleteTaskUseCase(taskRepository);
}

@riverpod
AssignTaskUseCase assignTaskUseCase(AssignTaskUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return AssignTaskUseCase(taskRepository);
}

@riverpod
UnassignTaskUseCase unassignTaskUseCase(UnassignTaskUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return UnassignTaskUseCase(taskRepository);
}

@riverpod
UncompleteTaskUseCase uncompleteTaskUseCase(UncompleteTaskUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return UncompleteTaskUseCase(taskRepository);
}

@riverpod
RejectTaskUseCase rejectTaskUseCase(RejectTaskUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return RejectTaskUseCase(taskRepository);
}

@riverpod
StreamTasksUseCase streamTasksUseCase(StreamTasksUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return StreamTasksUseCase(taskRepository);
}

@riverpod
StreamAvailableTasksUseCase streamAvailableTasksUseCase(StreamAvailableTasksUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return StreamAvailableTasksUseCase(taskRepository);
}

@riverpod
StreamTasksByAssigneeUseCase streamTasksByAssigneeUseCase(StreamTasksByAssigneeUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return StreamTasksByAssigneeUseCase(taskRepository);
}

// Additional Family Use Cases
@riverpod
GetFamilyUseCase getFamilyUseCase(GetFamilyUseCaseRef ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return GetFamilyUseCase(familyRepository);
}

@riverpod
UpdateFamilyUseCase updateFamilyUseCase(UpdateFamilyUseCaseRef ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return UpdateFamilyUseCase(familyRepository);
}

@riverpod
DeleteFamilyUseCase deleteFamilyUseCase(DeleteFamilyUseCaseRef ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return DeleteFamilyUseCase(familyRepository);
}

@riverpod
RemoveMemberUseCase removeMemberUseCase(RemoveMemberUseCaseRef ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return RemoveMemberUseCase(familyRepository);
}

@riverpod
GetFamilyMembersUseCase getFamilyMembersUseCase(GetFamilyMembersUseCaseRef ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return GetFamilyMembersUseCase(familyRepository);
}

@riverpod
UpdateFamilyMemberUseCase updateFamilyMemberUseCase(UpdateFamilyMemberUseCaseRef ref) {
  final familyRepository = ref.watch(familyRepositoryProvider);
  return UpdateFamilyMemberUseCase(familyRepository);
}

// Additional User Use Cases
@riverpod
DeleteUserUseCase deleteUserUseCase(DeleteUserUseCaseRef ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return DeleteUserUseCase(userRepository);
}

@riverpod
StreamUserProfileUseCase streamUserProfileUseCase(StreamUserProfileUseCaseRef ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return StreamUserProfileUseCase(userRepository);
}

@riverpod
InitializeUserDataUseCase initializeUserDataUseCase(InitializeUserDataUseCaseRef ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return InitializeUserDataUseCase(userRepository);
}

// Additional Gamification Use Cases
@riverpod
AwardBadgeUseCase awardBadgeUseCase(AwardBadgeUseCaseRef ref) {
  final badgeRepository = ref.watch(badgeRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return AwardBadgeUseCase(badgeRepository, userRepository);
}

@riverpod
RevokeBadgeUseCase revokeBadgeUseCase(RevokeBadgeUseCaseRef ref) {
  final badgeRepository = ref.watch(badgeRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return RevokeBadgeUseCase(badgeRepository, userRepository);
}

@riverpod
GrantAchievementUseCase grantAchievementUseCase(GrantAchievementUseCaseRef ref) {
  final achievementRepository = ref.watch(achievementRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return GrantAchievementUseCase(achievementRepository, userRepository);
}

@riverpod
CreateBadgeUseCase createBadgeUseCase(CreateBadgeUseCaseRef ref) {
  final badgeRepository = ref.watch(badgeRepositoryProvider);
  return CreateBadgeUseCase(badgeRepository);
}

@riverpod
CreateRewardUseCase createRewardUseCase(CreateRewardUseCaseRef ref) {
  final rewardRepository = ref.watch(rewardRepositoryProvider);
  return CreateRewardUseCase(rewardRepository);
}

@riverpod
GetBadgesUseCase getBadgesUseCase(GetBadgesUseCaseRef ref) {
  final badgeRepository = ref.watch(badgeRepositoryProvider);
  return GetBadgesUseCase(badgeRepository);
}

@riverpod
GetRewardsUseCase getRewardsUseCase(GetRewardsUseCaseRef ref) {
  final rewardRepository = ref.watch(rewardRepositoryProvider);
  return GetRewardsUseCase(rewardRepository);
}

// Notification Use Cases
@riverpod
GetNotificationsUseCase getNotificationsUseCase(GetNotificationsUseCaseRef ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return GetNotificationsUseCase(notificationRepository);
}

@riverpod
CreateNotificationUseCase createNotificationUseCase(CreateNotificationUseCaseRef ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return CreateNotificationUseCase(notificationRepository);
}

@riverpod
MarkNotificationAsReadUseCase markNotificationAsReadUseCase(MarkNotificationAsReadUseCaseRef ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return MarkNotificationAsReadUseCase(notificationRepository);
}

@riverpod
DeleteNotificationUseCase deleteNotificationUseCase(DeleteNotificationUseCaseRef ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return DeleteNotificationUseCase(notificationRepository);
}

@riverpod
StreamNotificationsUseCase streamNotificationsUseCase(StreamNotificationsUseCaseRef ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return StreamNotificationsUseCase(notificationRepository);
}

@riverpod
ResetPasswordUseCase resetPasswordUseCase(ResetPasswordUseCaseRef ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return ResetPasswordUseCase(authRepository);
} 