// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredTasksHash() => r'8b54026f055e751a72198dc10d1a2c8e31fd82bd';

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

/// Computed provider that returns filtered tasks based on the current filter.
///
/// Copied from [filteredTasks].
@ProviderFor(filteredTasks)
const filteredTasksProvider = FilteredTasksFamily();

/// Computed provider that returns filtered tasks based on the current filter.
///
/// Copied from [filteredTasks].
class FilteredTasksFamily extends Family<List<Task>> {
  /// Computed provider that returns filtered tasks based on the current filter.
  ///
  /// Copied from [filteredTasks].
  const FilteredTasksFamily();

  /// Computed provider that returns filtered tasks based on the current filter.
  ///
  /// Copied from [filteredTasks].
  FilteredTasksProvider call(FamilyId familyId) {
    return FilteredTasksProvider(familyId);
  }

  @override
  FilteredTasksProvider getProviderOverride(
    covariant FilteredTasksProvider provider,
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
  String? get name => r'filteredTasksProvider';
}

/// Computed provider that returns filtered tasks based on the current filter.
///
/// Copied from [filteredTasks].
class FilteredTasksProvider extends AutoDisposeProvider<List<Task>> {
  /// Computed provider that returns filtered tasks based on the current filter.
  ///
  /// Copied from [filteredTasks].
  FilteredTasksProvider(FamilyId familyId)
    : this._internal(
        (ref) => filteredTasks(ref as FilteredTasksRef, familyId),
        from: filteredTasksProvider,
        name: r'filteredTasksProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$filteredTasksHash,
        dependencies: FilteredTasksFamily._dependencies,
        allTransitiveDependencies:
            FilteredTasksFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  FilteredTasksProvider._internal(
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
  Override overrideWith(List<Task> Function(FilteredTasksRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: FilteredTasksProvider._internal(
        (ref) => create(ref as FilteredTasksRef),
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
  AutoDisposeProviderElement<List<Task>> createElement() {
    return _FilteredTasksProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredTasksProvider && other.familyId == familyId;
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
mixin FilteredTasksRef on AutoDisposeProviderRef<List<Task>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _FilteredTasksProviderElement
    extends AutoDisposeProviderElement<List<Task>>
    with FilteredTasksRef {
  _FilteredTasksProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as FilteredTasksProvider).familyId;
}

String _$taskListNotifierHash() => r'393ba02e479295eda80e5a6d4da09e69399461b9';

abstract class _$TaskListNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Task>> {
  late final FamilyId familyId;

  FutureOr<List<Task>> build(FamilyId familyId);
}

/// Manages the list of tasks for a family with filtering capabilities.
///
/// This notifier fetches tasks from the repository and provides
/// methods for creating, updating, and deleting tasks.
///
/// Example:
/// ```dart
/// final tasksAsync = ref.watch(taskListNotifierProvider(familyId));
/// final notifier = ref.read(taskListNotifierProvider(familyId).notifier);
/// await notifier.createTask(newTask);
/// ```
///
/// Copied from [TaskListNotifier].
@ProviderFor(TaskListNotifier)
const taskListNotifierProvider = TaskListNotifierFamily();

/// Manages the list of tasks for a family with filtering capabilities.
///
/// This notifier fetches tasks from the repository and provides
/// methods for creating, updating, and deleting tasks.
///
/// Example:
/// ```dart
/// final tasksAsync = ref.watch(taskListNotifierProvider(familyId));
/// final notifier = ref.read(taskListNotifierProvider(familyId).notifier);
/// await notifier.createTask(newTask);
/// ```
///
/// Copied from [TaskListNotifier].
class TaskListNotifierFamily extends Family<AsyncValue<List<Task>>> {
  /// Manages the list of tasks for a family with filtering capabilities.
  ///
  /// This notifier fetches tasks from the repository and provides
  /// methods for creating, updating, and deleting tasks.
  ///
  /// Example:
  /// ```dart
  /// final tasksAsync = ref.watch(taskListNotifierProvider(familyId));
  /// final notifier = ref.read(taskListNotifierProvider(familyId).notifier);
  /// await notifier.createTask(newTask);
  /// ```
  ///
  /// Copied from [TaskListNotifier].
  const TaskListNotifierFamily();

  /// Manages the list of tasks for a family with filtering capabilities.
  ///
  /// This notifier fetches tasks from the repository and provides
  /// methods for creating, updating, and deleting tasks.
  ///
  /// Example:
  /// ```dart
  /// final tasksAsync = ref.watch(taskListNotifierProvider(familyId));
  /// final notifier = ref.read(taskListNotifierProvider(familyId).notifier);
  /// await notifier.createTask(newTask);
  /// ```
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

/// Manages the list of tasks for a family with filtering capabilities.
///
/// This notifier fetches tasks from the repository and provides
/// methods for creating, updating, and deleting tasks.
///
/// Example:
/// ```dart
/// final tasksAsync = ref.watch(taskListNotifierProvider(familyId));
/// final notifier = ref.read(taskListNotifierProvider(familyId).notifier);
/// await notifier.createTask(newTask);
/// ```
///
/// Copied from [TaskListNotifier].
class TaskListNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<TaskListNotifier, List<Task>> {
  /// Manages the list of tasks for a family with filtering capabilities.
  ///
  /// This notifier fetches tasks from the repository and provides
  /// methods for creating, updating, and deleting tasks.
  ///
  /// Example:
  /// ```dart
  /// final tasksAsync = ref.watch(taskListNotifierProvider(familyId));
  /// final notifier = ref.read(taskListNotifierProvider(familyId).notifier);
  /// await notifier.createTask(newTask);
  /// ```
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
