// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$streakNotifierHash() => r'59731600b81f8e6bafc1da1b64011ba72d7e1c27';

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

abstract class _$StreakNotifier
    extends BuildlessAutoDisposeStreamNotifier<Streak?> {
  late final UserId userId;

  Stream<Streak?> build(UserId userId);
}

/// Manages streak-related state and operations.
///
/// This notifier handles loading and updating user streaks,
/// including milestone achievements and freeze management.
///
/// Example:
/// ```dart
/// final streakAsync = ref.watch(streakNotifierProvider(userId));
/// final notifier = ref.read(streakNotifierProvider(userId).notifier);
/// await notifier.updateStreakAfterQuestCompletion(DateTime.now());
/// ```
///
/// Copied from [StreakNotifier].
@ProviderFor(StreakNotifier)
const streakNotifierProvider = StreakNotifierFamily();

/// Manages streak-related state and operations.
///
/// This notifier handles loading and updating user streaks,
/// including milestone achievements and freeze management.
///
/// Example:
/// ```dart
/// final streakAsync = ref.watch(streakNotifierProvider(userId));
/// final notifier = ref.read(streakNotifierProvider(userId).notifier);
/// await notifier.updateStreakAfterQuestCompletion(DateTime.now());
/// ```
///
/// Copied from [StreakNotifier].
class StreakNotifierFamily extends Family<AsyncValue<Streak?>> {
  /// Manages streak-related state and operations.
  ///
  /// This notifier handles loading and updating user streaks,
  /// including milestone achievements and freeze management.
  ///
  /// Example:
  /// ```dart
  /// final streakAsync = ref.watch(streakNotifierProvider(userId));
  /// final notifier = ref.read(streakNotifierProvider(userId).notifier);
  /// await notifier.updateStreakAfterQuestCompletion(DateTime.now());
  /// ```
  ///
  /// Copied from [StreakNotifier].
  const StreakNotifierFamily();

  /// Manages streak-related state and operations.
  ///
  /// This notifier handles loading and updating user streaks,
  /// including milestone achievements and freeze management.
  ///
  /// Example:
  /// ```dart
  /// final streakAsync = ref.watch(streakNotifierProvider(userId));
  /// final notifier = ref.read(streakNotifierProvider(userId).notifier);
  /// await notifier.updateStreakAfterQuestCompletion(DateTime.now());
  /// ```
  ///
  /// Copied from [StreakNotifier].
  StreakNotifierProvider call(UserId userId) {
    return StreakNotifierProvider(userId);
  }

  @override
  StreakNotifierProvider getProviderOverride(
    covariant StreakNotifierProvider provider,
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
  String? get name => r'streakNotifierProvider';
}

/// Manages streak-related state and operations.
///
/// This notifier handles loading and updating user streaks,
/// including milestone achievements and freeze management.
///
/// Example:
/// ```dart
/// final streakAsync = ref.watch(streakNotifierProvider(userId));
/// final notifier = ref.read(streakNotifierProvider(userId).notifier);
/// await notifier.updateStreakAfterQuestCompletion(DateTime.now());
/// ```
///
/// Copied from [StreakNotifier].
class StreakNotifierProvider
    extends AutoDisposeStreamNotifierProviderImpl<StreakNotifier, Streak?> {
  /// Manages streak-related state and operations.
  ///
  /// This notifier handles loading and updating user streaks,
  /// including milestone achievements and freeze management.
  ///
  /// Example:
  /// ```dart
  /// final streakAsync = ref.watch(streakNotifierProvider(userId));
  /// final notifier = ref.read(streakNotifierProvider(userId).notifier);
  /// await notifier.updateStreakAfterQuestCompletion(DateTime.now());
  /// ```
  ///
  /// Copied from [StreakNotifier].
  StreakNotifierProvider(UserId userId)
    : this._internal(
        () => StreakNotifier()..userId = userId,
        from: streakNotifierProvider,
        name: r'streakNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$streakNotifierHash,
        dependencies: StreakNotifierFamily._dependencies,
        allTransitiveDependencies:
            StreakNotifierFamily._allTransitiveDependencies,
        userId: userId,
      );

  StreakNotifierProvider._internal(
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
  Stream<Streak?> runNotifierBuild(covariant StreakNotifier notifier) {
    return notifier.build(userId);
  }

  @override
  Override overrideWith(StreakNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: StreakNotifierProvider._internal(
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
  AutoDisposeStreamNotifierProviderElement<StreakNotifier, Streak?>
  createElement() {
    return _StreakNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StreakNotifierProvider && other.userId == userId;
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
mixin StreakNotifierRef on AutoDisposeStreamNotifierProviderRef<Streak?> {
  /// The parameter `userId` of this provider.
  UserId get userId;
}

class _StreakNotifierProviderElement
    extends AutoDisposeStreamNotifierProviderElement<StreakNotifier, Streak?>
    with StreakNotifierRef {
  _StreakNotifierProviderElement(super.provider);

  @override
  UserId get userId => (origin as StreakNotifierProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
