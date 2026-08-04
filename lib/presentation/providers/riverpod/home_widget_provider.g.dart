// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homeWidgetDataHash() => r'bb76a45e6b55dcea8fb6578fefdf6cd6fcbb090e';

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

/// Builds the data payload for the home-screen widget from the same state that
/// powers the home hub. Keeps the widget in sync without extra data fetching.
///
/// Copied from [homeWidgetData].
@ProviderFor(homeWidgetData)
const homeWidgetDataProvider = HomeWidgetDataFamily();

/// Builds the data payload for the home-screen widget from the same state that
/// powers the home hub. Keeps the widget in sync without extra data fetching.
///
/// Copied from [homeWidgetData].
class HomeWidgetDataFamily extends Family<HomeWidgetData> {
  /// Builds the data payload for the home-screen widget from the same state that
  /// powers the home hub. Keeps the widget in sync without extra data fetching.
  ///
  /// Copied from [homeWidgetData].
  const HomeWidgetDataFamily();

  /// Builds the data payload for the home-screen widget from the same state that
  /// powers the home hub. Keeps the widget in sync without extra data fetching.
  ///
  /// Copied from [homeWidgetData].
  HomeWidgetDataProvider call(FamilyId familyId, UserId userId) {
    return HomeWidgetDataProvider(familyId, userId);
  }

  @override
  HomeWidgetDataProvider getProviderOverride(
    covariant HomeWidgetDataProvider provider,
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
  String? get name => r'homeWidgetDataProvider';
}

/// Builds the data payload for the home-screen widget from the same state that
/// powers the home hub. Keeps the widget in sync without extra data fetching.
///
/// Copied from [homeWidgetData].
class HomeWidgetDataProvider extends AutoDisposeProvider<HomeWidgetData> {
  /// Builds the data payload for the home-screen widget from the same state that
  /// powers the home hub. Keeps the widget in sync without extra data fetching.
  ///
  /// Copied from [homeWidgetData].
  HomeWidgetDataProvider(FamilyId familyId, UserId userId)
    : this._internal(
        (ref) => homeWidgetData(ref as HomeWidgetDataRef, familyId, userId),
        from: homeWidgetDataProvider,
        name: r'homeWidgetDataProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$homeWidgetDataHash,
        dependencies: HomeWidgetDataFamily._dependencies,
        allTransitiveDependencies:
            HomeWidgetDataFamily._allTransitiveDependencies,
        familyId: familyId,
        userId: userId,
      );

  HomeWidgetDataProvider._internal(
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
    HomeWidgetData Function(HomeWidgetDataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HomeWidgetDataProvider._internal(
        (ref) => create(ref as HomeWidgetDataRef),
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
  AutoDisposeProviderElement<HomeWidgetData> createElement() {
    return _HomeWidgetDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HomeWidgetDataProvider &&
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
mixin HomeWidgetDataRef on AutoDisposeProviderRef<HomeWidgetData> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;

  /// The parameter `userId` of this provider.
  UserId get userId;
}

class _HomeWidgetDataProviderElement
    extends AutoDisposeProviderElement<HomeWidgetData>
    with HomeWidgetDataRef {
  _HomeWidgetDataProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as HomeWidgetDataProvider).familyId;
  @override
  UserId get userId => (origin as HomeWidgetDataProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
