# Sound Effects Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Play a soft tick when a chore is marked done and a short sound on each of the three celebrations, behind a per-device "Sound effects" toggle that is on by default.

**Architecture:** A small `lib/presentation/sound/` module: an `AppSound` enum mapping moments to bundled assets, a `SoundPlayer` seam (production impl on `audioplayers` in an ambient audio session), a `SoundService` that checks the toggle, and hand-written Riverpod providers. Celebrations play from `CelebrationOverlayView` via an `onShow` callback wired by `CelebrationListener`; the tick plays in `TaskListNotifier.completeTask`'s success branch.

**Tech Stack:** Flutter 3.47.5, Riverpod 2 (hand-written providers, no codegen), `audioplayers`, `shared_preferences`, Kenney CC0 audio.

**Spec:** `docs/superpowers/specs/2026-10-06-sound-effects-design.md`

## Global Constraints

- **No codegen.** `build_runner` is broken on this toolchain and deletes generated files. Write providers by hand with `Provider` / `NotifierProvider`; never add `@riverpod` or a `part '*.g.dart'` to new files.
- Sounds only at four moments: `choreDone`, `starsAwarded`, `treatRedeemed`, `streakMilestone`.
- Toggle key `sound_effects_enabled` in `SharedPreferences`; absent means `true`.
- Ambient session: iOS `AVAudioSessionCategory.ambient` (silent switch mutes, mixes with other audio); Android usage `assistanceSonification`, content `sonification`, audio focus `none`.
- Clips: tick ≤ 0.3 s, others ≤ 1.5 s, all four < 100 KB total, AAC `.m4a`.
- Playback failure: log at error level, never throw out of `SoundService.play`.
- Reduced motion does NOT silence the celebration sound.
- Toggle copy: "Sound effects", icon `Icons.volume_up`, after "Notifications" on the profile screen.

---

### Task 1: Sound assets, dependency, and `AppSound`

**Files:**
- Create: `assets/sounds/chore_done.m4a`, `stars_awarded.m4a`, `treat_redeemed.m4a`, `streak_milestone.m4a`, `assets/sounds/README.md`
- Create: `lib/presentation/sound/app_sound.dart`
- Modify: `pubspec.yaml` (dependency + `flutter: assets:`)
- Test: `test/presentation/sound/app_sound_test.dart`

**Interfaces:**
- Produces: `enum AppSound { choreDone, starsAwarded, treatRedeemed, streakMilestone }` with `final String asset` (path relative to `assets/`, e.g. `sounds/chore_done.m4a`) and `static AppSound forCelebration(CelebrationKind kind)`.

- [ ] **Step 1: Add the dependency**

Run: `flutter pub add audioplayers`
Expected: `pubspec.yaml` gains `audioplayers: ^6.x`; `pubspec.lock` updated.

- [ ] **Step 2: Fetch and convert the Kenney CC0 sounds**

Download "Interface Sounds" from https://kenney.nl/assets/interface-sounds (CC0) into the scratchpad, unzip, audition candidates with `afplay`, and pick: a short soft click for the tick; a bright rising chime for stars; a cheerful two-note for treats; a slightly longer flourish for streaks. Convert, trimming silence and lowering the tick:

```bash
ffmpeg -i <src>.ogg -af "silenceremove=1:0:-50dB,volume=-6dB" -t 0.3 -c:a aac -b:a 64k assets/sounds/chore_done.m4a
ffmpeg -i <src>.ogg -af "silenceremove=1:0:-50dB" -t 1.5 -c:a aac -b:a 64k assets/sounds/stars_awarded.m4a
# same pattern for treat_redeemed.m4a and streak_milestone.m4a
du -ch assets/sounds/*.m4a   # total must be < 100K
```

Write `assets/sounds/README.md`: pack name, URL, "CC0 1.0 (public domain), no attribution required", and a table of source file → asset name.

- [ ] **Step 3: Register the assets** in `pubspec.yaml` under `flutter:` (after `uses-material-design: true`):

```yaml
  assets:
    - assets/sounds/
```

- [ ] **Step 4: Write the failing test**

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/sound/app_sound.dart';

