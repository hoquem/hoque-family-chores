// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_leaderboard_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$weeklyLeaderboardNotifierHash() =>
    r'10e33292406b40c9ec27b161f49b184535fe0356';

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

abstract class _$WeeklyLeaderboardNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<LeaderboardEntry>> {
  late final FamilyId familyId;

  FutureOr<List<LeaderboardEntry>> build(FamilyId familyId);
}

/// Manages weekly leaderboard data for a family.
///
/// This notifier fetches and manages weekly leaderboard entries showing
/// family member rankings based on stars earned this week (Monday-Sunday).
///
/// Features:
/// - Weekly star tracking
/// - Podium for top 3
/// - Rank change indicators
/// - Champion badge tracking
/// - Week countdown timer
///
/// Copied from [WeeklyLeaderboardNotifier].
@ProviderFor(WeeklyLeaderboardNotifier)
const weeklyLeaderboardNotifierProvider = WeeklyLeaderboardNotifierFamily();

/// Manages weekly leaderboard data for a family.
///
/// This notifier fetches and manages weekly leaderboard entries showing
/// family member rankings based on stars earned this week (Monday-Sunday).
///
/// Features:
/// - Weekly star tracking
/// - Podium for top 3
/// - Rank change indicators
/// - Champion badge tracking
/// - Week countdown timer
///
/// Copied from [WeeklyLeaderboardNotifier].
class WeeklyLeaderboardNotifierFamily
    extends Family<AsyncValue<List<LeaderboardEntry>>> {
  /// Manages weekly leaderboard data for a family.
  ///
  /// This notifier fetches and manages weekly leaderboard entries showing
  /// family member rankings based on stars earned this week (Monday-Sunday).
  ///
  /// Features:
  /// - Weekly star tracking
  /// - Podium for top 3
  /// - Rank change indicators
  /// - Champion badge tracking
  /// - Week countdown timer
  ///
  /// Copied from [WeeklyLeaderboardNotifier].
  const WeeklyLeaderboardNotifierFamily();

  /// Manages weekly leaderboard data for a family.
  ///
  /// This notifier fetches and manages weekly leaderboard entries showing
  /// family member rankings based on stars earned this week (Monday-Sunday).
  ///
  /// Features:
  /// - Weekly star tracking
  /// - Podium for top 3
  /// - Rank change indicators
  /// - Champion badge tracking
  /// - Week countdown timer
  ///
  /// Copied from [WeeklyLeaderboardNotifier].
  WeeklyLeaderboardNotifierProvider call(FamilyId familyId) {
    return WeeklyLeaderboardNotifierProvider(familyId);
  }

  @override
  WeeklyLeaderboardNotifierProvider getProviderOverride(
    covariant WeeklyLeaderboardNotifierProvider provider,
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
  String? get name => r'weeklyLeaderboardNotifierProvider';
}

/// Manages weekly leaderboard data for a family.
///
/// This notifier fetches and manages weekly leaderboard entries showing
/// family member rankings based on stars earned this week (Monday-Sunday).
///
/// Features:
/// - Weekly star tracking
/// - Podium for top 3
/// - Rank change indicators
/// - Champion badge tracking
/// - Week countdown timer
///
/// Copied from [WeeklyLeaderboardNotifier].
class WeeklyLeaderboardNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          WeeklyLeaderboardNotifier,
          List<LeaderboardEntry>
        > {
  /// Manages weekly leaderboard data for a family.
  ///
  /// This notifier fetches and manages weekly leaderboard entries showing
  /// family member rankings based on stars earned this week (Monday-Sunday).
  ///
  /// Features:
  /// - Weekly star tracking
  /// - Podium for top 3
  /// - Rank change indicators
  /// - Champion badge tracking
  /// - Week countdown timer
  ///
  /// Copied from [WeeklyLeaderboardNotifier].
  WeeklyLeaderboardNotifierProvider(FamilyId familyId)
    : this._internal(
        () => WeeklyLeaderboardNotifier()..familyId = familyId,
        from: weeklyLeaderboardNotifierProvider,
        name: r'weeklyLeaderboardNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$weeklyLeaderboardNotifierHash,
        dependencies: WeeklyLeaderboardNotifierFamily._dependencies,
        allTransitiveDependencies:
            WeeklyLeaderboardNotifierFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  WeeklyLeaderboardNotifierProvider._internal(
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
    covariant WeeklyLeaderboardNotifier notifier,
  ) {
    return notifier.build(familyId);
  }

  @override
  Override overrideWith(WeeklyLeaderboardNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: WeeklyLeaderboardNotifierProvider._internal(
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
    WeeklyLeaderboardNotifier,
    List<LeaderboardEntry>
  >
  createElement() {
    return _WeeklyLeaderboardNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyLeaderboardNotifierProvider &&
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
mixin WeeklyLeaderboardNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<LeaderboardEntry>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _WeeklyLeaderboardNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          WeeklyLeaderboardNotifier,
          List<LeaderboardEntry>
        >
    with WeeklyLeaderboardNotifierRef {
  _WeeklyLeaderboardNotifierProviderElement(super.provider);

  @override
  FamilyId get familyId =>
      (origin as WeeklyLeaderboardNotifierProvider).familyId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
