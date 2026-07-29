// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_milestone_watcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$streakMilestoneWatcherHash() =>
    r'76c6ceaa0b1ba0014223ae6b9fcc19a54a06dbaf';

/// Session-scoped streak milestone detector. Home reports the live streak
/// (it already computes it from the task stream); crossing INTO a milestone
/// during the session celebrates once. The first report is the baseline
/// (spec §2) — launching the app on day 7 must not celebrate day 7.
///
/// Copied from [StreakMilestoneWatcher].
@ProviderFor(StreakMilestoneWatcher)
final streakMilestoneWatcherProvider =
    NotifierProvider<StreakMilestoneWatcher, void>.internal(
      StreakMilestoneWatcher.new,
      name: r'streakMilestoneWatcherProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$streakMilestoneWatcherHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StreakMilestoneWatcher = Notifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
