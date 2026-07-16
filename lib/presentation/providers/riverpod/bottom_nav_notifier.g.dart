// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bottom_nav_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bottomNavIndexNotifierHash() =>
    r'd61a300f3d17da3c52f51c8978f36e5b9b0dc2e9';

/// Currently selected bottom-navigation tab.
///
/// Lives in a provider so any screen can send the user to another tab,
/// e.g. the Home approval card opening the Tasks tab.
///
/// Copied from [BottomNavIndexNotifier].
@ProviderFor(BottomNavIndexNotifier)
final bottomNavIndexNotifierProvider =
    AutoDisposeNotifierProvider<BottomNavIndexNotifier, int>.internal(
      BottomNavIndexNotifier.new,
      name: r'bottomNavIndexNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$bottomNavIndexNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BottomNavIndexNotifier = AutoDisposeNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
