// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rewards_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$requestRedemptionHash() => r'7b14c0f8f41bec1efc806a92be414ce0b139bba6';

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

/// Provider for requesting a reward redemption
///
/// Copied from [requestRedemption].
@ProviderFor(requestRedemption)
const requestRedemptionProvider = RequestRedemptionFamily();

/// Provider for requesting a reward redemption
///
/// Copied from [requestRedemption].
class RequestRedemptionFamily extends Family<AsyncValue<RewardRedemption>> {
  /// Provider for requesting a reward redemption
  ///
  /// Copied from [requestRedemption].
  const RequestRedemptionFamily();

  /// Provider for requesting a reward redemption
  ///
  /// Copied from [requestRedemption].
  RequestRedemptionProvider call(
    FamilyId familyId,
    UserId userId,
    String rewardId,
  ) {
    return RequestRedemptionProvider(familyId, userId, rewardId);
  }

  @override
  RequestRedemptionProvider getProviderOverride(
    covariant RequestRedemptionProvider provider,
  ) {
    return call(provider.familyId, provider.userId, provider.rewardId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'requestRedemptionProvider';
}

/// Provider for requesting a reward redemption
///
/// Copied from [requestRedemption].
class RequestRedemptionProvider
    extends AutoDisposeFutureProvider<RewardRedemption> {
  /// Provider for requesting a reward redemption
  ///
  /// Copied from [requestRedemption].
  RequestRedemptionProvider(FamilyId familyId, UserId userId, String rewardId)
    : this._internal(
        (ref) => requestRedemption(
          ref as RequestRedemptionRef,
          familyId,
          userId,
          rewardId,
        ),
        from: requestRedemptionProvider,
        name: r'requestRedemptionProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$requestRedemptionHash,
        dependencies: RequestRedemptionFamily._dependencies,
        allTransitiveDependencies:
            RequestRedemptionFamily._allTransitiveDependencies,
        familyId: familyId,
        userId: userId,
        rewardId: rewardId,
      );

  RequestRedemptionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.familyId,
    required this.userId,
    required this.rewardId,
  }) : super.internal();

  final FamilyId familyId;
  final UserId userId;
  final String rewardId;

