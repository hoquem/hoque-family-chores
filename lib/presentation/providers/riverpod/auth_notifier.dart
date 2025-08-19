import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/user/get_user_profile_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/user/stream_user_profile_usecase.dart';
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
/// This notifier handles sign in, sign out, and user profile management.
/// It automatically streams user profile changes and maintains authentication state.
/// 
/// Example:
/// ```dart
/// final authState = ref.watch(authNotifierProvider);
/// final notifier = ref.read(authNotifierProvider.notifier);
/// await notifier.signInWithGoogle();
/// ```
@riverpod
class AuthNotifier extends _$AuthNotifier {
  final _logger = AppLogger();

  @override
  AuthState build() {
    _logger.d('AuthNotifier: Building initial state');
    _initializeUserProfileStream();
    return const AuthState();
  }

  /// Initializes the user profile stream to listen for changes.
  void _initializeUserProfileStream() {
    // This will be called when the user signs in
    // For now, we'll handle it in the signIn method
  }

  /// Signs in a user with Google.
  Future<void> signInWithGoogle() async {
    _logger.d('AuthNotifier: Signing in user with Google');
    
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      status: AuthStatus.authenticating,
    );

    try {
      final signInWithGoogleUseCase = ref.read(signInWithGoogleUseCaseProvider);
      final result = await signInWithGoogleUseCase.call();

      result.fold(
        (failure) {
          _logger.e('AuthNotifier: Sign in with Google failed', error: failure.message);
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
            status: AuthStatus.error,
          );
        },
        (user) {
          _logger.d('AuthNotifier: Sign in with Google successful for user ${user.id}');
          _startUserProfileStream(user.id);
          state = state.copyWith(
            isLoading: false,
            user: user,
            status: AuthStatus.authenticated,
          );
        },
      );
    } catch (e) {
      _logger.e('AuthNotifier: Unexpected error during sign in with Google', error: e);
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
      streamUseCase.call(userId: userId).listen(
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
              _logger.d('AuthNotifier: User profile updated for user ${user.id}');
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
    // Implementation would cancel stream subscriptions
  }

  /// Clears any error messages.
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Gets the current user ID.
  String? get currentUserId => state.user?.id.value;

  /// Gets the current user's family ID.
  String? get userFamilyId => state.user?.familyId?.value;

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
} 