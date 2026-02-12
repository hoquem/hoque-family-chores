// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'available_tasks_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$availableTasksNotifierHash() =>
    r'29e574ae7abd26ff9e42dc9862cd3201f120d880';

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

abstract class _$AvailableTasksNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Task>> {
  late final FamilyId familyId;

  FutureOr<List<Task>> build(FamilyId familyId);
}

/// Manages the list of available tasks that can be claimed by users.
///
/// This notifier streams available tasks within a family and provides
/// methods for claiming tasks.
///
/// Example:
/// ```dart
/// final availableTasksAsync = ref.watch(availableTasksNotifierProvider(familyId));
/// final notifier = ref.read(availableTasksNotifierProvider(familyId).notifier);
/// await notifier.claimTask(taskId, userId);
/// ```
///
/// Copied from [AvailableTasksNotifier].
@ProviderFor(AvailableTasksNotifier)
const availableTasksNotifierProvider = AvailableTasksNotifierFamily();

/// Manages the list of available tasks that can be claimed by users.
///
/// This notifier streams available tasks within a family and provides
/// methods for claiming tasks.
///
/// Example:
/// ```dart
/// final availableTasksAsync = ref.watch(availableTasksNotifierProvider(familyId));
/// final notifier = ref.read(availableTasksNotifierProvider(familyId).notifier);
/// await notifier.claimTask(taskId, userId);
/// ```
///
/// Copied from [AvailableTasksNotifier].
class AvailableTasksNotifierFamily extends Family<AsyncValue<List<Task>>> {
  /// Manages the list of available tasks that can be claimed by users.
  ///
  /// This notifier streams available tasks within a family and provides
  /// methods for claiming tasks.
  ///
  /// Example:
  /// ```dart
  /// final availableTasksAsync = ref.watch(availableTasksNotifierProvider(familyId));
  /// final notifier = ref.read(availableTasksNotifierProvider(familyId).notifier);
  /// await notifier.claimTask(taskId, userId);
  /// ```
  ///
  /// Copied from [AvailableTasksNotifier].
  const AvailableTasksNotifierFamily();

  /// Manages the list of available tasks that can be claimed by users.
  ///
  /// This notifier streams available tasks within a family and provides
  /// methods for claiming tasks.
  ///
  /// Example:
  /// ```dart
  /// final availableTasksAsync = ref.watch(availableTasksNotifierProvider(familyId));
  /// final notifier = ref.read(availableTasksNotifierProvider(familyId).notifier);
  /// await notifier.claimTask(taskId, userId);
  /// ```
  ///
  /// Copied from [AvailableTasksNotifier].
  AvailableTasksNotifierProvider call(FamilyId familyId) {
    return AvailableTasksNotifierProvider(familyId);
  }

  @override
  AvailableTasksNotifierProvider getProviderOverride(
    covariant AvailableTasksNotifierProvider provider,
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
  String? get name => r'availableTasksNotifierProvider';
}

/// Manages the list of available tasks that can be claimed by users.
///
/// This notifier streams available tasks within a family and provides
/// methods for claiming tasks.
///
/// Example:
/// ```dart
/// final availableTasksAsync = ref.watch(availableTasksNotifierProvider(familyId));
/// final notifier = ref.read(availableTasksNotifierProvider(familyId).notifier);
/// await notifier.claimTask(taskId, userId);
/// ```
///
/// Copied from [AvailableTasksNotifier].
class AvailableTasksNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          AvailableTasksNotifier,
          List<Task>
        > {
  /// Manages the list of available tasks that can be claimed by users.
  ///
  /// This notifier streams available tasks within a family and provides
  /// methods for claiming tasks.
  ///
  /// Example:
  /// ```dart
  /// final availableTasksAsync = ref.watch(availableTasksNotifierProvider(familyId));
  /// final notifier = ref.read(availableTasksNotifierProvider(familyId).notifier);
  /// await notifier.claimTask(taskId, userId);
  /// ```
  ///
  /// Copied from [AvailableTasksNotifier].
  AvailableTasksNotifierProvider(FamilyId familyId)
    : this._internal(
        () => AvailableTasksNotifier()..familyId = familyId,
        from: availableTasksNotifierProvider,
        name: r'availableTasksNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$availableTasksNotifierHash,
        dependencies: AvailableTasksNotifierFamily._dependencies,
        allTransitiveDependencies:
            AvailableTasksNotifierFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  AvailableTasksNotifierProvider._internal(
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
  FutureOr<List<Task>> runNotifierBuild(
    covariant AvailableTasksNotifier notifier,
  ) {
    return notifier.build(familyId);
  }

  @override
  Override overrideWith(AvailableTasksNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: AvailableTasksNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<AvailableTasksNotifier, List<Task>>
  createElement() {
    return _AvailableTasksNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AvailableTasksNotifierProvider &&
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
mixin AvailableTasksNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<Task>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _AvailableTasksNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          AvailableTasksNotifier,
          List<Task>
        >
    with AvailableTasksNotifierRef {
  _AvailableTasksNotifierProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as AvailableTasksNotifierProvider).familyId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
