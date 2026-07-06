import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'auth_notifier.g.dart';
part 'auth_notifier.freezed.dart';

/// Authentication state for the application.
@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthStatus.initial) AuthStatus status,
    User? user,
    String? errorMessage,
    @Default(false) bool isLoading,
  }) = _AuthState;
}

/// Manages authentication state and user profile.
/// 
/// This notifier handles sign in, sign up, sign out, and user profile management.
/// It automatically streams user profile changes and maintains authentication state.
/// 
/// Example:
/// ```dart
/// final authState = ref.watch(authNotifierProvider);
/// final notifier = ref.read(authNotifierProvider.notifier);
/// await notifier.signIn(email: 'user@example.com', password: 'password');
/// ```
@riverpod
class AuthNotifier extends _$AuthNotifier {
  final _logger = AppLogger();
  StreamSubscription<dynamic>? _profileSubscription;

  @override
  AuthState build() {
    _logger.d('AuthNotifier: Building initial state');
    ref.onDispose(_stopUserProfileStream);

    // Restore a persisted Firebase session: without this, every cold start
    // routes to MainScreen (authStateChanges has a user) while state.user
    // stays null and the UI spins forever.
    final firebaseUser = ref.read(authRepositoryProvider).currentUser;
    if (firebaseUser != null) {
      final userId = UserId(firebaseUser.uid as String);
      _logger.d('AuthNotifier: Restoring session for user $userId');
      _startUserProfileStream(userId);
      return const AuthState(status: AuthStatus.authenticated);
    }
    return const AuthState();
  }

