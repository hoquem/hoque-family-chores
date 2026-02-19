import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/environment_service.dart';

// Domain repositories
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/family_repository.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/repositories/task_completion_repository.dart';

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
NotificationRepository notificationRepository(Ref ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[NotificationRepository] as NotificationRepository;
}

@riverpod
TaskCompletionRepository taskCompletionRepository(Ref ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[TaskCompletionRepository] as TaskCompletionRepository;
}

/// Use Case Providers
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
  final userRepository = ref.watch(userRepositoryProvider);
  return ApproveTaskUseCase(taskRepository, userRepository);
}

@riverpod
StreamPendingApprovalsUseCase streamPendingApprovalsUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return StreamPendingApprovalsUseCase(taskRepository);
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

// Family Use Cases
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

// User Use Cases
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
