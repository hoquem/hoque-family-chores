// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$taskListStreamHash() => r'1112d95866e2fb718900ed7d380621a436975749';

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

/// Manages the list of tasks for a family with real-time updates.
///
/// This notifier streams tasks from the repository providing automatic
/// updates when tasks change in the database.
///
/// Example:
/// ```dart
/// final tasksAsync = ref.watch(taskListStreamProvider(familyId));
/// ```
///
/// Copied from [taskListStream].
@ProviderFor(taskListStream)
const taskListStreamProvider = TaskListStreamFamily();

/// Manages the list of tasks for a family with real-time updates.
///
/// This notifier streams tasks from the repository providing automatic
/// updates when tasks change in the database.
///
/// Example:
/// ```dart
/// final tasksAsync = ref.watch(taskListStreamProvider(familyId));
/// ```
///
/// Copied from [taskListStream].
class TaskListStreamFamily extends Family<AsyncValue<List<Task>>> {
  /// Manages the list of tasks for a family with real-time updates.
  ///
  /// This notifier streams tasks from the repository providing automatic
  /// updates when tasks change in the database.
  ///
  /// Example:
  /// ```dart
  /// final tasksAsync = ref.watch(taskListStreamProvider(familyId));
  /// ```
  ///
  /// Copied from [taskListStream].
  const TaskListStreamFamily();

  /// Manages the list of tasks for a family with real-time updates.
  ///
  /// This notifier streams tasks from the repository providing automatic
  /// updates when tasks change in the database.
  ///
  /// Example:
  /// ```dart
  /// final tasksAsync = ref.watch(taskListStreamProvider(familyId));
  /// ```
  ///
  /// Copied from [taskListStream].
  TaskListStreamProvider call(FamilyId familyId) {
    return TaskListStreamProvider(familyId);
  }

  @override
  TaskListStreamProvider getProviderOverride(
    covariant TaskListStreamProvider provider,
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
  String? get name => r'taskListStreamProvider';
}

/// Manages the list of tasks for a family with real-time updates.
///
/// This notifier streams tasks from the repository providing automatic
/// updates when tasks change in the database.
///
/// Example:
/// ```dart
/// final tasksAsync = ref.watch(taskListStreamProvider(familyId));
/// ```
///
/// Copied from [taskListStream].
class TaskListStreamProvider extends AutoDisposeStreamProvider<List<Task>> {
  /// Manages the list of tasks for a family with real-time updates.
  ///
  /// This notifier streams tasks from the repository providing automatic
  /// updates when tasks change in the database.
  ///
  /// Example:
  /// ```dart
  /// final tasksAsync = ref.watch(taskListStreamProvider(familyId));
  /// ```
  ///
  /// Copied from [taskListStream].
  TaskListStreamProvider(FamilyId familyId)
    : this._internal(
        (ref) => taskListStream(ref as TaskListStreamRef, familyId),
        from: taskListStreamProvider,
        name: r'taskListStreamProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$taskListStreamHash,
        dependencies: TaskListStreamFamily._dependencies,
        allTransitiveDependencies:
            TaskListStreamFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  TaskListStreamProvider._internal(
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
    Stream<List<Task>> Function(TaskListStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TaskListStreamProvider._internal(
        (ref) => create(ref as TaskListStreamRef),
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
  AutoDisposeStreamProviderElement<List<Task>> createElement() {
    return _TaskListStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TaskListStreamProvider && other.familyId == familyId;
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
mixin TaskListStreamRef on AutoDisposeStreamProviderRef<List<Task>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _TaskListStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<Task>>
    with TaskListStreamRef {
  _TaskListStreamProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as TaskListStreamProvider).familyId;
}

String _$taskListNotifierHash() => r'd737e07c9b7c7560c0073a4435f0dcd9da62b95f';

abstract class _$TaskListNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Task>> {
  late final FamilyId familyId;

  FutureOr<List<Task>> build(FamilyId familyId);
}

/// Legacy notifier - kept for backward compatibility with use case methods.
/// Use taskListStreamProvider for real-time updates instead.
///
/// Copied from [TaskListNotifier].
@ProviderFor(TaskListNotifier)
const taskListNotifierProvider = TaskListNotifierFamily();

/// Legacy notifier - kept for backward compatibility with use case methods.
/// Use taskListStreamProvider for real-time updates instead.
///
/// Copied from [TaskListNotifier].
class TaskListNotifierFamily extends Family<AsyncValue<List<Task>>> {
  /// Legacy notifier - kept for backward compatibility with use case methods.
  /// Use taskListStreamProvider for real-time updates instead.
  ///
  /// Copied from [TaskListNotifier].
  const TaskListNotifierFamily();

  /// Legacy notifier - kept for backward compatibility with use case methods.
  /// Use taskListStreamProvider for real-time updates instead.
  ///
  /// Copied from [TaskListNotifier].
  TaskListNotifierProvider call(FamilyId familyId) {
    return TaskListNotifierProvider(familyId);
  }

  @override
  TaskListNotifierProvider getProviderOverride(
    covariant TaskListNotifierProvider provider,
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
  String? get name => r'taskListNotifierProvider';
}

/// Legacy notifier - kept for backward compatibility with use case methods.
/// Use taskListStreamProvider for real-time updates instead.
///
/// Copied from [TaskListNotifier].
class TaskListNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<TaskListNotifier, List<Task>> {
  /// Legacy notifier - kept for backward compatibility with use case methods.
  /// Use taskListStreamProvider for real-time updates instead.
  ///
  /// Copied from [TaskListNotifier].
  TaskListNotifierProvider(FamilyId familyId)
    : this._internal(
        () => TaskListNotifier()..familyId = familyId,
        from: taskListNotifierProvider,
        name: r'taskListNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$taskListNotifierHash,
        dependencies: TaskListNotifierFamily._dependencies,
        allTransitiveDependencies:
            TaskListNotifierFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  TaskListNotifierProvider._internal(
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
  FutureOr<List<Task>> runNotifierBuild(covariant TaskListNotifier notifier) {
    return notifier.build(familyId);
  }

  @override
  Override overrideWith(TaskListNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: TaskListNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<TaskListNotifier, List<Task>>
  createElement() {
    return _TaskListNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TaskListNotifierProvider && other.familyId == familyId;
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
mixin TaskListNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<Task>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _TaskListNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<TaskListNotifier, List<Task>>
    with TaskListNotifierRef {
  _TaskListNotifierProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as TaskListNotifierProvider).familyId;
}

String _$taskFilterNotifierHash() =>
    r'869c198a8a1c27ae7eb4ec475cfe33c6f8d8ac0c';

/// Provider for task filtering state.
///
/// Copied from [TaskFilterNotifier].
@ProviderFor(TaskFilterNotifier)
final taskFilterNotifierProvider =
    AutoDisposeNotifierProvider<TaskFilterNotifier, TaskFilterType>.internal(
      TaskFilterNotifier.new,
      name: r'taskFilterNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$taskFilterNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TaskFilterNotifier = AutoDisposeNotifier<TaskFilterType>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
