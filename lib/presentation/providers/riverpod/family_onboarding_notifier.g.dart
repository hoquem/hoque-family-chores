// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_onboarding_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$familyOnboardingNotifierHash() =>
    r'3217d7e69d592260653990a57b7beace1869aa24';

/// Handles creating a family or joining one with an invite code.
///
/// On success the user's profile document is updated with the new familyId,
/// which propagates through the auth profile stream and switches the UI out
/// of onboarding automatically.
///
/// Copied from [FamilyOnboardingNotifier].
@ProviderFor(FamilyOnboardingNotifier)
final familyOnboardingNotifierProvider = AutoDisposeNotifierProvider<
  FamilyOnboardingNotifier,
  FamilyOnboardingState
>.internal(
  FamilyOnboardingNotifier.new,
  name: r'familyOnboardingNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$familyOnboardingNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FamilyOnboardingNotifier = AutoDisposeNotifier<FamilyOnboardingState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
