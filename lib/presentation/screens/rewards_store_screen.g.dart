// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rewards_store_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userPointsHash() => r'bb6d0e3a874bc3090a817db240ee70b467920834';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider for user's current points/stars
///
/// Copied from [userPoints].
@ProviderFor(userPoints)
const userPointsProvider = UserPointsFamily();

/// Provider for user's current points/stars
///
/// Copied from [userPoints].
class UserPointsFamily extends Family<AsyncValue<int>> {
  /// Provider for user's current points/stars
  ///
  /// Copied from [userPoints].
  const UserPointsFamily();

  /// Provider for user's current points/stars
  ///
  /// Copied from [userPoints].
  UserPointsProvider call(UserId userId) {
    return UserPointsProvider(userId);
  }

  @override
  UserPointsProvider getProviderOverride(
    covariant UserPointsProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userPointsProvider';
}

/// Provider for user's current points/stars
///
/// Copied from [userPoints].
class UserPointsProvider extends AutoDisposeFutureProvider<int> {
  /// Provider for user's current points/stars
  ///
  /// Copied from [userPoints].
  UserPointsProvider(UserId userId)
    : this._internal(
        (ref) => userPoints(ref as UserPointsRef, userId),
        from: userPointsProvider,
        name: r'userPointsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$userPointsHash,
        dependencies: UserPointsFamily._dependencies,
        allTransitiveDependencies: UserPointsFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserPointsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final UserId userId;

  @override
  Override overrideWith(FutureOr<int> Function(UserPointsRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: UserPointsProvider._internal(
        (ref) => create(ref as UserPointsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _UserPointsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserPointsProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserPointsRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `userId` of this provider.
  UserId get userId;
}

class _UserPointsProviderElement extends AutoDisposeFutureProviderElement<int>
    with UserPointsRef {
  _UserPointsProviderElement(super.provider);

  @override
  UserId get userId => (origin as UserPointsProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