  @override
  Override overrideWith(
    FutureOr<RewardRedemption> Function(RequestRedemptionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RequestRedemptionProvider._internal(
        (ref) => create(ref as RequestRedemptionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        familyId: familyId,
        userId: userId,
        rewardId: rewardId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<RewardRedemption> createElement() {
    return _RequestRedemptionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RequestRedemptionProvider &&
        other.familyId == familyId &&
        other.userId == userId &&
        other.rewardId == rewardId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, familyId.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, rewardId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RequestRedemptionRef on AutoDisposeFutureProviderRef<RewardRedemption> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;

  /// The parameter `userId` of this provider.
  UserId get userId;

  /// The parameter `rewardId` of this provider.
  String get rewardId;
}

class _RequestRedemptionProviderElement
    extends AutoDisposeFutureProviderElement<RewardRedemption>
    with RequestRedemptionRef {
  _RequestRedemptionProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as RequestRedemptionProvider).familyId;
  @override
  UserId get userId => (origin as RequestRedemptionProvider).userId;
  @override
  String get rewardId => (origin as RequestRedemptionProvider).rewardId;
}

String _$rewardsNotifierHash() => r'2e0a9b0d246e1baaa88bdd2e9bfaf3420be167e1';

abstract class _$RewardsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Reward>> {
  late final FamilyId familyId;

  FutureOr<List<Reward>> build(FamilyId familyId);
}

/// Manages rewards list state
///
/// Copied from [RewardsNotifier].
@ProviderFor(RewardsNotifier)
const rewardsNotifierProvider = RewardsNotifierFamily();

/// Manages rewards list state
///
/// Copied from [RewardsNotifier].
class RewardsNotifierFamily extends Family<AsyncValue<List<Reward>>> {
  /// Manages rewards list state
  ///
  /// Copied from [RewardsNotifier].
  const RewardsNotifierFamily();

  /// Manages rewards list state
  ///
  /// Copied from [RewardsNotifier].
  RewardsNotifierProvider call(FamilyId familyId) {
    return RewardsNotifierProvider(familyId);
  }

  @override
  RewardsNotifierProvider getProviderOverride(
    covariant RewardsNotifierProvider provider,
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
  String? get name => r'rewardsNotifierProvider';
}

/// Manages rewards list state
///
/// Copied from [RewardsNotifier].
class RewardsNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<RewardsNotifier, List<Reward>> {
  /// Manages rewards list state
  ///
  /// Copied from [RewardsNotifier].
  RewardsNotifierProvider(FamilyId familyId)
    : this._internal(
        () => RewardsNotifier()..familyId = familyId,
        from: rewardsNotifierProvider,
        name: r'rewardsNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$rewardsNotifierHash,
        dependencies: RewardsNotifierFamily._dependencies,
        allTransitiveDependencies:
            RewardsNotifierFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  RewardsNotifierProvider._internal(
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
  FutureOr<List<Reward>> runNotifierBuild(covariant RewardsNotifier notifier) {
    return notifier.build(familyId);
  }

  @override
  Override overrideWith(RewardsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: RewardsNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<RewardsNotifier, List<Reward>>
  createElement() {
    return _RewardsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RewardsNotifierProvider && other.familyId == familyId;
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
mixin RewardsNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<Reward>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _RewardsNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<RewardsNotifier, List<Reward>>
    with RewardsNotifierRef {
  _RewardsNotifierProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as RewardsNotifierProvider).familyId;
}

String _$pendingRedemptionsNotifierHash() =>
    r'767fcd6865e4fa325aed5c9f7b5dcc04c0ca8ef9';

abstract class _$PendingRedemptionsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<RewardRedemption>> {
  late final FamilyId familyId;

  FutureOr<List<RewardRedemption>> build(FamilyId familyId);
}

/// Manages pending redemptions state
///
/// Copied from [PendingRedemptionsNotifier].
@ProviderFor(PendingRedemptionsNotifier)
const pendingRedemptionsNotifierProvider = PendingRedemptionsNotifierFamily();

/// Manages pending redemptions state
///
/// Copied from [PendingRedemptionsNotifier].
class PendingRedemptionsNotifierFamily
    extends Family<AsyncValue<List<RewardRedemption>>> {
  /// Manages pending redemptions state
  ///
  /// Copied from [PendingRedemptionsNotifier].
  const PendingRedemptionsNotifierFamily();

  /// Manages pending redemptions state
  ///
  /// Copied from [PendingRedemptionsNotifier].
  PendingRedemptionsNotifierProvider call(FamilyId familyId) {
    return PendingRedemptionsNotifierProvider(familyId);
  }

  @override
  PendingRedemptionsNotifierProvider getProviderOverride(
    covariant PendingRedemptionsNotifierProvider provider,
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
  String? get name => r'pendingRedemptionsNotifierProvider';
}

/// Manages pending redemptions state
///
/// Copied from [PendingRedemptionsNotifier].
class PendingRedemptionsNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          PendingRedemptionsNotifier,
          List<RewardRedemption>
        > {
  /// Manages pending redemptions state
  ///
  /// Copied from [PendingRedemptionsNotifier].
  PendingRedemptionsNotifierProvider(FamilyId familyId)
    : this._internal(
        () => PendingRedemptionsNotifier()..familyId = familyId,
        from: pendingRedemptionsNotifierProvider,
        name: r'pendingRedemptionsNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$pendingRedemptionsNotifierHash,
        dependencies: PendingRedemptionsNotifierFamily._dependencies,
        allTransitiveDependencies:
            PendingRedemptionsNotifierFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  PendingRedemptionsNotifierProvider._internal(
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
  FutureOr<List<RewardRedemption>> runNotifierBuild(
    covariant PendingRedemptionsNotifier notifier,
  ) {
    return notifier.build(familyId);
  }

  @override
  Override overrideWith(PendingRedemptionsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: PendingRedemptionsNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<
    PendingRedemptionsNotifier,
    List<RewardRedemption>
  >
  createElement() {
    return _PendingRedemptionsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingRedemptionsNotifierProvider &&
        other.familyId == familyId;
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
mixin PendingRedemptionsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<RewardRedemption>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _PendingRedemptionsNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          PendingRedemptionsNotifier,
          List<RewardRedemption>
        >
    with PendingRedemptionsNotifierRef {
  _PendingRedemptionsNotifierProviderElement(super.provider);

  @override
  FamilyId get familyId =>
      (origin as PendingRedemptionsNotifierProvider).familyId;
}

String _$userRedemptionsNotifierHash() =>
    r'd6fd0eba845208135b04a54ef345c4a682c4caa4';

abstract class _$UserRedemptionsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<RewardRedemption>> {
  late final FamilyId familyId;
  late final UserId userId;

  FutureOr<List<RewardRedemption>> build(FamilyId familyId, UserId userId);
}

/// Manages user redemption history
///
/// Copied from [UserRedemptionsNotifier].
@ProviderFor(UserRedemptionsNotifier)
const userRedemptionsNotifierProvider = UserRedemptionsNotifierFamily();

/// Manages user redemption history
///
/// Copied from [UserRedemptionsNotifier].
class UserRedemptionsNotifierFamily
    extends Family<AsyncValue<List<RewardRedemption>>> {
  /// Manages user redemption history
  ///
  /// Copied from [UserRedemptionsNotifier].
  const UserRedemptionsNotifierFamily();

  /// Manages user redemption history
  ///
  /// Copied from [UserRedemptionsNotifier].
  UserRedemptionsNotifierProvider call(FamilyId familyId, UserId userId) {
    return UserRedemptionsNotifierProvider(familyId, userId);
  }

  @override
  UserRedemptionsNotifierProvider getProviderOverride(
    covariant UserRedemptionsNotifierProvider provider,
  ) {
    return call(provider.familyId, provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userRedemptionsNotifierProvider';
}

/// Manages user redemption history
///
/// Copied from [UserRedemptionsNotifier].
class UserRedemptionsNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          UserRedemptionsNotifier,
          List<RewardRedemption>
        > {
  /// Manages user redemption history
  ///
  /// Copied from [UserRedemptionsNotifier].
  UserRedemptionsNotifierProvider(FamilyId familyId, UserId userId)
    : this._internal(
        () =>
            UserRedemptionsNotifier()
              ..familyId = familyId
              ..userId = userId,
        from: userRedemptionsNotifierProvider,
        name: r'userRedemptionsNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$userRedemptionsNotifierHash,
        dependencies: UserRedemptionsNotifierFamily._dependencies,
        allTransitiveDependencies:
            UserRedemptionsNotifierFamily._allTransitiveDependencies,
        familyId: familyId,
        userId: userId,
      );

  UserRedemptionsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.familyId,
    required this.userId,
  }) : super.internal();

  final FamilyId familyId;
  final UserId userId;

  @override
  FutureOr<List<RewardRedemption>> runNotifierBuild(
    covariant UserRedemptionsNotifier notifier,
  ) {
    return notifier.build(familyId, userId);
  }

  @override
  Override overrideWith(UserRedemptionsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: UserRedemptionsNotifierProvider._internal(
        () =>
            create()
              ..familyId = familyId
              ..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        familyId: familyId,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    UserRedemptionsNotifier,
    List<RewardRedemption>
  >
  createElement() {
    return _UserRedemptionsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserRedemptionsNotifierProvider &&
        other.familyId == familyId &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, familyId.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserRedemptionsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<RewardRedemption>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;

  /// The parameter `userId` of this provider.
  UserId get userId;
}

class _UserRedemptionsNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          UserRedemptionsNotifier,
          List<RewardRedemption>
        >
    with UserRedemptionsNotifierRef {
  _UserRedemptionsNotifierProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as UserRedemptionsNotifierProvider).familyId;
  @override
  UserId get userId => (origin as UserRedemptionsNotifierProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
