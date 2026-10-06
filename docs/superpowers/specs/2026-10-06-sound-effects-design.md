# Sound Effects — Design

**Status:** approved design, not yet implemented
**Date:** 2026-10-06
**Goal:** Give the moments that matter to a child an audible payoff (a tick
when they mark a chore done, a short flourish when stars, treats, or streaks
land) without turning Chores Star into a noisy app or getting in a parent's
way.

## Decisions (with product owner)

- **Sound effects, no background music.** Sessions are short bursts on a
  shared family device; music would be the first thing parents switch off.
- **Four moments, nothing else:**
  - `choreDone`: soft tick when a chore is marked done (status moves to
    `pendingApproval`). No stars are earned yet, so this is deliberately
    small, not a celebration.
  - `starsAwarded`, `treatRedeemed`, `streakMilestone`: one sound per
    existing payoff moment (motion spec §2). The "nothing else may
    celebrate" rule from `lib/presentation/motion/celebration.dart` applies
    to sound as well.
  - No sounds on button presses, tab switches, navigation, or errors.
- **Who hears it: everyone, with a per-device toggle, on by default.** Same
  behaviour for parents and children; anyone can switch it off on their own
  device. Not synced to the user profile.
- **Source: a CC0 pack from Kenney.nl** (e.g. "Interface Sounds" / "Digital
  Audio"). CC0 needs no attribution; the chosen file names and pack are
  recorded in `assets/sounds/README.md` so provenance is traceable.
- **Playback package: `audioplayers`.** Lightweight, handles short bundled
  clips, and exposes the platform audio context. `just_audio` is built for
  streaming and playlists (more than four clips need); `SystemSound` offers
  only a generic click and cannot play custom assets.

## 1. Audio behaviour

- **Ambient audio session.** iOS: `AVAudioSessionCategory.ambient` with mix
  mode, so the ring/silent switch mutes the app and a tick never pauses the
  parent's music or podcast. Android: `AudioAttributes` usage
  `assistanceSonification` / content type `sonification`, no audio focus
  request, so other audio keeps playing.
- **Short and quiet.** Every clip ≤ 1.5 s (tick ≤ 0.3 s), normalised so
  the tick is noticeably softer than the three celebration sounds.
- **One at a time.** Celebrations already queue (one plays at a time), and
  the sound fires from the overlay, so celebration sounds never overlap.
- **Reduced motion does not silence sound.** Reduced motion is about
  movement; the static celebration variant still plays its sound. The sound
  toggle is the only switch for audio.

## 2. Components

New code lives in `lib/presentation/sound/`, beside `motion/`.

- **`AppSound`** (enum): `choreDone`, `starsAwarded`, `treatRedeemed`,
  `streakMilestone`, each mapped to one asset path under `assets/sounds/`.
  A celebration kind maps to its sound in one place (an exhaustive `switch`
  over the sealed `CelebrationKind`), so adding a fourth celebration fails
  to compile until it is given a sound.
- **`SoundPlayer`** (abstract, one method: `Future<void> play(String asset)`):
  the seam for tests. `AudioplayersSoundPlayer` is the production
  implementation; it configures the audio context once when it is created.
- **`SoundService`**: `play(AppSound)`. Reads the toggle; if off, returns
  without touching the player. If on, calls `SoundPlayer.play`. A playback
  exception is logged at error level with the sound name and swallowed:
  a missing sound must never block completing a chore or a celebration.
  This is the one deliberate exception to "fail loudly". The failure is
  still logged, so it stays visible.
- **`soundEnabledProvider`**: Riverpod notifier holding a `bool`, persisted
  with `shared_preferences` (already a dependency) under key
  `sound_effects_enabled`. Missing key means `true`.
- **`soundServiceProvider`**: wires the two together; overridden with a fake
  player in tests.

## 3. Where sounds fire

- **Celebrations:** `CelebrationOverlayView` post-frame callback
  (`lib/presentation/motion/celebration_overlay.dart`), alongside the
  existing `SemanticsService.announce`. It plays **before** the
  reduced-motion branch, so both variants sound. The haptic stays where it is.
  The overlay receives the play callback through the `CelebrationListener`
  that builds it, which keeps the overlay itself free of Riverpod.
- **Chore done:** `TaskListNotifier.completeTask`
  (`lib/presentation/providers/riverpod/task_list_notifier.dart`), in the
  success branch of `result.fold`, next to the `taskCompleted` analytics
  event. It is never played on the failure branch or on tap, so a failed
  write makes no tick. The sound is not awaited (fire-and-forget), so the
  notifier's latency is unchanged.

## 4. Settings toggle

`UserProfileScreen` menu (`lib/presentation/screens/user_profile_screen.dart`):
a `SwitchListTile` titled **"Sound effects"** with `Icons.volume_up`, placed
after "Notifications". It is bound to `soundEnabledProvider`, on by default,
and takes effect immediately.

## 5. Assets

- `assets/sounds/` with four short files (`.m4a`/AAC, or `.ogg` converted
  to AAC, so both iOS and Android decode natively), plus `README.md` naming
  the Kenney pack, its URL, the CC0 licence, and which source file became
  which sound.
- `pubspec.yaml` gets a `flutter: assets:` entry for `assets/sounds/`
  (the section does not exist yet).
- Total added bytes target: < 100 KB.

## 6. Testing

Fake `SoundPlayer` recording the assets it was asked to play.

- `SoundService` plays when the toggle is on, and does nothing when off.
- The toggle defaults to on when the preference is absent, and persists
  `false` after being switched off (`SharedPreferences.setMockInitialValues`).
- A player that throws: `SoundService.play` completes normally and logs.
- Each `CelebrationKind` maps to its `AppSound` (table test over all kinds).
- The overlay plays its sound in both normal and reduced-motion modes.
- `completeTask` success plays `choreDone` once; failure plays nothing.
- The profile screen shows the "Sound effects" switch, and toggling it
  updates the provider.

Real audio output is verified by hand on the iOS simulator and an Android
emulator. The checks: the silent switch mutes the app, background music keeps
playing, and the toggle off means silence.

## Out of scope

- Background music, per-child sound themes, volume slider.
- Sounds on any moment other than the four above.
- Syncing the toggle across devices or to the user profile.
- Sound for notifications (system notification sounds are unchanged).
- Any change to Firestore rules, Cloud Functions, or data models.
