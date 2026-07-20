// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rewards_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$familyRewardsHash() => r'43b3caf8cb4ed701d3d8a2fb66d7e851d891c5b9';

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

/// The rewards a family offers.
///
/// Copied from [familyRewards].
@ProviderFor(familyRewards)
const familyRewardsProvider = FamilyRewardsFamily();

/// The rewards a family offers.
///
/// Copied from [familyRewards].
class FamilyRewardsFamily extends Family<AsyncValue<List<Reward>>> {
  /// The rewards a family offers.
  ///
  /// Copied from [familyRewards].
  const FamilyRewardsFamily();

  /// The rewards a family offers.
  ///
  /// Copied from [familyRewards].
  FamilyRewardsProvider call(FamilyId familyId) {
    return FamilyRewardsProvider(familyId);
  }

  @override
  FamilyRewardsProvider getProviderOverride(
    covariant FamilyRewardsProvider provider,
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
  String? get name => r'familyRewardsProvider';
}

/// The rewards a family offers.
///
/// Copied from [familyRewards].
class FamilyRewardsProvider extends AutoDisposeStreamProvider<List<Reward>> {
  /// The rewards a family offers.
  ///
  /// Copied from [familyRewards].
  FamilyRewardsProvider(FamilyId familyId)
    : this._internal(
        (ref) => familyRewards(ref as FamilyRewardsRef, familyId),
        from: familyRewardsProvider,
        name: r'familyRewardsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$familyRewardsHash,
        dependencies: FamilyRewardsFamily._dependencies,
        allTransitiveDependencies:
            FamilyRewardsFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  FamilyRewardsProvider._internal(
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
  Override overrideWith(
    Stream<List<Reward>> Function(FamilyRewardsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FamilyRewardsProvider._internal(
        (ref) => create(ref as FamilyRewardsRef),
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
  AutoDisposeStreamProviderElement<List<Reward>> createElement() {
    return _FamilyRewardsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FamilyRewardsProvider && other.familyId == familyId;
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
mixin FamilyRewardsRef on AutoDisposeStreamProviderRef<List<Reward>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _FamilyRewardsProviderElement
    extends AutoDisposeStreamProviderElement<List<Reward>>
    with FamilyRewardsRef {
  _FamilyRewardsProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as FamilyRewardsProvider).familyId;
}

String _$familyRedemptionsHash() => r'7caece0a1b59b8ff56f159d36289beeceaa45b1c';

/// Every claim the family has made, newest first.
///
/// Copied from [familyRedemptions].
@ProviderFor(familyRedemptions)
const familyRedemptionsProvider = FamilyRedemptionsFamily();

/// Every claim the family has made, newest first.
///
/// Copied from [familyRedemptions].
class FamilyRedemptionsFamily extends Family<AsyncValue<List<Redemption>>> {
  /// Every claim the family has made, newest first.
  ///
  /// Copied from [familyRedemptions].
  const FamilyRedemptionsFamily();

  /// Every claim the family has made, newest first.
  ///
  /// Copied from [familyRedemptions].
  FamilyRedemptionsProvider call(FamilyId familyId) {
    return FamilyRedemptionsProvider(familyId);
  }

  @override
  FamilyRedemptionsProvider getProviderOverride(
    covariant FamilyRedemptionsProvider provider,
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
  String? get name => r'familyRedemptionsProvider';
}

/// Every claim the family has made, newest first.
///
/// Copied from [familyRedemptions].
class FamilyRedemptionsProvider
    extends AutoDisposeStreamProvider<List<Redemption>> {
  /// Every claim the family has made, newest first.
  ///
  /// Copied from [familyRedemptions].
  FamilyRedemptionsProvider(FamilyId familyId)
    : this._internal(
        (ref) => familyRedemptions(ref as FamilyRedemptionsRef, familyId),
        from: familyRedemptionsProvider,
        name: r'familyRedemptionsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$familyRedemptionsHash,
        dependencies: FamilyRedemptionsFamily._dependencies,
        allTransitiveDependencies:
            FamilyRedemptionsFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  FamilyRedemptionsProvider._internal(
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
  Override overrideWith(
    Stream<List<Redemption>> Function(FamilyRedemptionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FamilyRedemptionsProvider._internal(
        (ref) => create(ref as FamilyRedemptionsRef),
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
  AutoDisposeStreamProviderElement<List<Redemption>> createElement() {
    return _FamilyRedemptionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FamilyRedemptionsProvider && other.familyId == familyId;
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
mixin FamilyRedemptionsRef on AutoDisposeStreamProviderRef<List<Redemption>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _FamilyRedemptionsProviderElement
    extends AutoDisposeStreamProviderElement<List<Redemption>>
    with FamilyRedemptionsRef {
  _FamilyRedemptionsProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as FamilyRedemptionsProvider).familyId;
}

String _$outstandingClaimsHash() => r'2608340808bddd232cf8b03a51cc8701ea477664';

/// Outings the family still owes [userId].
///
/// Expired claims are settled on the way past: the refund is lazy by design —
/// no cron, no server — so it happens the next time anyone reads. The
/// consequence worth knowing: a child who stops opening the app does not get
/// their stars back until they do. Acceptable, but a real property rather than
/// an accident.
///
/// Copied from [outstandingClaims].
@ProviderFor(outstandingClaims)
const outstandingClaimsProvider = OutstandingClaimsFamily();

/// Outings the family still owes [userId].
///
/// Expired claims are settled on the way past: the refund is lazy by design —
/// no cron, no server — so it happens the next time anyone reads. The
/// consequence worth knowing: a child who stops opening the app does not get
/// their stars back until they do. Acceptable, but a real property rather than
/// an accident.
///
/// Copied from [outstandingClaims].
class OutstandingClaimsFamily extends Family<AsyncValue<List<Redemption>>> {
  /// Outings the family still owes [userId].
  ///
  /// Expired claims are settled on the way past: the refund is lazy by design —
  /// no cron, no server — so it happens the next time anyone reads. The
  /// consequence worth knowing: a child who stops opening the app does not get
  /// their stars back until they do. Acceptable, but a real property rather than
  /// an accident.
  ///
  /// Copied from [outstandingClaims].
  const OutstandingClaimsFamily();

  /// Outings the family still owes [userId].
  ///
  /// Expired claims are settled on the way past: the refund is lazy by design —
  /// no cron, no server — so it happens the next time anyone reads. The
  /// consequence worth knowing: a child who stops opening the app does not get
  /// their stars back until they do. Acceptable, but a real property rather than
  /// an accident.
  ///
  /// Copied from [outstandingClaims].
  OutstandingClaimsProvider call(FamilyId familyId, UserId userId) {
    return OutstandingClaimsProvider(familyId, userId);
  }

  @override
  OutstandingClaimsProvider getProviderOverride(
    covariant OutstandingClaimsProvider provider,
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
  String? get name => r'outstandingClaimsProvider';
}

/// Outings the family still owes [userId].
///
/// Expired claims are settled on the way past: the refund is lazy by design —
/// no cron, no server — so it happens the next time anyone reads. The
/// consequence worth knowing: a child who stops opening the app does not get
/// their stars back until they do. Acceptable, but a real property rather than
/// an accident.
///
/// Copied from [outstandingClaims].
class OutstandingClaimsProvider
    extends AutoDisposeFutureProvider<List<Redemption>> {
  /// Outings the family still owes [userId].
  ///
  /// Expired claims are settled on the way past: the refund is lazy by design —
  /// no cron, no server — so it happens the next time anyone reads. The
  /// consequence worth knowing: a child who stops opening the app does not get
  /// their stars back until they do. Acceptable, but a real property rather than
  /// an accident.
  ///
  /// Copied from [outstandingClaims].
  OutstandingClaimsProvider(FamilyId familyId, UserId userId)
    : this._internal(
        (ref) =>
            outstandingClaims(ref as OutstandingClaimsRef, familyId, userId),
        from: outstandingClaimsProvider,
        name: r'outstandingClaimsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$outstandingClaimsHash,
        dependencies: OutstandingClaimsFamily._dependencies,
        allTransitiveDependencies:
            OutstandingClaimsFamily._allTransitiveDependencies,
        familyId: familyId,
        userId: userId,
      );

  OutstandingClaimsProvider._internal(
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
  Override overrideWith(
    FutureOr<List<Redemption>> Function(OutstandingClaimsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OutstandingClaimsProvider._internal(
        (ref) => create(ref as OutstandingClaimsRef),
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
  AutoDisposeFutureProviderElement<List<Redemption>> createElement() {
    return _OutstandingClaimsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OutstandingClaimsProvider &&
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
mixin OutstandingClaimsRef on AutoDisposeFutureProviderRef<List<Redemption>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;

  /// The parameter `userId` of this provider.
  UserId get userId;
}

class _OutstandingClaimsProviderElement
    extends AutoDisposeFutureProviderElement<List<Redemption>>
    with OutstandingClaimsRef {
  _OutstandingClaimsProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as OutstandingClaimsProvider).familyId;
  @override
  UserId get userId => (origin as OutstandingClaimsProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
