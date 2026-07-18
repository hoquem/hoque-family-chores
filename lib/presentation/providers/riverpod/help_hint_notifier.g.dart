// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'help_hint_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$helpHintSeenHash() => r'e28d19242314f1f38b9c313b6c48bc6f0be1ede7';

/// Whether the user has ever opened a help sheet.
///
/// Drives a one-time pulse on the `?` button so first-timers notice it. Once
/// they open help anywhere, the pulse never returns.
///
/// Defaults to `true` (no pulse) and corrects to the stored value on load, so a
/// returning user who has already seen it never flickers a pulse; only a genuine
/// first-timer (stored value false/absent) starts pulsing.
///
/// Copied from [HelpHintSeen].
@ProviderFor(HelpHintSeen)
final helpHintSeenProvider =
    AutoDisposeNotifierProvider<HelpHintSeen, bool>.internal(
      HelpHintSeen.new,
      name: r'helpHintSeenProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$helpHintSeenHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$HelpHintSeen = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
