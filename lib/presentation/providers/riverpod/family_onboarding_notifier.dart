import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'family_onboarding_notifier.g.dart';

/// State for the family onboarding flow (create or join a family).
class FamilyOnboardingState {
  final bool isLoading;
  final String? error;

  const FamilyOnboardingState({this.isLoading = false, this.error});

  FamilyOnboardingState copyWith({bool? isLoading, String? error}) {
    return FamilyOnboardingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Handles creating a family or joining one with an invite code.
///
/// On success the user's profile document is updated with the new familyId,
/// which propagates through the auth profile stream and switches the UI out
/// of onboarding automatically.
@riverpod
class FamilyOnboardingNotifier extends _$FamilyOnboardingNotifier {
  final _logger = AppLogger();

  @override
  FamilyOnboardingState build() => const FamilyOnboardingState();

  /// Creates a new family; the creator becomes a parent.
  ///
  /// :returns: true on success.
  Future<bool> createFamily({
    required String name,
    required UserId creatorId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final createFamily = ref.read(createFamilyUseCaseProvider);
    final result = await createFamily.call(name: name, creatorId: creatorId);

    return result.fold(
      (failure) {
        _logger.e('FamilyOnboarding: create failed', error: failure.message);
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (family) {
        _logger.i('FamilyOnboarding: created family ${family.id}');
        state = state.copyWith(isLoading: false, error: null);
        return true;
      },
    );
  }

  /// Joins an existing family using its invite code.
  ///
  /// :returns: true on success.
  Future<bool> joinFamily({
    required String inviteCode,
    required UserId userId,
    required UserRole role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final joinFamily = ref.read(joinFamilyUseCaseProvider);
    final result = await joinFamily.call(
      inviteCode: inviteCode,
      userId: userId,
      role: role,
    );

    return result.fold(
      (failure) {
        _logger.e('FamilyOnboarding: join failed', error: failure.message);
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (family) {
        _logger.i('FamilyOnboarding: joined family ${family.id}');
        state = state.copyWith(isLoading: false, error: null);
        return true;
      },
    );
  }
}
