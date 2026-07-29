// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'celebration.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$celebrationQueueHash() => r'27743b8c8d4206b51764f5eab71dbd9fb589c9da';

/// FIFO of pending celebrations. One plays at a time ("one celebration moment
/// per screen", DESIGN.md); the listener advances it when the overlay ends.
///
/// Copied from [CelebrationQueue].
@ProviderFor(CelebrationQueue)
final celebrationQueueProvider =
    NotifierProvider<CelebrationQueue, List<QueuedCelebration>>.internal(
      CelebrationQueue.new,
      name: r'celebrationQueueProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$celebrationQueueHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CelebrationQueue = Notifier<List<QueuedCelebration>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
