// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$leaderboardNotifierHash() =>
    r'4355fe9cf21a481615636e0524d27ab438419cd8';

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

abstract class _$LeaderboardNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<LeaderboardEntry>> {
  late final FamilyId familyId;

  FutureOr<List<LeaderboardEntry>> build(FamilyId familyId);
}

/// Manages leaderboard data for a family.
///
/// This notifier fetches and manages leaderboard entries showing
/// family member rankings based on points and completed tasks.
///
/// Example:
/// ```dart
/// final leaderboardAsync = ref.watch(leaderboardNotifierProvider(familyId));
/// final notifier = ref.read(leaderboardNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
///
/// Copied from [LeaderboardNotifier].
@ProviderFor(LeaderboardNotifier)
const leaderboardNotifierProvider = LeaderboardNotifierFamily();

/// Manages leaderboard data for a family.
///
/// This notifier fetches and manages leaderboard entries showing
/// family member rankings based on points and completed tasks.
///
/// Example:
/// ```dart
/// final leaderboardAsync = ref.watch(leaderboardNotifierProvider(familyId));
/// final notifier = ref.read(leaderboardNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
///
/// Copied from [LeaderboardNotifier].
class LeaderboardNotifierFamily
    extends Family<AsyncValue<List<LeaderboardEntry>>> {
  /// Manages leaderboard data for a family.
  ///
  /// This notifier fetches and manages leaderboard entries showing
  /// family member rankings based on points and completed tasks.
  ///
  /// Example:
  /// ```dart
  /// final leaderboardAsync = ref.watch(leaderboardNotifierProvider(familyId));
  /// final notifier = ref.read(leaderboardNotifierProvider(familyId).notifier);
  /// await notifier.refresh();
  /// ```
  ///
  /// Copied from [LeaderboardNotifier].
  const LeaderboardNotifierFamily();

  /// Manages leaderboard data for a family.
  ///
  /// This notifier fetches and manages leaderboard entries showing
  /// family member rankings based on points and completed tasks.
  ///
  /// Example:
  /// ```dart
  /// final leaderboardAsync = ref.watch(leaderboardNotifierProvider(familyId));
  /// final notifier = ref.read(leaderboardNotifierProvider(familyId).notifier);
  /// await notifier.refresh();
  /// ```
  ///
  /// Copied from [LeaderboardNotifier].
  LeaderboardNotifierProvider call(FamilyId familyId) {
    return LeaderboardNotifierProvider(familyId);
  }

  @override
  LeaderboardNotifierProvider getProviderOverride(
    covariant LeaderboardNotifierProvider provider,
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
  String? get name => r'leaderboardNotifierProvider';
}

/// Manages leaderboard data for a family.
///
/// This notifier fetches and manages leaderboard entries showing
/// family member rankings based on points and completed tasks.
///
/// Example:
/// ```dart
/// final leaderboardAsync = ref.watch(leaderboardNotifierProvider(familyId));
/// final notifier = ref.read(leaderboardNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
///
/// Copied from [LeaderboardNotifier].
class LeaderboardNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          LeaderboardNotifier,
          List<LeaderboardEntry>
        > {
  /// Manages leaderboard data for a family.
  ///
  /// This notifier fetches and manages leaderboard entries showing
  /// family member rankings based on points and completed tasks.
  ///
  /// Example:
  /// ```dart
  /// final leaderboardAsync = ref.watch(leaderboardNotifierProvider(familyId));
  /// final notifier = ref.read(leaderboardNotifierProvider(familyId).notifier);
  /// await notifier.refresh();
  /// ```
  ///
  /// Copied from [LeaderboardNotifier].
  LeaderboardNotifierProvider(FamilyId familyId)
    : this._internal(
        () => LeaderboardNotifier()..familyId = familyId,
        from: leaderboardNotifierProvider,
        name: r'leaderboardNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$leaderboardNotifierHash,
        dependencies: LeaderboardNotifierFamily._dependencies,
        allTransitiveDependencies:
            LeaderboardNotifierFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  LeaderboardNotifierProvider._internal(
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
    covariant LeaderboardNotifier notifier,
  ) {
    return notifier.build(familyId);
  }

  @override
  Override overrideWith(LeaderboardNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: LeaderboardNotifierProvider._internal(
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
    LeaderboardNotifier,
    List<LeaderboardEntry>
  >
  createElement() {
    return _LeaderboardNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LeaderboardNotifierProvider && other.familyId == familyId;
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
mixin LeaderboardNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<LeaderboardEntry>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _LeaderboardNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          LeaderboardNotifier,
          List<LeaderboardEntry>
        >
    with LeaderboardNotifierRef {
  _LeaderboardNotifierProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as LeaderboardNotifierProvider).familyId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
