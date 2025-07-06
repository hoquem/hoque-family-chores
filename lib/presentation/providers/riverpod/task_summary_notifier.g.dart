// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_summary_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$taskSummaryNotifierHash() =>
    r'1bb4c7aaa2e976ff457e436d95144e454ed3bd5f';

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

abstract class _$TaskSummaryNotifier
    extends BuildlessAutoDisposeAsyncNotifier<TaskSummary> {
  late final FamilyId familyId;

  FutureOr<TaskSummary> build(FamilyId familyId);
}

/// Manages task summary data for a family.
///
/// This notifier streams tasks and computes summary statistics
/// including completed tasks, pending tasks, and points earned.
///
/// Example:
/// ```dart
/// final summaryAsync = ref.watch(taskSummaryNotifierProvider(familyId));
/// final notifier = ref.read(taskSummaryNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
///
/// Copied from [TaskSummaryNotifier].
@ProviderFor(TaskSummaryNotifier)
const taskSummaryNotifierProvider = TaskSummaryNotifierFamily();

/// Manages task summary data for a family.
///
/// This notifier streams tasks and computes summary statistics
/// including completed tasks, pending tasks, and points earned.
///
/// Example:
/// ```dart
/// final summaryAsync = ref.watch(taskSummaryNotifierProvider(familyId));
/// final notifier = ref.read(taskSummaryNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
///
/// Copied from [TaskSummaryNotifier].
class TaskSummaryNotifierFamily extends Family<AsyncValue<TaskSummary>> {
  /// Manages task summary data for a family.
  ///
  /// This notifier streams tasks and computes summary statistics
  /// including completed tasks, pending tasks, and points earned.
  ///
  /// Example:
  /// ```dart
  /// final summaryAsync = ref.watch(taskSummaryNotifierProvider(familyId));
  /// final notifier = ref.read(taskSummaryNotifierProvider(familyId).notifier);
  /// await notifier.refresh();
  /// ```
  ///
  /// Copied from [TaskSummaryNotifier].
  const TaskSummaryNotifierFamily();

  /// Manages task summary data for a family.
  ///
  /// This notifier streams tasks and computes summary statistics
  /// including completed tasks, pending tasks, and points earned.
  ///
  /// Example:
  /// ```dart
  /// final summaryAsync = ref.watch(taskSummaryNotifierProvider(familyId));
  /// final notifier = ref.read(taskSummaryNotifierProvider(familyId).notifier);
  /// await notifier.refresh();
  /// ```
  ///
  /// Copied from [TaskSummaryNotifier].
  TaskSummaryNotifierProvider call(FamilyId familyId) {
    return TaskSummaryNotifierProvider(familyId);
  }

  @override
  TaskSummaryNotifierProvider getProviderOverride(
    covariant TaskSummaryNotifierProvider provider,
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
  String? get name => r'taskSummaryNotifierProvider';
}

/// Manages task summary data for a family.
///
/// This notifier streams tasks and computes summary statistics
/// including completed tasks, pending tasks, and points earned.
///
/// Example:
/// ```dart
/// final summaryAsync = ref.watch(taskSummaryNotifierProvider(familyId));
/// final notifier = ref.read(taskSummaryNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
///
/// Copied from [TaskSummaryNotifier].
class TaskSummaryNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<TaskSummaryNotifier, TaskSummary> {
  /// Manages task summary data for a family.
  ///
  /// This notifier streams tasks and computes summary statistics
  /// including completed tasks, pending tasks, and points earned.
  ///
  /// Example:
  /// ```dart
  /// final summaryAsync = ref.watch(taskSummaryNotifierProvider(familyId));
  /// final notifier = ref.read(taskSummaryNotifierProvider(familyId).notifier);
  /// await notifier.refresh();
  /// ```
  ///
  /// Copied from [TaskSummaryNotifier].
  TaskSummaryNotifierProvider(FamilyId familyId)
    : this._internal(
        () => TaskSummaryNotifier()..familyId = familyId,
        from: taskSummaryNotifierProvider,
        name: r'taskSummaryNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$taskSummaryNotifierHash,
        dependencies: TaskSummaryNotifierFamily._dependencies,
        allTransitiveDependencies:
            TaskSummaryNotifierFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  TaskSummaryNotifierProvider._internal(
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
  FutureOr<TaskSummary> runNotifierBuild(
    covariant TaskSummaryNotifier notifier,
  ) {
    return notifier.build(familyId);
  }

  @override
  Override overrideWith(TaskSummaryNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: TaskSummaryNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<TaskSummaryNotifier, TaskSummary>
  createElement() {
    return _TaskSummaryNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TaskSummaryNotifierProvider && other.familyId == familyId;
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
mixin TaskSummaryNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<TaskSummary> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _TaskSummaryNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          TaskSummaryNotifier,
          TaskSummary
        >
    with TaskSummaryNotifierRef {
  _TaskSummaryNotifierProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as TaskSummaryNotifierProvider).familyId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
