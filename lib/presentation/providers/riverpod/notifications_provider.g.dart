// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationsHash() => r'b6b0e72bd351d76610dc8303c4afb8cd9af050c7';

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

/// Streams the user's notifications, newest first.
///
/// Failures from the underlying stream surface as the provider's error
/// state — never as a silently empty list.
///
/// Copied from [notifications].
@ProviderFor(notifications)
const notificationsProvider = NotificationsFamily();

/// Streams the user's notifications, newest first.
///
/// Failures from the underlying stream surface as the provider's error
/// state — never as a silently empty list.
///
/// Copied from [notifications].
class NotificationsFamily extends Family<AsyncValue<List<Notification>>> {
  /// Streams the user's notifications, newest first.
  ///
  /// Failures from the underlying stream surface as the provider's error
  /// state — never as a silently empty list.
  ///
  /// Copied from [notifications].
  const NotificationsFamily();

  /// Streams the user's notifications, newest first.
  ///
  /// Failures from the underlying stream surface as the provider's error
  /// state — never as a silently empty list.
  ///
  /// Copied from [notifications].
  NotificationsProvider call(UserId userId) {
    return NotificationsProvider(userId);
  }

  @override
  NotificationsProvider getProviderOverride(
    covariant NotificationsProvider provider,
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
  String? get name => r'notificationsProvider';
}

/// Streams the user's notifications, newest first.
///
/// Failures from the underlying stream surface as the provider's error
/// state — never as a silently empty list.
///
/// Copied from [notifications].
class NotificationsProvider
    extends AutoDisposeStreamProvider<List<Notification>> {
  /// Streams the user's notifications, newest first.
  ///
  /// Failures from the underlying stream surface as the provider's error
  /// state — never as a silently empty list.
  ///
  /// Copied from [notifications].
  NotificationsProvider(UserId userId)
    : this._internal(
        (ref) => notifications(ref as NotificationsRef, userId),
        from: notificationsProvider,
        name: r'notificationsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$notificationsHash,
        dependencies: NotificationsFamily._dependencies,
        allTransitiveDependencies:
            NotificationsFamily._allTransitiveDependencies,
        userId: userId,
      );

  NotificationsProvider._internal(
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
  Override overrideWith(
    Stream<List<Notification>> Function(NotificationsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NotificationsProvider._internal(
        (ref) => create(ref as NotificationsRef),
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
  AutoDisposeStreamProviderElement<List<Notification>> createElement() {
    return _NotificationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationsProvider && other.userId == userId;
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
mixin NotificationsRef on AutoDisposeStreamProviderRef<List<Notification>> {
  /// The parameter `userId` of this provider.
  UserId get userId;
}

class _NotificationsProviderElement
    extends AutoDisposeStreamProviderElement<List<Notification>>
    with NotificationsRef {
  _NotificationsProviderElement(super.provider);

  @override
  UserId get userId => (origin as NotificationsProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
