// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gamificationNotifierHash() =>
    r'7a0fc88fda55581334d6770523f6c1da9fd2a2e7';

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

abstract class _$GamificationNotifier
    extends BuildlessAutoDisposeAsyncNotifier<GamificationData> {
  late final UserId userId;

  FutureOr<GamificationData> build(UserId userId);
}

/// Manages gamification data including badges, rewards, achievements, and points.
///
/// This notifier handles all gamification-related operations including
/// awarding points, badges, achievements, and redeeming rewards.
///
/// Example:
/// ```dart
/// final gamificationAsync = ref.watch(gamificationNotifierProvider(userId));
/// final notifier = ref.read(gamificationNotifierProvider(userId).notifier);
/// await notifier.awardPoints(10, familyId);
/// ```
///
/// Copied from [GamificationNotifier].
@ProviderFor(GamificationNotifier)
const gamificationNotifierProvider = GamificationNotifierFamily();

/// Manages gamification data including badges, rewards, achievements, and points.
///
/// This notifier handles all gamification-related operations including
/// awarding points, badges, achievements, and redeeming rewards.
///
/// Example:
/// ```dart
/// final gamificationAsync = ref.watch(gamificationNotifierProvider(userId));
/// final notifier = ref.read(gamificationNotifierProvider(userId).notifier);
/// await notifier.awardPoints(10, familyId);
/// ```
///
/// Copied from [GamificationNotifier].
class GamificationNotifierFamily extends Family<AsyncValue<GamificationData>> {
  /// Manages gamification data including badges, rewards, achievements, and points.
  ///
  /// This notifier handles all gamification-related operations including
  /// awarding points, badges, achievements, and redeeming rewards.
  ///
  /// Example:
  /// ```dart
  /// final gamificationAsync = ref.watch(gamificationNotifierProvider(userId));
  /// final notifier = ref.read(gamificationNotifierProvider(userId).notifier);
  /// await notifier.awardPoints(10, familyId);
  /// ```
  ///
  /// Copied from [GamificationNotifier].
  const GamificationNotifierFamily();

  /// Manages gamification data including badges, rewards, achievements, and points.
  ///
  /// This notifier handles all gamification-related operations including
  /// awarding points, badges, achievements, and redeeming rewards.
  ///
  /// Example:
  /// ```dart
  /// final gamificationAsync = ref.watch(gamificationNotifierProvider(userId));
  /// final notifier = ref.read(gamificationNotifierProvider(userId).notifier);
  /// await notifier.awardPoints(10, familyId);
  /// ```
  ///
  /// Copied from [GamificationNotifier].
  GamificationNotifierProvider call(UserId userId) {
    return GamificationNotifierProvider(userId);
  }

  @override
  GamificationNotifierProvider getProviderOverride(
    covariant GamificationNotifierProvider provider,
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
  String? get name => r'gamificationNotifierProvider';
}

/// Manages gamification data including badges, rewards, achievements, and points.
///
/// This notifier handles all gamification-related operations including
/// awarding points, badges, achievements, and redeeming rewards.
///
/// Example:
/// ```dart
/// final gamificationAsync = ref.watch(gamificationNotifierProvider(userId));
/// final notifier = ref.read(gamificationNotifierProvider(userId).notifier);
/// await notifier.awardPoints(10, familyId);
/// ```
///
/// Copied from [GamificationNotifier].
class GamificationNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          GamificationNotifier,
          GamificationData
        > {
  /// Manages gamification data including badges, rewards, achievements, and points.
  ///
  /// This notifier handles all gamification-related operations including
  /// awarding points, badges, achievements, and redeeming rewards.
  ///
  /// Example:
  /// ```dart
  /// final gamificationAsync = ref.watch(gamificationNotifierProvider(userId));
  /// final notifier = ref.read(gamificationNotifierProvider(userId).notifier);
  /// await notifier.awardPoints(10, familyId);
  /// ```
  ///
  /// Copied from [GamificationNotifier].
  GamificationNotifierProvider(UserId userId)
    : this._internal(
        () => GamificationNotifier()..userId = userId,
        from: gamificationNotifierProvider,
        name: r'gamificationNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$gamificationNotifierHash,
        dependencies: GamificationNotifierFamily._dependencies,
        allTransitiveDependencies:
            GamificationNotifierFamily._allTransitiveDependencies,
        userId: userId,
      );

  GamificationNotifierProvider._internal(
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
  FutureOr<GamificationData> runNotifierBuild(
    covariant GamificationNotifier notifier,
  ) {
    return notifier.build(userId);
  }

  @override
  Override overrideWith(GamificationNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: GamificationNotifierProvider._internal(
        () => create()..userId = userId,
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
  AutoDisposeAsyncNotifierProviderElement<
    GamificationNotifier,
    GamificationData
  >
  createElement() {
    return _GamificationNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GamificationNotifierProvider && other.userId == userId;
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
mixin GamificationNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<GamificationData> {
  /// The parameter `userId` of this provider.
  UserId get userId;
}

class _GamificationNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          GamificationNotifier,
          GamificationData
        >
    with GamificationNotifierRef {
  _GamificationNotifierProviderElement(super.provider);

  @override
  UserId get userId => (origin as GamificationNotifierProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
