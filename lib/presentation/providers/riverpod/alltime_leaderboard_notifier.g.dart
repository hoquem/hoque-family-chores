// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alltime_leaderboard_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allTimeLeaderboardNotifierHash() =>
    r'597d66f5f57a3a210652e29127f1e4ac484ca938';

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

abstract class _$AllTimeLeaderboardNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<LeaderboardEntry>> {
  late final FamilyId familyId;

  FutureOr<List<LeaderboardEntry>> build(FamilyId familyId);
}

/// Manages all-time leaderboard data for a family.
///
/// This notifier fetches and manages all-time leaderboard entries showing
/// family member lifetime statistics: total stars, quests completed, longest streak.
///
/// Copied from [AllTimeLeaderboardNotifier].
@ProviderFor(AllTimeLeaderboardNotifier)
const allTimeLeaderboardNotifierProvider = AllTimeLeaderboardNotifierFamily();

/// Manages all-time leaderboard data for a family.
///
/// This notifier fetches and manages all-time leaderboard entries showing
/// family member lifetime statistics: total stars, quests completed, longest streak.
///
/// Copied from [AllTimeLeaderboardNotifier].
class AllTimeLeaderboardNotifierFamily
    extends Family<AsyncValue<List<LeaderboardEntry>>> {
  /// Manages all-time leaderboard data for a family.
  ///
  /// This notifier fetches and manages all-time leaderboard entries showing
  /// family member lifetime statistics: total stars, quests completed, longest streak.
  ///
  /// Copied from [AllTimeLeaderboardNotifier].
  const AllTimeLeaderboardNotifierFamily();

  /// Manages all-time leaderboard data for a family.
  ///
  /// This notifier fetches and manages all-time leaderboard entries showing
  /// family member lifetime statistics: total stars, quests completed, longest streak.
  ///
  /// Copied from [AllTimeLeaderboardNotifier].
  AllTimeLeaderboardNotifierProvider call(FamilyId familyId) {
    return AllTimeLeaderboardNotifierProvider(familyId);
  }

  @override
  AllTimeLeaderboardNotifierProvider getProviderOverride(
    covariant AllTimeLeaderboardNotifierProvider provider,
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
  String? get name => r'allTimeLeaderboardNotifierProvider';
}

/// Manages all-time leaderboard data for a family.
///
/// This notifier fetches and manages all-time leaderboard entries showing
/// family member lifetime statistics: total stars, quests completed, longest streak.
///
/// Copied from [AllTimeLeaderboardNotifier].
class AllTimeLeaderboardNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          AllTimeLeaderboardNotifier,
          List<LeaderboardEntry>
        > {
  /// Manages all-time leaderboard data for a family.
  ///
  /// This notifier fetches and manages all-time leaderboard entries showing
  /// family member lifetime statistics: total stars, quests completed, longest streak.
  ///
  /// Copied from [AllTimeLeaderboardNotifier].
  AllTimeLeaderboardNotifierProvider(FamilyId familyId)
    : this._internal(
        () => AllTimeLeaderboardNotifier()..familyId = familyId,
        from: allTimeLeaderboardNotifierProvider,
        name: r'allTimeLeaderboardNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$allTimeLeaderboardNotifierHash,
        dependencies: AllTimeLeaderboardNotifierFamily._dependencies,
        allTransitiveDependencies:
            AllTimeLeaderboardNotifierFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  AllTimeLeaderboardNotifierProvider._internal(
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
  FutureOr<List<LeaderboardEntry>> runNotifierBuild(
    covariant AllTimeLeaderboardNotifier notifier,
  ) {
    return notifier.build(familyId);
  }

  @override
  Override overrideWith(AllTimeLeaderboardNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: AllTimeLeaderboardNotifierProvider._internal(
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
    AllTimeLeaderboardNotifier,
    List<LeaderboardEntry>
  >
  createElement() {
    return _AllTimeLeaderboardNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AllTimeLeaderboardNotifierProvider &&
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
mixin AllTimeLeaderboardNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<LeaderboardEntry>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _AllTimeLeaderboardNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          AllTimeLeaderboardNotifier,
          List<LeaderboardEntry>
        >
    with AllTimeLeaderboardNotifierRef {
  _AllTimeLeaderboardNotifierProviderElement(super.provider);

  @override
  FamilyId get familyId =>
      (origin as AllTimeLeaderboardNotifierProvider).familyId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
