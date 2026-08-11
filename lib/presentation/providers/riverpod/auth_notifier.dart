import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/join_failure_message.dart';
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
  StreamSubscription<dynamic>? _authSubscription;

  /// The user whose profile [_profileSubscription] is currently following.
  /// Lets the auth listener tell a genuinely new session apart from Firebase
  /// re-emitting the one already being streamed (it does that on token
  /// refresh).
  UserId? _streamedUserId;

  @override
  AuthState build() {
    _logger.d('AuthNotifier: Building initial state');
    ref.onDispose(_stopUserProfileStream);
    ref.onDispose(_stopAuthStateStream);

    final authRepository = ref.read(authRepositoryProvider);

    // Follow the session for as long as this notifier lives. Reading
    // currentUser once was not enough: Firebase restores a persisted session
    // asynchronously, so a notifier built during that window (LoginScreen
    // watches it) kept state.user null for good — FamilyGate then held the
    // splash open with no way out but signing out. It also missed sessions
    // dropped from elsewhere, leaving a signed-out user looking signed in.
    _stopAuthStateStream();
    _authSubscription =
        authRepository.authStateChanges.listen(_onAuthStateChanged);

    // Still read synchronously as well: when the session is already restored
    // there is no reason to render a signed-out frame first.
    final firebaseUser = authRepository.currentUser;
    if (firebaseUser != null) {
      final userId = UserId(firebaseUser.uid as String);
      _logger.d('AuthNotifier: Restoring session for user $userId');
      _startUserProfileStream(userId);
      return const AuthState(status: AuthStatus.authenticated);
    }
    return const AuthState();
  }

  /// Reconciles state with a session change that did not come from one of this
  /// notifier's own sign-in methods.
  void _onAuthStateChanged(dynamic firebaseUser) {
    if (firebaseUser == null) {
      if (_streamedUserId == null && state.user == null) return;
      _logger.d('AuthNotifier: Session ended outside the notifier');
      _stopUserProfileStream();
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    final userId = UserId(firebaseUser.uid as String);
    if (userId == _streamedUserId) return;

    // A sign-in flow in progress owns this transition — it decides whether the
    // profile exists and starts the stream itself. Stepping in here would
    // overwrite `needsProfileCompletion` with a bare "authenticated, no
    // profile", which is the dead end this whole change exists to remove.
    if (state.status == AuthStatus.authenticating ||
        state.status == AuthStatus.needsProfileCompletion) {
      return;
    }

    _logger.d('AuthNotifier: Session appeared for user $userId');
    _startUserProfileStream(userId);
    state = state.copyWith(
      status: AuthStatus.authenticated,
      errorMessage: null,
    );
  }

  void _stopAuthStateStream() {
    _authSubscription?.cancel();
    _authSubscription = null;
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
          ref.read(analyticsProvider).log(
                AnalyticsEventName.signedIn,
                userId: userId.value,
                params: const {'method': 'email'},
              );
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

  /// Signs in with Apple. A first-time adult becomes a [UserRole.parent].
  Future<void> signInWithApple() =>
      _oauth(() => ref.read(authRepositoryProvider).signInWithApple());

  /// Signs in with Google. A first-time adult becomes a [UserRole.parent].
  Future<void> signInWithGoogle() =>
      _oauth(() => ref.read(authRepositoryProvider).signInWithGoogle());

  /// Runs an OAuth [signIn] and reconciles the resulting Firebase session with
  /// the Firestore profile.
  Future<void> _oauth(Future<dynamic> Function() signIn) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      status: AuthStatus.authenticating,
    );

    try {
      await _afterOAuth(await signIn());
    } on AuthException catch (e) {
      if (e.code == 'SIGN_IN_CANCELLED') {
        // The user dismissed the provider sheet. That is a choice, not a
        // failure, so it must not surface as an error.
        _logger.d('AuthNotifier: OAuth sign-in cancelled by user');
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
          status: AuthStatus.unauthenticated,
        );
        return;
      }
      _logger.e('AuthNotifier: OAuth sign-in failed', error: e.message);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        status: AuthStatus.error,
      );
    } catch (e) {
      _logger.e('AuthNotifier: Unexpected error during OAuth sign in', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: $e',
        status: AuthStatus.error,
      );
    }
  }

  /// Creates the Firestore profile for a first-time OAuth user, then starts the
  /// profile stream. An existing profile is left untouched, so a returning
  /// child is never promoted to parent.
  Future<void> _afterOAuth(dynamic firebaseUser) async {
    final userId = UserId(firebaseUser.uid as String);

    final lookup = await ref
        .read(getUserProfileUseCaseProvider)
        .call(userId: userId);

    // Only a NotFoundFailure means "new user". Any other failure is a real
    // problem (network, permissions) and must not be mistaken for one.
    final lookupFailure = lookup.fold((failure) => failure, (_) => null);
    if (lookupFailure != null && lookupFailure is! NotFoundFailure) {
      _logger.e('AuthNotifier: Could not read profile after OAuth',
          error: lookupFailure.message);
      // Signed in but the profile couldn't be read. Keep the session so the
      // user can retry from the complete-profile screen instead of losing any
      // Apple name/email data by signing out.
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Could not load your account: ${lookupFailure.message}. Please try again.',
        status: AuthStatus.needsProfileCompletion,
      );
      return;
    }

    if (lookupFailure is NotFoundFailure) {
      final email = firebaseUser.email as String?;
      if (email == null || email.trim().isEmpty) {
        _logger.e('AuthNotifier: OAuth provider returned no email');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Could not get your email address from the sign-in '
              'provider. Please try the other provider (Apple/Google).',
          status: AuthStatus.error,
        );
        return;
      }

      final displayName = firebaseUser.displayName as String?;
      final success = await _initializeUserProfile(
        userId: userId,
        name: displayName?.trim().isNotEmpty == true
            ? displayName!.trim()
            : email.split('@').first,
        email: email.trim().toLowerCase(),
      );
      if (!success) return;
    }

    ref.read(analyticsProvider).log(
          AnalyticsEventName.signedIn,
          userId: userId.value,
          params: const {'method': 'oauth'},
        );
    _startUserProfileStream(userId);
    state = state.copyWith(
      isLoading: false,
      status: AuthStatus.authenticated,
    );
  }

  /// Creates or recreates the user's Firestore profile and starts streaming it.
  ///
  /// Returns `true` on success. On failure, sets
  /// [AuthStatus.needsProfileCompletion] with the real error message and keeps
  /// the Firebase session alive so the caller can retry.
  Future<bool> _initializeUserProfile({
    required UserId userId,
    required String name,
    required String email,
  }) async {
    final initResult = await ref.read(initializeUserDataUseCaseProvider).call(
          userId: userId,
          name: name.trim(),
          email: email.trim().toLowerCase(),
          role: UserRole.parent,
        );

    final initFailure = initResult.fold((failure) => failure, (_) => null);
    if (initFailure != null) {
      _logger.e('AuthNotifier: Failed to create OAuth user profile',
          error: initFailure.message);
      // Keep the Firebase session alive so the user can retry on a dedicated
      // "complete profile" screen rather than being kicked back to Login with a
      // swallowed error. Apple Sign-In only returns name/email once; signing out
      // and starting over can lose that data permanently.
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Could not finish setting up your account: ${initFailure.message}',
        status: AuthStatus.needsProfileCompletion,
      );
      return false;
    }
    _logger.d('AuthNotifier: Created parent profile for user $userId');
    return true;
  }

  /// Completes an OAuth profile by creating the Firestore document with the
  /// name and email the user supplies (or confirms) after an initial failure.
  ///
  /// On success the profile stream starts and the user is authenticated.
  /// On failure the session stays alive and [AuthStatus.needsProfileCompletion]
  /// remains set with the real error message.
  Future<void> completeProfile({
    required String name,
    required String email,
  }) async {
    _logger.d('AuthNotifier: Completing profile for ${state.user?.id ?? "current user"}');

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      status: AuthStatus.needsProfileCompletion,
    );

    final firebaseUser = ref.read(authRepositoryProvider).currentUser;
    if (firebaseUser == null) {
      _logger.w('AuthNotifier: completeProfile called with no Firebase user');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'You are no longer signed in. Please sign in again.',
        status: AuthStatus.unauthenticated,
      );
      return;
    }

    final userId = UserId(firebaseUser.uid as String);
    final success = await _initializeUserProfile(
      userId: userId,
      name: name,
      email: email,
    );
    if (!success) return;

    _startUserProfileStream(userId);
    state = state.copyWith(
      isLoading: false,
      status: AuthStatus.authenticated,
    );
  }

  /// Joins a family as a child: anonymous account + profile + membership.
  ///
  /// On failure the use case has already rolled the anonymous account back,
  /// so the state returns to unauthenticated with the error message set.
  Future<void> joinFamilyAsChild({
    required String name,
    required String inviteCode,
  }) async {
    _logger.d('AuthNotifier: Child joining family with code $inviteCode');
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      status: AuthStatus.authenticating,
    );

    final result = await ref
        .read(joinFamilyAsChildUseCaseProvider)
        .call(name: name, inviteCode: inviteCode);

    result.fold(
      (failure) {
        // Log the technical text, show the human one — this screen is the one
        // a child uses, and it used to print raw Firestore errors at them.
        _logger.e('AuthNotifier: Child join failed: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: joinFailureMessage(failure),
          status: AuthStatus.unauthenticated,
        );
      },
      (family) {
        final userId =
            UserId(ref.read(authRepositoryProvider).currentUser.uid as String);
        _logger.d('AuthNotifier: Child joined family as $userId');
        final analytics = ref.read(analyticsProvider);
        analytics.log(
          AnalyticsEventName.signedIn,
          userId: userId.value,
          params: const {'method': 'anonymous'},
        );
        analytics.log(
          AnalyticsEventName.familyJoined,
          userId: userId.value,
          familyId: family.id.value,
          params: const {'role': 'child'},
        );
        _startUserProfileStream(userId);
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.authenticated,
        );
      },
    );
  }

  /// Leaves the family the current user belongs to.
  ///
  /// Returns ``null`` on success, or a human-readable error message on failure
  /// so the caller can surface it. The user's profile stream clears the
  /// ``familyId`` on success, which routes them back to family onboarding.
  Future<String?> leaveFamily() async {
    final user = state.user;
    if (user == null) {
      return 'You must be signed in to leave a family.';
    }
    _logger.d('AuthNotifier: ${user.id} leaving family ${user.familyId}');

    final result =
        await ref.read(leaveFamilyUseCaseProvider).call(userId: user.id);

    return result.fold(
      (failure) {
        _logger.e('AuthNotifier: Leave family failed: ${failure.message}');
        return failure.message;
      },
      (_) {
        _logger.i('AuthNotifier: ${user.id} left their family');
        return null;
      },
    );
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

  /// Permanently deletes the signed-in user's account and profile.
  ///
  /// On success the state becomes unauthenticated (authStateChanges routing
  /// returns the app to the login screen). On failure — most commonly
  /// Firebase requiring a recent sign-in — the session survives and
  /// `errorMessage` carries the explanation.
  Future<void> deleteAccount() async {
    final user = state.user;
    if (user == null) {
      _logger.w('AuthNotifier: Cannot delete account - no user profile');
      state = state.copyWith(
        errorMessage: 'No signed-in user to delete',
      );
      return;
    }

    _logger.d('AuthNotifier: Deleting account for ${user.id}');
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result =
        await ref.read(deleteAccountUseCaseProvider).call(user: user);

    result.fold(
      (failure) {
        _logger.e('AuthNotifier: Account deletion failed: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (_) {
        _logger.d('AuthNotifier: Account deleted');
        _stopUserProfileStream();
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
      },
    );
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
      _streamedUserId = userId;
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
    _streamedUserId = null;
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
  String? get userEmail => state.user?.email?.value;

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

    // Checked before anything else: `Email` throws on a bad address, and the
    // catch below would stringify that ArgumentError onto the login screen —
    // "Invalid argument(s): Invalid email format:" is not a sentence anyone
    // should be shown, least of all someone who just tapped a button with an
    // empty field.
    final email = Email.tryCreate(emailStr.trim());
    if (email == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Enter the email address you signed up with, then tap '
            'Forgot Password.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
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