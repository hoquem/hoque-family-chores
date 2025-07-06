// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authNotifierHash() => r'b5ef9fd9da9d0bac893ea45e4d79c69a05aab999';

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
///
/// Copied from [AuthNotifier].
@ProviderFor(AuthNotifier)
final authNotifierProvider =
    AutoDisposeNotifierProvider<AuthNotifier, AuthState>.internal(
      AuthNotifier.new,
      name: r'authNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$authNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthNotifier = AutoDisposeNotifier<AuthState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
