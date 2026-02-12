// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_approvals_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingApprovalsNotifierHash() =>
    r'78729db2ae6b0f0766c0ce4d69e04b8191b4de31';

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

abstract class _$PendingApprovalsNotifier
    extends BuildlessAutoDisposeStreamNotifier<List<Task>> {
  late final FamilyId familyId;

  Stream<List<Task>> build(FamilyId familyId);
}

/// Manages pending approval tasks for a family.
///
/// This notifier streams tasks with pendingApproval status and provides
/// methods for approving and rejecting tasks.
///
/// Copied from [PendingApprovalsNotifier].
@ProviderFor(PendingApprovalsNotifier)
const pendingApprovalsNotifierProvider = PendingApprovalsNotifierFamily();

/// Manages pending approval tasks for a family.
///
/// This notifier streams tasks with pendingApproval status and provides
/// methods for approving and rejecting tasks.
///
/// Copied from [PendingApprovalsNotifier].
class PendingApprovalsNotifierFamily extends Family<AsyncValue<List<Task>>> {
  /// Manages pending approval tasks for a family.
  ///
  /// This notifier streams tasks with pendingApproval status and provides
  /// methods for approving and rejecting tasks.
  ///
  /// Copied from [PendingApprovalsNotifier].
  const PendingApprovalsNotifierFamily();

  /// Manages pending approval tasks for a family.
  ///
  /// This notifier streams tasks with pendingApproval status and provides
  /// methods for approving and rejecting tasks.
  ///
  /// Copied from [PendingApprovalsNotifier].
  PendingApprovalsNotifierProvider call(FamilyId familyId) {
    return PendingApprovalsNotifierProvider(familyId);
  }

  @override
  PendingApprovalsNotifierProvider getProviderOverride(
    covariant PendingApprovalsNotifierProvider provider,
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
  String? get name => r'pendingApprovalsNotifierProvider';
}

/// Manages pending approval tasks for a family.
///
/// This notifier streams tasks with pendingApproval status and provides
/// methods for approving and rejecting tasks.
///
/// Copied from [PendingApprovalsNotifier].
class PendingApprovalsNotifierProvider
    extends
        AutoDisposeStreamNotifierProviderImpl<
          PendingApprovalsNotifier,
          List<Task>
        > {
  /// Manages pending approval tasks for a family.
  ///
  /// This notifier streams tasks with pendingApproval status and provides
  /// methods for approving and rejecting tasks.
  ///
  /// Copied from [PendingApprovalsNotifier].
  PendingApprovalsNotifierProvider(FamilyId familyId)
    : this._internal(
        () => PendingApprovalsNotifier()..familyId = familyId,
        from: pendingApprovalsNotifierProvider,
        name: r'pendingApprovalsNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$pendingApprovalsNotifierHash,
        dependencies: PendingApprovalsNotifierFamily._dependencies,
        allTransitiveDependencies:
            PendingApprovalsNotifierFamily._allTransitiveDependencies,
        familyId: familyId,
      );

  PendingApprovalsNotifierProvider._internal(
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
  Stream<List<Task>> runNotifierBuild(
    covariant PendingApprovalsNotifier notifier,
  ) {
    return notifier.build(familyId);
  }

  @override
  Override overrideWith(PendingApprovalsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: PendingApprovalsNotifierProvider._internal(
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
  AutoDisposeStreamNotifierProviderElement<PendingApprovalsNotifier, List<Task>>
  createElement() {
    return _PendingApprovalsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingApprovalsNotifierProvider &&
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
mixin PendingApprovalsNotifierRef
    on AutoDisposeStreamNotifierProviderRef<List<Task>> {
  /// The parameter `familyId` of this provider.
  FamilyId get familyId;
}

class _PendingApprovalsNotifierProviderElement
    extends
        AutoDisposeStreamNotifierProviderElement<
          PendingApprovalsNotifier,
          List<Task>
        >
    with PendingApprovalsNotifierRef {
  _PendingApprovalsNotifierProviderElement(super.provider);

  @override
  FamilyId get familyId =>
      (origin as PendingApprovalsNotifierProvider).familyId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
