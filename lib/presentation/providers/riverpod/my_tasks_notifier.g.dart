// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_tasks_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$myTasksNotifierHash() => r'5dd827a03fb8ac000166b6b7aac9596707966a62';

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

abstract class _$MyTasksNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Task>> {
  late final FamilyId familyId;
  late final UserId userId;

  FutureOr<List<Task>> build(FamilyId familyId, UserId userId);
}

/// Manages the list of tasks assigned to the current user.
///
/// This notifier streams tasks assigned to a specific user within a family
/// and provides methods for task management.
///
/// Example:
/// ```dart
/// final myTasksAsync = ref.watch(myTasksNotifierProvider(familyId, userId));
/// final notifier = ref.read(myTasksNotifierProvider(familyId, userId).notifier);
/// await notifier.refresh();
/// ```
///
/// Copied from [MyTasksNotifier].
@ProviderFor(MyTasksNotifier)
const myTasksNotifierProvider = MyTasksNotifierFamily();

/// Manages the list of tasks assigned to the current user.
///
/// This notifier streams tasks assigned to a specific user within a family
/// and provides methods for task management.
///
/// Example:
/// ```dart
/// final myTasksAsync = ref.watch(myTasksNotifierProvider(familyId, userId));
/// final notifier = ref.read(myTasksNotifierProvider(familyId, userId).notifier);
/// await notifier.refresh();
/// ```
///
/// Copied from [MyTasksNotifier].
class MyTasksNotifierFamily extends Family<AsyncValue<List<Task>>> {
  /// Manages the list of tasks assigned to the current user.
  ///
  /// This notifier streams tasks assigned to a specific user within a family
  /// and provides methods for task management.
  ///
  /// Example:
  /// ```dart
  /// final myTasksAsync = ref.watch(myTasksNotifierProvider(familyId, userId));
  /// final notifier = ref.read(myTasksNotifierProvider(familyId, userId).notifier);
  /// await notifier.refresh();
  /// ```
  ///
  /// Copied from [MyTasksNotifier].
  const MyTasksNotifierFamily();

  /// Manages the list of tasks assigned to the current user.
  ///
  /// This notifier streams tasks assigned to a specific user within a family
  /// and provides methods for task management.
  ///
  /// Example:
  /// ```dart
  /// final myTasksAsync = ref.watch(myTasksNotifierProvider(familyId, userId));
  /// final notifier = ref.read(myTasksNotifierProvider(familyId, userId).notifier);
  /// await notifier.refresh();
  /// ```
  ///
  /// Copied from [MyTasksNotifier].
  MyTasksNotifierProvider call(FamilyId familyId, UserId userId) {
    return MyTasksNotifierProvider(familyId, userId);
  }

  @override
  MyTasksNotifierProvider getProviderOverride(
    covariant MyTasksNotifierProvider provider,
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
  String? get name => r'myTasksNotifierProvider';
}

/// Manages the list of tasks assigned to the current user.
///
/// This notifier streams tasks assigned to a specific user within a family
/// and provides methods for task management.
///
/// Example:
/// ```dart
/// final myTasksAsync = ref.watch(myTasksNotifierProvider(familyId, userId));
/// final notifier = ref.read(myTasksNotifierProvider(familyId, userId).notifier);
/// await notifier.refresh();
/// ```
///
/// Copied from [MyTasksNotifier].
class MyTasksNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<MyTasksNotifier, List<Task>> {
  /// Manages the list of tasks assigned to the current user.
  ///
  /// This notifier streams tasks assigned to a specific user within a family
  /// and provides methods for task management.
  ///
  /// Example:
  /// ```dart
  /// final myTasksAsync = ref.watch(myTasksNotifierProvider(familyId, userId));
  /// final notifier = ref.read(myTasksNotifierProvider(familyId, userId).notifier);
  /// await notifier.refresh();
  /// ```
  ///
  /// Copied from [MyTasksNotifier].
  MyTasksNotifierProvider(FamilyId familyId, UserId userId)
    : this._internal(
        () =>
            MyTasksNotifier()
              ..familyId = familyId
              ..userId = userId,
        from: myTasksNotifierProvider,
        name: r'myTasksNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$myTasksNotifierHash,
        dependencies: MyTasksNotifierFamily._dependencies,
        allTransitiveDependencies:
            MyTasksNotifierFamily._allTransitiveDependencies,
        familyId: familyId,
        userId: userId,
      );

  MyTasksNotifierProvider._internal(
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
  FutureOr<List<Task>> runNotifierBuild(covariant MyTasksNotifier notifier) {
    return notifier.build(familyId, userId);
  }

  @override
  Override overrideWith(MyTasksNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MyTasksNotifierProvider._internal(
        () =>
            create()
              ..familyId = familyId
              ..userId = userId,
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
  AutoDisposeAsyncNotifierProviderElement<MyTasksNotifier, List<Task>>
  createElement() {
    return _MyTasksNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MyTasksNotifierProvider &&
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
mixin MyTasksNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<Task>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;

  /// The parameter `userId` of this provider.
  UserId get userId;
}

class _MyTasksNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<MyTasksNotifier, List<Task>>
    with MyTasksNotifierRef {
  _MyTasksNotifierProviderElement(super.provider);

  @override
  FamilyId get familyId => (origin as MyTasksNotifierProvider).familyId;
  @override
  UserId get userId => (origin as MyTasksNotifierProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