  /// Signs in a user with email and password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _logger.d('AuthNotifier: Signing in user $email');
    
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      status: AuthStatus.authenticating,
    );

    try {
      final signInUseCase = ref.read(signInUseCaseProvider);
      final result = await signInUseCase.call(
        email: email,
        password: password,
      );

      result.fold(
        (failure) {
          _logger.e('AuthNotifier: Sign in failed', error: failure.message);
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
            status: AuthStatus.error,
          );
        },
        (firebaseUser) {
          // The repository returns the raw Firebase user (uid), not the
          // domain User. The domain profile arrives via the profile stream.
          final userId = UserId(firebaseUser.uid as String);
          _logger.d('AuthNotifier: Sign in successful for user $userId');
          _startUserProfileStream(userId);
          state = state.copyWith(
            isLoading: false,
            status: AuthStatus.authenticated,
          );
        },
      );
    } catch (e) {
      _logger.e('AuthNotifier: Unexpected error during sign in', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: $e',
        status: AuthStatus.error,
      );
    }
  }

  /// Signs up a new user.
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _logger.d('AuthNotifier: Signing up user $email');
    
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      status: AuthStatus.authenticating,
    );

    try {
      final signUpUseCase = ref.read(signUpUseCaseProvider);
      final result = await signUpUseCase.call(
        email: email,
        password: password,
        displayName: displayName,
      );

      await result.fold(
        (failure) async {
          _logger.e('AuthNotifier: Sign up failed', error: failure.message);
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
            status: AuthStatus.error,
          );
        },
        (firebaseUser) async {
          final userId = UserId(firebaseUser.uid as String);
          _logger.d('AuthNotifier: Sign up successful for user $userId');

          // Create the Firestore user profile; without it the profile
          // stream has nothing to emit and the app is unusable.
          final initializeUserData = ref.read(initializeUserDataUseCaseProvider);
          final initResult = await initializeUserData.call(
            userId: userId,
            name: displayName?.trim().isNotEmpty == true
                ? displayName!.trim()
                : email.split('@').first,
            email: email.trim().toLowerCase(),
          );

          initResult.fold(
            (failure) {
              _logger.e('AuthNotifier: Failed to create user profile',
                  error: failure.message);
              state = state.copyWith(
                isLoading: false,
                errorMessage: failure.message,
                status: AuthStatus.error,
              );
            },
            (_) {
              _startUserProfileStream(userId);
              state = state.copyWith(
                isLoading: false,
                status: AuthStatus.authenticated,
              );
            },
          );
        },
      );
    } catch (e) {
      _logger.e('AuthNotifier: Unexpected error during sign up', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: $e',
        status: AuthStatus.error,
      );
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    _logger.d('AuthNotifier: Signing out user');
    
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      // Stop the user profile stream
      _stopUserProfileStream();

      // Actually sign out of Firebase — routing is driven by
      // authStateChanges, so clearing local state alone leaves the user
      // logged in.
      await ref.read(authRepositoryProvider).signOut();

      // Clear the state
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );

      _logger.d('AuthNotifier: Sign out successful');
    } catch (e) {
      _logger.e('AuthNotifier: Error during sign out', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error signing out: $e',
      );
    }
  }

  /// Refreshes the user profile.
  Future<void> refreshUserProfile() async {
    if (state.user == null) {
      _logger.w('AuthNotifier: Cannot refresh profile - no user');
      return;
    }

    _logger.d('AuthNotifier: Refreshing user profile');
    
    state = state.copyWith(isLoading: true);

    try {
      final getUserProfileUseCase = ref.read(getUserProfileUseCaseProvider);
      final result = await getUserProfileUseCase.call(userId: state.user!.id);

      result.fold(
        (failure) {
          _logger.e('AuthNotifier: Failed to refresh profile', error: failure.message);
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
        },
        (userProfile) {
          _logger.d('AuthNotifier: Profile refreshed successfully');
          state = state.copyWith(
            isLoading: false,
            user: userProfile,
          );
        },
      );
    } catch (e) {
      _logger.e('AuthNotifier: Error refreshing profile', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error refreshing profile: $e',
      );
    }
  }

  /// Starts streaming user profile changes for the given user ID.
  void _startUserProfileStream(UserId userId) {
    _logger.d('AuthNotifier: Starting user profile stream for user $userId');
    
    try {
      final streamUseCase = ref.read(streamUserProfileUseCaseProvider);
      _profileSubscription?.cancel();
      _profileSubscription = streamUseCase.call(userId: userId).listen(
        (result) {
          result.fold(
            (failure) {
              _logger.e('AuthNotifier: User profile stream error', error: failure.message);
              state = state.copyWith(
                errorMessage: failure.message,
                status: AuthStatus.error,
              );
            },
            (user) {
              _logger.d('AuthNotifier: User profile updated for user ${user?.id}');
              state = state.copyWith(
                user: user,
                errorMessage: null,
                status: AuthStatus.authenticated,
              );
            },
          );
        },
        onError: (error) {
          _logger.e('AuthNotifier: User profile stream error', error: error);
          state = state.copyWith(
            errorMessage: 'Error streaming user profile: $error',
            status: AuthStatus.error,
          );
        },
      );
    } catch (e) {
      _logger.e('AuthNotifier: Error starting user profile stream', error: e);
    }
  }

  /// Stops listening to user profile changes.
  void _stopUserProfileStream() {
    _logger.d('AuthNotifier: Stopping user profile stream');
    _profileSubscription?.cancel();
    _profileSubscription = null;
  }

  /// Clears any error messages.
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Gets the current user ID.
  String? get currentUserId => state.user?.id.value;

  /// Gets the current user's family ID.
  String? get userFamilyId => state.user?.familyId.value;

  /// Gets the display name of the current user.
  String? get displayName => state.user?.name;

  /// Gets the current user's email.
  String? get userEmail => state.user?.email.value;

  /// Gets the current user's photo URL.
  String? get photoUrl => state.user?.photoUrl;

  /// Checks if the user is currently logged in.
  bool get isLoggedIn => state.status == AuthStatus.authenticated;

  /// Gets the current authentication status.
  AuthStatus get status => state.status;

  /// Gets the current error message.
  String? get errorMessage => state.errorMessage;

  /// Checks if authentication is currently loading.
  bool get isLoading => state.isLoading;

  /// Gets the current user profile.
  User? get currentUserProfile => state.user;

  /// Resets password for the given email.
  Future<void> resetPassword(String emailStr) async {
    _logger.d('AuthNotifier: Resetting password for $emailStr');
    
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final email = Email(emailStr);
      final resetPasswordUseCase = ref.read(resetPasswordUseCaseProvider);
      final result = await resetPasswordUseCase.call(email);

      result.fold(
        (failure) {
          _logger.e('AuthNotifier: Password reset failed', error: failure.message);
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
        },
        (_) {
          _logger.d('AuthNotifier: Password reset successful');
          state = state.copyWith(
            isLoading: false,
            errorMessage: null,
          );
        },
      );
    } catch (e) {
      _logger.e('AuthNotifier: Unexpected error during password reset', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: $e',
      );
    }
  }
} 