// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$rewardNotifierHash() => r'667ef87947efe5290224757f02e78e5cd32a0df2';

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

abstract class _$RewardNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Reward>> {
  late final FamilyId familyId;

  FutureOr<List<Reward>> build(FamilyId familyId);
}

/// Manages reward-related state and operations.
///
/// This notifier handles loading rewards for a family and provides
/// methods for reward-related operations.
///
/// Example:
/// ```dart
/// final rewardsAsync = ref.watch(rewardNotifierProvider(familyId));
/// final notifier = ref.read(rewardNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
///
/// Copied from [RewardNotifier].
@ProviderFor(RewardNotifier)
const rewardNotifierProvider = RewardNotifierFamily();

/// Manages reward-related state and operations.
///
/// This notifier handles loading rewards for a family and provides
/// methods for reward-related operations.
///
/// Example:
/// ```dart
/// final rewardsAsync = ref.watch(rewardNotifierProvider(familyId));
/// final notifier = ref.read(rewardNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
///
/// Copied from [RewardNotifier].
class RewardNotifierFamily extends Family<AsyncValue<List<Reward>>> {
  /// Manages reward-related state and operations.
  ///
  /// This notifier handles loading rewards for a family and provides
  /// methods for reward-related operations.
  ///
  /// Example:
  /// ```dart
  /// final rewardsAsync = ref.watch(rewardNotifierProvider(familyId));
  /// final notifier = ref.read(rewardNotifierProvider(familyId).notifier);
  /// await notifier.refresh();
  /// ```
  ///
  /// Copied from [RewardNotifier].
  const RewardNotifierFamily();

  /// Manages reward-related state and operations.
  ///
  /// This notifier handles loading rewards for a family and provides
  /// methods for reward-related operations.
  ///
  /// Example:
  /// ```dart
  /// final rewardsAsync = ref.watch(rewardNotifierProvider(familyId));
  /// final notifier = ref.read(rewardNotifierProvider(familyId).notifier);
  /// await notifier.refresh();
  /// ```
  ///
  /// Copied from [RewardNotifier].
  RewardNotifierProvider call(FamilyId familyId) {
    return RewardNotifierProvider(familyId);
  }

  @override
  RewardNotifierProvider getProviderOverride(
    covariant RewardNotifierProvider provider,
  ) {
    return call(provider.familyId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'rewardNotifierProvider';
}

/// Manages reward-related state and operations.
///
/// This notifier handles loading rewards for a family and provides
/// methods for reward-related operations.
///
/// Example:
/// ```dart
/// final rewardsAsync = ref.watch(rewardNotifierProvider(familyId));
/// final notifier = ref.read(rewardNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
///
/// Copied from [RewardNotifier].
class RewardNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<RewardNotifier, List<Reward>> {
  /// Manages reward-related state and operations.
  ///
  /// This notifier handles loading rewards for a family and provides
  /// methods for reward-related operations.
  ///
  /// Example:
  /// ```dart
  /// final rewardsAsync = ref.watch(rewardNotifierProvider(familyId));
  /// final notifier = ref.read(rewardNotifierProvider(familyId).notifier);
  /// await notifier.refresh();
  /// ```
  ///
  /// Copied from [RewardNotifier].
  RewardNotifierProvider(FamilyId familyId)
    : this._internal(
        () => RewardNotifier()..familyId = familyId,
        from: rewardNotifierProvider,
        name: r'rewardNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$rewardNotifierHash,
        dependencies: RewardNotifierFamily._dependencies,
        allTransitiveDependencies:
            RewardNotifierFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  RewardNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.familyId,
  }) : super.internal();

  final FamilyId familyId;

  @override
  FutureOr<List<Reward>> runNotifierBuild(covariant RewardNotifier notifier) {
    return notifier.build(familyId);
  }

  @override
  Override overrideWith(RewardNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: RewardNotifierProvider._internal(
        () => create()..familyId = familyId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        familyId: familyId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<RewardNotifier, List<Reward>>
  createElement() {
    return _RewardNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RewardNotifierProvider && other.familyId == familyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, familyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RewardNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<Reward>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _RewardNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<RewardNotifier, List<Reward>>
    with RewardNotifierRef {
  _RewardNotifierProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as RewardNotifierProvider).familyId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