void main() {
  test('every sound has a bundled asset file', () {
    for (final sound in AppSound.values) {
      expect(File('assets/${sound.asset}').existsSync(), isTrue,
          reason: '${sound.name} -> assets/${sound.asset} is missing');
    }
  });

  test('each celebration kind maps to its own sound', () {
    expect(AppSound.forCelebration(const StarsAwarded(5)), AppSound.starsAwarded);
    expect(AppSound.forCelebration(const TreatRedeemed('Bike ride')), AppSound.treatRedeemed);
    expect(AppSound.forCelebration(const StreakMilestone(7)), AppSound.streakMilestone);
  });
}
```

- [ ] **Step 5: Run it, expect a compile failure** (`app_sound.dart` missing)

Run: `flutter test test/presentation/sound/app_sound_test.dart`

- [ ] **Step 6: Implement `lib/presentation/sound/app_sound.dart`**

```dart
import 'package:hoque_family_chores/presentation/motion/celebration.dart';

/// The only moments that make a sound (sound spec §Decisions). Adding one
/// here is a product decision, not a refactor.
enum AppSound {
  choreDone('sounds/chore_done.m4a'),
  starsAwarded('sounds/stars_awarded.m4a'),
  treatRedeemed('sounds/treat_redeemed.m4a'),
  streakMilestone('sounds/streak_milestone.m4a');

  const AppSound(this.asset);

  /// Path relative to `assets/`, the form `audioplayers`' `AssetSource` takes.
  final String asset;

  /// Exhaustive over the sealed [CelebrationKind]: a new celebration fails
  /// to compile here until it is given a sound.
  static AppSound forCelebration(CelebrationKind kind) => switch (kind) {
        StarsAwarded() => AppSound.starsAwarded,
        TreatRedeemed() => AppSound.treatRedeemed,
        StreakMilestone() => AppSound.streakMilestone,
      };
}
```

- [ ] **Step 7: Run the test, expect PASS**

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock assets/sounds lib/presentation/sound/app_sound.dart test/presentation/sound/app_sound_test.dart
git commit -m "feat(sound): bundle four CC0 sounds and map moments to them"
```

---

### Task 2: `SoundService`, toggle, and providers

**Files:**
- Create: `lib/presentation/sound/sound_player.dart`, `lib/presentation/sound/sound_service.dart`
- Test: `test/presentation/sound/sound_service_test.dart`, `test/presentation/sound/fake_sound_player.dart`

**Interfaces:**
- Consumes: `AppSound` (Task 1).
- Produces:
  - `abstract interface class SoundPlayer { Future<void> play(String asset); }`
  - `class AudioplayersSoundPlayer implements SoundPlayer`
  - `class SoundService { SoundService({required SoundPlayer player, required bool Function() isEnabled}); Future<void> play(AppSound sound); }`
  - `final soundEnabledProvider = NotifierProvider<SoundEnabled, bool>`; `SoundEnabled.setEnabled(bool)`
  - `final soundPlayerProvider = Provider<SoundPlayer>`; `final soundServiceProvider = Provider<SoundService>`
  - Test helper `FakeSoundPlayer` with `final List<String> played` and `bool throwOnPlay`.

- [ ] **Step 1: Write the fake** `test/presentation/sound/fake_sound_player.dart`

```dart
import 'package:hoque_family_chores/presentation/sound/sound_player.dart';

/// Records what would have been played; never touches a platform channel.
class FakeSoundPlayer implements SoundPlayer {
  final List<String> played = [];
  bool throwOnPlay = false;

  @override
  Future<void> play(String asset) async {
    if (throwOnPlay) throw StateError('no audio device');
    played.add(asset);
  }
}
```

- [ ] **Step 2: Write the failing tests** `test/presentation/sound/sound_service_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoque_family_chores/presentation/sound/app_sound.dart';
import 'package:hoque_family_chores/presentation/sound/sound_service.dart';

import 'fake_sound_player.dart';

void main() {
  group('SoundService', () {
    test('plays the asset when enabled', () async {
      final player = FakeSoundPlayer();
      await SoundService(player: player, isEnabled: () => true)
          .play(AppSound.choreDone);
      expect(player.played, [AppSound.choreDone.asset]);
    });

    test('plays nothing when disabled', () async {
      final player = FakeSoundPlayer();
      await SoundService(player: player, isEnabled: () => false)
          .play(AppSound.starsAwarded);
      expect(player.played, isEmpty);
    });

    test('a failing player does not throw out of play', () async {
      final player = FakeSoundPlayer()..throwOnPlay = true;
      await expectLater(
        SoundService(player: player, isEnabled: () => true)
            .play(AppSound.treatRedeemed),
        completes,
      );
    });
  });

  group('soundEnabledProvider', () {
    test('defaults to on when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(soundEnabledProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(soundEnabledProvider), isTrue);
    });

    test('loads a stored off', () async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(soundEnabledProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(soundEnabledProvider), isFalse);
    });

    test('setEnabled(false) persists', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(soundEnabledProvider.notifier).setEnabled(false);
      expect(container.read(soundEnabledProvider), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sound_effects_enabled'), isFalse);
    });

    test('the service follows the toggle', () async {
      SharedPreferences.setMockInitialValues({});
      final player = FakeSoundPlayer();
      final container = ProviderContainer(
        overrides: [soundPlayerProvider.overrideWithValue(player)],
      );
      addTearDown(container.dispose);
      await container.read(soundEnabledProvider.notifier).setEnabled(false);
      await container.read(soundServiceProvider).play(AppSound.choreDone);
      expect(player.played, isEmpty);
    });
  });
}
```

