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

String _$filteredTasksHash() => r'48a687b08810f217a1ef73f76879d58a766180da';

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

String _$filteredQuestsStreamHash() =>
    r'4b722ec7a9f62c4d5ef25bfd70282eceada95c6e';

/// Stream provider for role-based filtered quests (Quest Board specific).
/// Children see only their own quests, parents see all or filtered by assignee.
///
/// Copied from [filteredQuestsStream].
@ProviderFor(filteredQuestsStream)
const filteredQuestsStreamProvider = FilteredQuestsStreamFamily();

/// Stream provider for role-based filtered quests (Quest Board specific).
/// Children see only their own quests, parents see all or filtered by assignee.
///
/// Copied from [filteredQuestsStream].
class FilteredQuestsStreamFamily extends Family<AsyncValue<List<Task>>> {
  /// Stream provider for role-based filtered quests (Quest Board specific).
  /// Children see only their own quests, parents see all or filtered by assignee.
  ///
  /// Copied from [filteredQuestsStream].
  const FilteredQuestsStreamFamily();

  /// Stream provider for role-based filtered quests (Quest Board specific).
  /// Children see only their own quests, parents see all or filtered by assignee.
  ///
  /// Copied from [filteredQuestsStream].
  FilteredQuestsStreamProvider call(
    FamilyId familyId,
    UserId currentUserId,
    bool isParent,
  ) {
    return FilteredQuestsStreamProvider(familyId, currentUserId, isParent);
  }

  @override
  FilteredQuestsStreamProvider getProviderOverride(
    covariant FilteredQuestsStreamProvider provider,
  ) {
    return call(provider.familyId, provider.currentUserId, provider.isParent);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'filteredQuestsStreamProvider';
}

/// Stream provider for role-based filtered quests (Quest Board specific).
/// Children see only their own quests, parents see all or filtered by assignee.
///
/// Copied from [filteredQuestsStream].
class FilteredQuestsStreamProvider
    extends AutoDisposeStreamProvider<List<Task>> {
  /// Stream provider for role-based filtered quests (Quest Board specific).
  /// Children see only their own quests, parents see all or filtered by assignee.
  ///
  /// Copied from [filteredQuestsStream].
  FilteredQuestsStreamProvider(
    FamilyId familyId,
    UserId currentUserId,
    bool isParent,
  ) : this._internal(
        (ref) => filteredQuestsStream(
          ref as FilteredQuestsStreamRef,
          familyId,
          currentUserId,
          isParent,
        ),
        from: filteredQuestsStreamProvider,
        name: r'filteredQuestsStreamProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$filteredQuestsStreamHash,
        dependencies: FilteredQuestsStreamFamily._dependencies,
        allTransitiveDependencies:
            FilteredQuestsStreamFamily._allTransitiveDependencies,
        familyId: familyId,
        currentUserId: currentUserId,
        isParent: isParent,
      );

  FilteredQuestsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.familyId,
    required this.currentUserId,
    required this.isParent,
  }) : super.internal();

  final FamilyId familyId;
  final UserId currentUserId;
  final bool isParent;

  @override
  Override overrideWith(
    Stream<List<Task>> Function(FilteredQuestsStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilteredQuestsStreamProvider._internal(
        (ref) => create(ref as FilteredQuestsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        familyId: familyId,
        currentUserId: currentUserId,
        isParent: isParent,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Task>> createElement() {
    return _FilteredQuestsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredQuestsStreamProvider &&
        other.familyId == familyId &&
        other.currentUserId == currentUserId &&
        other.isParent == isParent;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, familyId.hashCode);
    hash = _SystemHash.combine(hash, currentUserId.hashCode);
    hash = _SystemHash.combine(hash, isParent.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FilteredQuestsStreamRef on AutoDisposeStreamProviderRef<List<Task>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;

  /// The parameter `currentUserId` of this provider.
  UserId get currentUserId;

  /// The parameter `isParent` of this provider.
  bool get isParent;
}

class _FilteredQuestsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<Task>>
    with FilteredQuestsStreamRef {
  _FilteredQuestsStreamProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as FilteredQuestsStreamProvider).familyId;
  @override
  UserId get currentUserId =>
      (origin as FilteredQuestsStreamProvider).currentUserId;
  @override
  bool get isParent => (origin as FilteredQuestsStreamProvider).isParent;
}

String _$taskListNotifierHash() => r'393ba02e479295eda80e5a6d4da09e69399461b9';

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
String _$assigneeFilterNotifierHash() =>
    r'8a60df51b2f5c8b317d3d213a160d4a3b423fd34';

/// Provider for assignee filtering (for parent view).
/// Stores which child's quests to show, or null for "All Family".
///
/// Copied from [AssigneeFilterNotifier].
@ProviderFor(AssigneeFilterNotifier)
final assigneeFilterNotifierProvider =
    AutoDisposeNotifierProvider<AssigneeFilterNotifier, UserId?>.internal(
      AssigneeFilterNotifier.new,
      name: r'assigneeFilterNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$assigneeFilterNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AssigneeFilterNotifier = AutoDisposeNotifier<UserId?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
