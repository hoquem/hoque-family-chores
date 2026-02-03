// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$familyNotifierHash() => r'5612bae4b5b8cb8e1db7b628d6a8b3e9a56d1b64';

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

abstract class _$FamilyNotifier
    extends BuildlessAutoDisposeAsyncNotifier<FamilyEntity> {
  late final FamilyId familyId;

  FutureOr<FamilyEntity> build(FamilyId familyId);
}

/// Manages family data and family members.
///
/// This notifier handles family operations including getting family details,
/// managing family members, and updating family information.
///
/// Example:
/// ```dart
/// final familyAsync = ref.watch(familyNotifierProvider(familyId));
/// final notifier = ref.read(familyNotifierProvider(familyId).notifier);
/// await notifier.addMember(userId, familyId, role);
/// ```
///
/// Copied from [FamilyNotifier].
@ProviderFor(FamilyNotifier)
const familyNotifierProvider = FamilyNotifierFamily();

/// Manages family data and family members.
///
/// This notifier handles family operations including getting family details,
/// managing family members, and updating family information.
///
/// Example:
/// ```dart
/// final familyAsync = ref.watch(familyNotifierProvider(familyId));
/// final notifier = ref.read(familyNotifierProvider(familyId).notifier);
/// await notifier.addMember(userId, familyId, role);
/// ```
///
/// Copied from [FamilyNotifier].
class FamilyNotifierFamily extends Family<AsyncValue<FamilyEntity>> {
  /// Manages family data and family members.
  ///
  /// This notifier handles family operations including getting family details,
  /// managing family members, and updating family information.
  ///
  /// Example:
  /// ```dart
  /// final familyAsync = ref.watch(familyNotifierProvider(familyId));
  /// final notifier = ref.read(familyNotifierProvider(familyId).notifier);
  /// await notifier.addMember(userId, familyId, role);
  /// ```
  ///
  /// Copied from [FamilyNotifier].
  const FamilyNotifierFamily();

  /// Manages family data and family members.
  ///
  /// This notifier handles family operations including getting family details,
  /// managing family members, and updating family information.
  ///
  /// Example:
  /// ```dart
  /// final familyAsync = ref.watch(familyNotifierProvider(familyId));
  /// final notifier = ref.read(familyNotifierProvider(familyId).notifier);
  /// await notifier.addMember(userId, familyId, role);
  /// ```
  ///
  /// Copied from [FamilyNotifier].
  FamilyNotifierProvider call(FamilyId familyId) {
    return FamilyNotifierProvider(familyId);
  }

  @override
  FamilyNotifierProvider getProviderOverride(
    covariant FamilyNotifierProvider provider,
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
  String? get name => r'familyNotifierProvider';
}

/// Manages family data and family members.
///
/// This notifier handles family operations including getting family details,
/// managing family members, and updating family information.
///
/// Example:
/// ```dart
/// final familyAsync = ref.watch(familyNotifierProvider(familyId));
/// final notifier = ref.read(familyNotifierProvider(familyId).notifier);
/// await notifier.addMember(userId, familyId, role);
/// ```
///
/// Copied from [FamilyNotifier].
class FamilyNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<FamilyNotifier, FamilyEntity> {
  /// Manages family data and family members.
  ///
  /// This notifier handles family operations including getting family details,
  /// managing family members, and updating family information.
  ///
  /// Example:
  /// ```dart
  /// final familyAsync = ref.watch(familyNotifierProvider(familyId));
  /// final notifier = ref.read(familyNotifierProvider(familyId).notifier);
  /// await notifier.addMember(userId, familyId, role);
  /// ```
  ///
  /// Copied from [FamilyNotifier].
  FamilyNotifierProvider(FamilyId familyId)
    : this._internal(
        () => FamilyNotifier()..familyId = familyId,
        from: familyNotifierProvider,
        name: r'familyNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$familyNotifierHash,
        dependencies: FamilyNotifierFamily._dependencies,
        allTransitiveDependencies:
            FamilyNotifierFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  FamilyNotifierProvider._internal(
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
  FutureOr<FamilyEntity> runNotifierBuild(covariant FamilyNotifier notifier) {
    return notifier.build(familyId);
  }

  @override
  Override overrideWith(FamilyNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: FamilyNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<FamilyNotifier, FamilyEntity>
  createElement() {
    return _FamilyNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FamilyNotifierProvider && other.familyId == familyId;
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
mixin FamilyNotifierRef on AutoDisposeAsyncNotifierProviderRef<FamilyEntity> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _FamilyNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<FamilyNotifier, FamilyEntity>
    with FamilyNotifierRef {
  _FamilyNotifierProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as FamilyNotifierProvider).familyId;
}

String _$familyMembersNotifierHash() =>
    r'5d18888807bf6523df0433c3ee8e94364e1e0a54';

abstract class _$FamilyMembersNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<User>> {
  late final FamilyId familyId;

  FutureOr<List<User>> build(FamilyId familyId);
}

/// Manages family members list.
///
/// Copied from [FamilyMembersNotifier].
@ProviderFor(FamilyMembersNotifier)
const familyMembersNotifierProvider = FamilyMembersNotifierFamily();

/// Manages family members list.
///
/// Copied from [FamilyMembersNotifier].
class FamilyMembersNotifierFamily extends Family<AsyncValue<List<User>>> {
  /// Manages family members list.
  ///
  /// Copied from [FamilyMembersNotifier].
  const FamilyMembersNotifierFamily();

  /// Manages family members list.
  ///
  /// Copied from [FamilyMembersNotifier].
  FamilyMembersNotifierProvider call(FamilyId familyId) {
    return FamilyMembersNotifierProvider(familyId);
  }

  @override
  FamilyMembersNotifierProvider getProviderOverride(
    covariant FamilyMembersNotifierProvider provider,
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
  String? get name => r'familyMembersNotifierProvider';
}

/// Manages family members list.
///
/// Copied from [FamilyMembersNotifier].
class FamilyMembersNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          FamilyMembersNotifier,
          List<User>
        > {
  /// Manages family members list.
  ///
  /// Copied from [FamilyMembersNotifier].
  FamilyMembersNotifierProvider(FamilyId familyId)
    : this._internal(
        () => FamilyMembersNotifier()..familyId = familyId,
        from: familyMembersNotifierProvider,
        name: r'familyMembersNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$familyMembersNotifierHash,
        dependencies: FamilyMembersNotifierFamily._dependencies,
        allTransitiveDependencies:
            FamilyMembersNotifierFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  FamilyMembersNotifierProvider._internal(
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
  FutureOr<List<User>> runNotifierBuild(
    covariant FamilyMembersNotifier notifier,
  ) {
    return notifier.build(familyId);
  }

  @override
  Override overrideWith(FamilyMembersNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: FamilyMembersNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<FamilyMembersNotifier, List<User>>
  createElement() {
    return _FamilyMembersNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FamilyMembersNotifierProvider && other.familyId == familyId;
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
mixin FamilyMembersNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<User>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _FamilyMembersNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          FamilyMembersNotifier,
          List<User>
        >
    with FamilyMembersNotifierRef {
  _FamilyMembersNotifierProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as FamilyMembersNotifierProvider).familyId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