- [ ] **Step 3: Run, expect compile failure**

Run: `flutter test test/presentation/sound/sound_service_test.dart`

- [ ] **Step 4: Implement `lib/presentation/sound/sound_player.dart`**

Check the installed API first (`grep -rn "class AudioContextIOS\|class AudioContextAndroid\|mixWithOthers" ~/.pub-cache/hosted/pub.dev/audioplayers_platform_interface-*/lib`): if `AudioContextIOS` asserts on options for the `ambient` category, pass an empty options set (ambient already mixes).

```dart
import 'package:audioplayers/audioplayers.dart';

/// Plays one bundled clip. The seam that keeps tests off platform channels.
abstract interface class SoundPlayer {
  Future<void> play(String asset);
}

/// Production player: one low-latency `AudioPlayer`, created on first use so
/// nothing touches the platform until a sound is actually wanted.
class AudioplayersSoundPlayer implements SoundPlayer {
  /// Ambient: the iOS silent switch mutes it and it mixes with whatever the
  /// parent is already listening to; on Android no audio focus is requested,
  /// so other audio keeps playing.
  static final _ambient = AudioContext(
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  AudioPlayer? _player;

  @override
  Future<void> play(String asset) async {
    final player = _player ??= await _create();
    await player.play(AssetSource(asset));
  }

  Future<AudioPlayer> _create() async {
    final player = AudioPlayer();
    await player.setAudioContext(_ambient);
    await player.setPlayerMode(PlayerMode.lowLatency);
    return player;
  }
}
```

- [ ] **Step 5: Implement `lib/presentation/sound/sound_service.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hoque_family_chores/presentation/sound/app_sound.dart';
import 'package:hoque_family_chores/presentation/sound/sound_player.dart';
import 'package:hoque_family_chores/utils/logger.dart';

/// Plays an [AppSound] if the device's toggle allows it.
///
/// A playback failure is logged and swallowed: a missing sound must never
/// block completing a chore or a celebration (sound spec §2).
class SoundService {
  SoundService({required SoundPlayer player, required bool Function() isEnabled})
      : _player = player,
        _isEnabled = isEnabled;

  final SoundPlayer _player;
  final bool Function() _isEnabled;

  Future<void> play(AppSound sound) async {
    if (!_isEnabled()) return;
    try {
      await _player.play(sound.asset);
    } catch (e, st) {
      AppLogger().e('[Sound] could not play ${sound.name}', error: e, stackTrace: st);
    }
  }
}

/// The per-device "Sound effects" toggle. On by default; corrects to the
/// stored value once SharedPreferences has loaded.
class SoundEnabled extends Notifier<bool> {
  static const _key = 'sound_effects_enabled';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    // Fire-and-forget from build(): log a prefs failure rather than throw an
    // unhandled async error; sound simply stays on.
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? true;
    } catch (e) {
      AppLogger().w('[Sound] could not read the toggle: $e');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}

final soundEnabledProvider =
    NotifierProvider<SoundEnabled, bool>(SoundEnabled.new);

final soundPlayerProvider =
    Provider<SoundPlayer>((ref) => AudioplayersSoundPlayer());

final soundServiceProvider = Provider<SoundService>(
  (ref) => SoundService(
    player: ref.watch(soundPlayerProvider),
    isEnabled: () => ref.read(soundEnabledProvider),
  ),
);
```

