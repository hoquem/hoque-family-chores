// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'star_award_watcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$starAwardWatcherHash() => r'2691380178769852572783c13eba24228e94be95';

/// Watches the signed-in user's star balance and celebrates increases.
///
/// Cold start sets a baseline (spec §2): the first emission for a user records
/// state and celebrates nothing, so history never replays at launch. Only
/// deltas observed after the baseline celebrate. Decreases (spending) are the
/// treat flow's job, not ours.
///
/// Copied from [StarAwardWatcher].
@ProviderFor(StarAwardWatcher)
final starAwardWatcherProvider =
    NotifierProvider<StarAwardWatcher, void>.internal(
      StarAwardWatcher.new,
      name: r'starAwardWatcherProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$starAwardWatcherHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StarAwardWatcher = Notifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
