// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$badgeNotifierHash() => r'9fa1e72d86ad1f64b904d6bcda0e7000c099d640';

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

abstract class _$BadgeNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Badge>> {
  late final FamilyId familyId;

  FutureOr<List<Badge>> build(FamilyId familyId);
}

/// Manages badge-related state and operations.
///
/// This notifier handles loading badges for a family and provides
/// methods for badge-related operations.
///
/// Example:
/// ```dart
/// final badgesAsync = ref.watch(badgeNotifierProvider(familyId));
/// final notifier = ref.read(badgeNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
///
/// Copied from [BadgeNotifier].
@ProviderFor(BadgeNotifier)
const badgeNotifierProvider = BadgeNotifierFamily();

/// Manages badge-related state and operations.
///
/// This notifier handles loading badges for a family and provides
/// methods for badge-related operations.
///
/// Example:
/// ```dart
/// final badgesAsync = ref.watch(badgeNotifierProvider(familyId));
/// final notifier = ref.read(badgeNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
///
/// Copied from [BadgeNotifier].
class BadgeNotifierFamily extends Family<AsyncValue<List<Badge>>> {
  /// Manages badge-related state and operations.
  ///
  /// This notifier handles loading badges for a family and provides
  /// methods for badge-related operations.
  ///
  /// Example:
  /// ```dart
  /// final badgesAsync = ref.watch(badgeNotifierProvider(familyId));
  /// final notifier = ref.read(badgeNotifierProvider(familyId).notifier);
  /// await notifier.refresh();
  /// ```
  ///
  /// Copied from [BadgeNotifier].
  const BadgeNotifierFamily();

  /// Manages badge-related state and operations.
  ///
  /// This notifier handles loading badges for a family and provides
  /// methods for badge-related operations.
  ///
  /// Example:
  /// ```dart
  /// final badgesAsync = ref.watch(badgeNotifierProvider(familyId));
  /// final notifier = ref.read(badgeNotifierProvider(familyId).notifier);
  /// await notifier.refresh();
  /// ```
  ///
  /// Copied from [BadgeNotifier].
  BadgeNotifierProvider call(FamilyId familyId) {
    return BadgeNotifierProvider(familyId);
  }

  @override
  BadgeNotifierProvider getProviderOverride(
    covariant BadgeNotifierProvider provider,
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
  String? get name => r'badgeNotifierProvider';
}

/// Manages badge-related state and operations.
///
/// This notifier handles loading badges for a family and provides
/// methods for badge-related operations.
///
/// Example:
/// ```dart
/// final badgesAsync = ref.watch(badgeNotifierProvider(familyId));
/// final notifier = ref.read(badgeNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
///
/// Copied from [BadgeNotifier].
class BadgeNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<BadgeNotifier, List<Badge>> {
  /// Manages badge-related state and operations.
  ///
  /// This notifier handles loading badges for a family and provides
  /// methods for badge-related operations.
  ///
  /// Example:
  /// ```dart
  /// final badgesAsync = ref.watch(badgeNotifierProvider(familyId));
  /// final notifier = ref.read(badgeNotifierProvider(familyId).notifier);
  /// await notifier.refresh();
  /// ```
  ///
  /// Copied from [BadgeNotifier].
  BadgeNotifierProvider(FamilyId familyId)
    : this._internal(
        () => BadgeNotifier()..familyId = familyId,
        from: badgeNotifierProvider,
        name: r'badgeNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$badgeNotifierHash,
        dependencies: BadgeNotifierFamily._dependencies,
        allTransitiveDependencies:
            BadgeNotifierFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  BadgeNotifierProvider._internal(
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
  FutureOr<List<Badge>> runNotifierBuild(covariant BadgeNotifier notifier) {
    return notifier.build(familyId);
  }

  @override
  Override overrideWith(BadgeNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: BadgeNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<BadgeNotifier, List<Badge>>
  createElement() {
    return _BadgeNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BadgeNotifierProvider && other.familyId == familyId;
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
mixin BadgeNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<Badge>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _BadgeNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<BadgeNotifier, List<Badge>>
    with BadgeNotifierRef {
  _BadgeNotifierProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as BadgeNotifierProvider).familyId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