- [ ] **Step 6: Run the tests, expect PASS**

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/sound test/presentation/sound
git commit -m "feat(sound): add SoundService behind a per-device toggle"
```

---

### Task 3: Sound on celebrations

**Files:**
- Modify: `lib/presentation/motion/celebration_overlay.dart` (constructor + post-frame callback)
- Modify: `lib/presentation/motion/celebration_listener.dart` (pass `onShow`)
- Test: `test/presentation/motion/celebration_overlay_test.dart` (add cases), `test/presentation/sound/celebration_sound_test.dart` (new)

**Interfaces:**
- Consumes: `AppSound.forCelebration`, `soundServiceProvider`, `soundPlayerProvider`, `FakeSoundPlayer`.
- Produces: `CelebrationOverlayView({required kind, required onDone, VoidCallback? onShow})`. `onShow` is called once per show, before the reduced-motion branch.

- [ ] **Step 1: Add failing overlay tests** to `celebration_overlay_test.dart`. Extend `_pump` with `VoidCallback? onShow` passed to the view, then:

```dart
  testWidgets('onShow fires once when the celebration starts', (tester) async {
    var shows = 0;
    await _pump(tester, const StarsAwarded(10), onShow: () => shows++);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(shows, 1);
  });

  testWidgets('reduced motion still fires onShow (sound is not motion)',
      (tester) async {
    var shows = 0;
    await _pump(tester, const StarsAwarded(5),
        reducedMotion: true, onShow: () => shows++);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(shows, 1);
  });
```

- [ ] **Step 2: Run, expect compile failure** (no `onShow` param)

Run: `flutter test test/presentation/motion/celebration_overlay_test.dart`

- [ ] **Step 3: Implement in the overlay**

Constructor: `const CelebrationOverlayView({super.key, required this.kind, required this.onDone, this.onShow});` plus field doc:

```dart
  /// Called once as the celebration starts, in both the animated and the
  /// reduced-motion variant. The listener plays the sound from here.
  final VoidCallback? onShow;
```

In the post-frame callback, directly after `SemanticsService.announce(...)`:

```dart
      widget.onShow?.call();
```

Update the class doc to "star-burst + headline + one haptic + optional sound".

- [ ] **Step 4: Run overlay tests, expect PASS**

- [ ] **Step 5: Write the failing wiring test** `test/presentation/sound/celebration_sound_test.dart`, reusing the harness from `test/presentation/motion/review_prompt_celebration_test.dart` (fixed child auth user so the review prompt path stays inert):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/celebration_listener.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/sound/app_sound.dart';
import 'package:hoque_family_chores/presentation/sound/sound_service.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import 'fake_sound_player.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

final _child = User(
  id: UserId('child_1'),
  name: 'Child',
  familyId: FamilyId('family_1'),
  role: UserRole.child,
  points: Points(0),
  joinedAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  testWidgets('each celebration plays its own sound, in order',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final player = FakeSoundPlayer();
    final container = ProviderContainer(overrides: [
      authNotifierProvider
          .overrideWith(() => _FixedAuthNotifier(AuthState(user: _child))),
      soundPlayerProvider.overrideWithValue(player),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: appLightTheme,
        home: const Scaffold(body: CelebrationListener(child: SizedBox.expand())),
      ),
    ));
    final queue = container.read(celebrationQueueProvider.notifier);
    queue.celebrate(const StarsAwarded(10));
    queue.celebrate(const TreatRedeemed('Bike ride'));
    queue.celebrate(const StreakMilestone(7));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 800));
    }

    expect(player.played, [
      AppSound.starsAwarded.asset,
      AppSound.treatRedeemed.asset,
      AppSound.streakMilestone.asset,
    ]);
  });
}
```

If `starAwardWatcherProvider` needs more overrides to build, copy them from `review_prompt_celebration_test.dart`'s `_containerFor`.

- [ ] **Step 6: Run, expect FAIL** (`played` is empty)

- [ ] **Step 7: Wire the listener.** In `CelebrationListener.build`, add to the `CelebrationOverlayView(...)`:

```dart
              onShow: () => ref
                  .read(soundServiceProvider)
                  .play(AppSound.forCelebration(queue.first.kind)),
```

with imports for `app_sound.dart` and `sound_service.dart`.

- [ ] **Step 8: Run both test files plus `test/presentation/motion/`, expect PASS**

Run: `flutter test test/presentation/motion test/presentation/sound`

- [ ] **Step 9: Commit**

```bash
git add lib/presentation/motion test/presentation/motion test/presentation/sound
git commit -m "feat(sound): play a sound with each celebration"
```

---

### Task 4: Tick when a chore is marked done

**Files:**
- Modify: `lib/presentation/providers/riverpod/task_list_notifier.dart` (`completeTask` success branch, ~line 296)
- Test: `test/presentation/sound/chore_done_sound_test.dart`

**Interfaces:**
- Consumes: `soundServiceProvider`, `soundPlayerProvider`, `AppSound.choreDone`, `FakeSoundPlayer`.

- [ ] **Step 1: Write the failing test** (setup copied from `test/presentation/task_approve_analytics_test.dart`; `MockTaskRepository` seeds `task_2` assigned to `user_2`):

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/sound/app_sound.dart';
import 'package:hoque_family_chores/presentation/sound/sound_service.dart';

import '../../mocks/mock_task_repository.dart';
import 'fake_sound_player.dart';

final _familyId = FamilyId('family_1');

(ProviderContainer, FakeSoundPlayer) _setUp() {
  SharedPreferences.setMockInitialValues({});
  final player = FakeSoundPlayer();
  final container = ProviderContainer(overrides: [
    taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
    analyticsProvider.overrideWith((_) => Analytics(FakeFirebaseFirestore())),
    soundPlayerProvider.overrideWithValue(player),
  ]);
  addTearDown(container.dispose);
  return (container, player);
}

void main() {
  test('a successful mark-done plays the tick once', () async {
    final (container, player) = _setUp();
    await container
        .read(taskListNotifierProvider(_familyId).notifier)
        .completeTask('task_2', UserId('user_2'), _familyId);
    expect(player.played, [AppSound.choreDone.asset]);
  });

  test('a failed mark-done plays nothing', () async {
    final (container, player) = _setUp();
    await expectLater(
      container
          .read(taskListNotifierProvider(_familyId).notifier)
          .completeTask('task_2', UserId('user_9'), _familyId),
      throwsException,
    );
    expect(player.played, isEmpty);
  });
}
```

- [ ] **Step 2: Run, expect FAIL** on the first test (`played` empty)

Run: `flutter test test/presentation/sound/chore_done_sound_test.dart`

- [ ] **Step 3: Implement.** In `completeTask`'s success branch, after the `taskCompleted` analytics log and before `ref.invalidateSelf()`:

```dart
          // Not awaited: the tick must never add latency to marking done.
          ref.read(soundServiceProvider).play(AppSound.choreDone);
```

Add imports for `app_sound.dart` and `sound_service.dart`.

- [ ] **Step 4: Run, expect PASS**

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/providers/riverpod/task_list_notifier.dart test/presentation/sound/chore_done_sound_test.dart
git commit -m "feat(sound): tick when a chore is marked done"
```

---

### Task 5: "Sound effects" toggle on the profile screen, then full verification

**Files:**
- Modify: `lib/presentation/screens/user_profile_screen.dart` (after the Notifications `ListTile`)
- Test: `test/presentation/user_profile_sound_toggle_test.dart`

**Interfaces:**
- Consumes: `soundEnabledProvider`, `SoundEnabled.setEnabled`.

- [ ] **Step 1: Write the failing test.** Reuse `_pumpProfile`'s setup from `test/presentation/user_profile_notifications_badge_test.dart` (seed: none), plus `SharedPreferences.setMockInitialValues({})` first, then:

```dart
  testWidgets('Sound effects switch is on by default and turns sound off',
      (tester) async {
    final container = await _pumpProfile(tester);
    final tile = find.widgetWithText(SwitchListTile, 'Sound effects');
    await tester.scrollUntilVisible(tile, 100);
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);

    await tester.tap(tile);
    await tester.pump();
    expect(container.read(soundEnabledProvider), isFalse);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
  });
```

(`_pumpProfile` returns the container in this file.)

- [ ] **Step 2: Run, expect FAIL** (no such tile)

- [ ] **Step 3: Implement** after the Notifications `ListTile`:

```dart
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: const Text('Sound effects'),
            value: ref.watch(soundEnabledProvider),
            onChanged: (on) =>
                ref.read(soundEnabledProvider.notifier).setEnabled(on),
          ),
```

Import `package:hoque_family_chores/presentation/sound/sound_service.dart`.

- [ ] **Step 4: Run, expect PASS**

- [ ] **Step 5: Full verification**

Run: `flutter analyze` (expect no new issues) and `flutter test` (expect all pass; any test that now reaches the real `AudioplayersSoundPlayer` must be fixed by overriding `soundPlayerProvider` with `FakeSoundPlayer`, never by skipping).

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/screens/user_profile_screen.dart test/presentation/user_profile_sound_toggle_test.dart
git commit -m "feat(sound): add a Sound effects toggle to the profile screen"
```

- [ ] **Step 7: Manual check on the iOS simulator** (see the driving-the-ios-simulator memory): mark a chore done (tick), approve it as the other member (stars sound), toggle off (silence). The silent-switch and mix-with-music behaviour is checked on a real device via TestFlight with the next release candidate.
