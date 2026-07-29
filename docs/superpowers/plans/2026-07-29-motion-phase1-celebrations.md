# Motion Phase 1 — Celebrations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the three payoff celebrations (stars awarded, treat redeemed, streak milestone) as a one-shot, queued, reduced-motion-safe overlay system, per `docs/superpowers/specs/2026-07-29-motion-ux-design.md`.

**Architecture:** Extend the existing motion vocabulary in `lib/presentation/theme/motion.dart` (snappy tier only). All bouncy motion lives in a new `lib/presentation/motion/` module: a sealed `CelebrationKind`, a Riverpod queue, an overlay widget with a `CustomPainter` star-burst, and two trigger watchers (star-balance delta, streak milestone). A structural test bans overshoot curves everywhere else.

**Tech Stack:** Flutter (no new packages), Riverpod codegen (`@riverpod` + `dart run build_runner build --delete-conflicting-outputs` after adding providers), flutter_test.

**Conventions (read before starting):**
- TDD per @superpowers:test-driven-development — failing test first, always run it, minimal code, re-run.
- Docstrings in reStructuredText. Comments state constraints, not narration.
- `flutter analyze` must be clean and `flutter test` fully green before every commit.
- Branch: `feat/motion-phase1-celebrations` off `main`.

---

### Task 1: Snappy-tier vocabulary + the carve-out guard test

**Files:**
- Modify: `lib/presentation/theme/motion.dart`
- Test: `test/presentation/theme/motion_carveout_test.dart` (create)

- [ ] **Step 1: Write the guard test**

This is a structural rule test (like `test/presentation/theme/token_contrast_test.dart`), not a behavior test — it is EXPECTED to pass immediately (the reviewer verified no banned curve exists in `lib/` today). It exists to fail the moment anyone leaks bouncy easing outside the celebration module.

```dart
// DESIGN.md bans bounce/elastic easing everywhere except the owner-approved
// carve-out: the celebration module (lib/presentation/motion/). This test is
// the carve-out's fence.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('overshoot curves appear only inside lib/presentation/motion/', () {
    final banned = RegExp(r'\b(elasticOut|elasticIn|bounceOut|bounceIn|easeOutBack|easeInBack)\b');
    final offenders = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      if (f.path.startsWith('lib/presentation/motion/')) continue;
      for (final (i, line) in f.readAsLinesSync().indexed) {
        final code = line.split('//').first; // ignore comments
        if (banned.hasMatch(code)) offenders.add('${f.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty,
        reason: 'Bouncy easing is allowed ONLY in lib/presentation/motion/ '
            '(DESIGN.md carve-out). Found: $offenders');
  });
}
```

- [ ] **Step 2: Run it — must pass (guard test, documented exception to fail-first)**

Run: `flutter test test/presentation/theme/motion_carveout_test.dart`
Expected: PASS (1 test)

- [ ] **Step 3: Add the snappy tier to `motion.dart`**

Append below the existing consts (keep `kMotionDuration`/`kMotionCurve` untouched — 21 call sites is a lie, they're used by CelebrationCard and the badge; do not rename):

```dart
/// Snappy tier (spec §1). Everyday actions only — the bouncy tier is defined
/// inside lib/presentation/motion/ and must never appear here (see
/// motion_carveout_test.dart).
const Duration kMotionTapDuration = Duration(milliseconds: 120);
const Duration kMotionEntranceDuration = Duration(milliseconds: 250);

/// Exits are faster than entrances: things leave quickly, arrive gently.
const Duration kMotionExitDuration = Duration(milliseconds: 150);
const Curve kMotionTapCurve = Curves.easeOutCubic;
const Curve kMotionEntranceCurve = Curves.easeOutCubic;
const Curve kMotionExitCurve = Curves.easeInCubic;
```

- [ ] **Step 4: Analyze + full test run**

Run: `flutter analyze && flutter test`
Expected: clean, all green.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/theme/motion.dart test/presentation/theme/motion_carveout_test.dart
git commit -m "feat(motion): snappy-tier vocabulary + structural carve-out guard"
```

---

### Task 2: `CelebrationKind` + queue

**Files:**
- Create: `lib/presentation/motion/celebration.dart`
- Test: `test/presentation/motion/celebration_queue_test.dart` (create)

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';

void main() {
  test('celebrations queue in order and advance one at a time', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final queue = container.read(celebrationQueueProvider.notifier);

    queue.celebrate(const StarsAwarded(10));
    queue.celebrate(const StreakMilestone(7));

    List<CelebrationKind> kinds() =>
        container.read(celebrationQueueProvider).map((q) => q.kind).toList();

    expect(kinds(), const [StarsAwarded(10), StreakMilestone(7)]);

    queue.advance();
    expect(kinds(), const [StreakMilestone(7)]);
    queue.advance();
    expect(kinds(), isEmpty);
    queue.advance(); // advancing an empty queue is a no-op, not a crash
    expect(kinds(), isEmpty);
  });

  test('each entry gets a unique sequence number, even for equal kinds', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final queue = container.read(celebrationQueueProvider.notifier);

    queue.celebrate(const StarsAwarded(10));
    queue.celebrate(const StarsAwarded(10)); // identical payoff twice
    final entries = container.read(celebrationQueueProvider);
    expect(entries[0].seq, isNot(entries[1].seq),
        reason: 'the overlay keys off seq — equal kinds must still be '
            'distinct entries or the second show never restarts');
  });

  test('kinds carry their payloads and compare by value', () {
    expect(const StarsAwarded(5), const StarsAwarded(5));
    expect(const TreatRedeemed('Movie night'), const TreatRedeemed('Movie night'));
    expect(const StreakMilestone(3), isNot(const StreakMilestone(7)));
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/presentation/motion/celebration_queue_test.dart`
Expected: FAIL — `celebration.dart` doesn't exist.

- [ ] **Step 3: Implement**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'celebration.g.dart';

/// The three payoff moments (spec §2). Nothing else may celebrate.
sealed class CelebrationKind {
  const CelebrationKind();
}

class StarsAwarded extends CelebrationKind {
  const StarsAwarded(this.count);
  final int count;
  @override
  bool operator ==(Object other) => other is StarsAwarded && other.count == count;
  @override
  int get hashCode => Object.hash(runtimeType, count);
}

class TreatRedeemed extends CelebrationKind {
  const TreatRedeemed(this.treatName);
  final String treatName;
  @override
  bool operator ==(Object other) =>
      other is TreatRedeemed && other.treatName == treatName;
  @override
  int get hashCode => Object.hash(runtimeType, treatName);
}

class StreakMilestone extends CelebrationKind {
  const StreakMilestone(this.days);
  final int days;
  @override
  bool operator ==(Object other) => other is StreakMilestone && other.days == days;
  @override
  int get hashCode => Object.hash(runtimeType, days);
}

/// A queued celebration. The sequence number exists for the overlay's widget
/// key: two identical payoffs (e.g. +10 twice) must still restart the show.
class QueuedCelebration {
  const QueuedCelebration(this.seq, this.kind);
  final int seq;
  final CelebrationKind kind;
}

/// FIFO of pending celebrations. One plays at a time ("one celebration moment
/// per screen", DESIGN.md); the listener advances it when the overlay ends.
@Riverpod(keepAlive: true)
class CelebrationQueue extends _$CelebrationQueue {
  int _nextSeq = 0;

  @override
  List<QueuedCelebration> build() => const [];

  void celebrate(CelebrationKind kind) =>
      state = [...state, QueuedCelebration(_nextSeq++, kind)];

  void advance() {
    if (state.isEmpty) return;
    state = state.sublist(1);
  }
}
```

- [ ] **Step 4: Generate providers, run tests**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/presentation/motion/celebration_queue_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/motion/ test/presentation/motion/celebration_queue_test.dart
git commit -m "feat(motion): CelebrationKind + one-at-a-time queue"
```

---

### Task 3: Star-burst painter

**Files:**
- Create: `lib/presentation/motion/star_burst_painter.dart`
- Test: `test/presentation/motion/star_burst_painter_test.dart` (create)

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/motion/star_burst_painter.dart';

void main() {
  testWidgets('paints at every phase of the burst without error', (tester) async {
    for (final progress in [0.0, 0.3, 0.7, 1.0]) {
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(300, 300),
          painter: StarBurstPainter(
            progress: progress,
            colors: const [Color(0xFFFFB300), Color(0xFF4CAF50), Color(0xFFC6412A)],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });

  test('repaints only when progress changes', () {
    const colors = [Color(0xFFFFB300)];
    final a = StarBurstPainter(progress: 0.2, colors: colors);
    final b = StarBurstPainter(progress: 0.2, colors: colors);
    final c = StarBurstPainter(progress: 0.4, colors: colors);
    expect(a.shouldRepaint(b), isFalse);
    expect(a.shouldRepaint(c), isTrue);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/presentation/motion/star_burst_painter_test.dart`
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Implement**

Twelve particles, deterministic layout (fixed seed — no `Random()` without seed, keeps tests and frames stable). The overshoot lives HERE, inside the module, as the carve-out requires. Scale/fade only — no flashing (spec §4).

```dart
import 'dart:math';
import 'package:flutter/material.dart';

/// The single owner-approved overshoot (DESIGN.md carve-out): one-shot,
/// bounded, never perpetual. Lives only in lib/presentation/motion/.
const Curve kCelebrationOvershoot = Curves.easeOutBack;

class StarBurstPainter extends CustomPainter {
  StarBurstPainter({required this.progress, required this.colors});

  /// 0 → 1 over the burst envelope.
  final double progress;
  final List<Color> colors;

  static const int _count = 12;
  static final List<double> _jitter = List.unmodifiable(
    List.generate(_count, (i) => Random(7 * i + 3).nextDouble()),
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.38;
    final travel = kCelebrationOvershoot.transform(progress.clamp(0.0, 1.0));
    final fade = (1.0 - progress).clamp(0.0, 1.0);

    for (var i = 0; i < _count; i++) {
      final angle = (2 * pi * i / _count) + _jitter[i] * 0.4;
      final distance = radius * travel * (0.7 + 0.3 * _jitter[i]);
      // Gravity: particles sag as the burst ends.
      final gravity = 18.0 * progress * progress;
      final pos = center +
          Offset(cos(angle) * distance, sin(angle) * distance + gravity);
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: fade);
      final side = 7.0 * (0.6 + 0.4 * _jitter[i]) * (1.0 - 0.3 * progress);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: pos, width: side, height: side),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarBurstPainter old) =>
      old.progress != progress || old.colors != colors;
}
```

(If `withValues` is unavailable on this Flutter version, use `withOpacity(fade)` — check how the codebase does alpha and match it.)

- [ ] **Step 4: Run tests, analyze**

Run: `flutter test test/presentation/motion/star_burst_painter_test.dart && flutter analyze`
Expected: PASS, clean. The carve-out guard test still passes (`easeOutBack` is inside `lib/presentation/motion/`).

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/motion/star_burst_painter.dart test/presentation/motion/star_burst_painter_test.dart
git commit -m "feat(motion): one-shot star-burst painter with module-private overshoot"
```

---

### Task 4: Celebration overlay widget

**Files:**
- Create: `lib/presentation/motion/celebration_overlay.dart`
- Test: `test/presentation/motion/celebration_overlay_test.dart` (create)

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/celebration_overlay.dart';
import 'package:hoque_family_chores/presentation/motion/star_burst_painter.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

Future<void> _pump(WidgetTester tester, CelebrationKind kind,
    {bool reducedMotion = false, VoidCallback? onDone}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: appLightTheme,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: Scaffold(
          body: CelebrationOverlayView(kind: kind, onDone: onDone ?? () {}),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('stars awarded shows +N and finishes', (tester) async {
    var done = false;
    await _pump(tester, const StarsAwarded(10), onDone: () => done = true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('+10'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(done, isTrue, reason: 'the overlay must end and report completion');
  });

  testWidgets('treat redeemed shows the treat name, no +N', (tester) async {
    await _pump(tester, const TreatRedeemed('Movie night'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Movie night'), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  });

  testWidgets('streak milestone shows the day count', (tester) async {
    await _pump(tester, const StreakMilestone(7));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('7-day streak'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  });

  testWidgets('reduced motion: information without the burst', (tester) async {
    var done = false;
    await _pump(tester, const StarsAwarded(5),
        reducedMotion: true, onDone: () => done = true);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('+5'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is StarBurstPainter),
      findsNothing,
      reason: 'reduced motion renders the static variant — no burst painter',
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(done, isTrue);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/presentation/motion/celebration_overlay_test.dart`
Expected: FAIL — `CelebrationOverlayView` doesn't exist.

- [ ] **Step 3: Implement**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/star_burst_painter.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/theme/motion.dart';

/// Plays one celebration (spec §2): star-burst + headline + one haptic, then
/// calls [onDone]. One-shot by construction — the controller never repeats.
class CelebrationOverlayView extends StatefulWidget {
  const CelebrationOverlayView({super.key, required this.kind, required this.onDone});

  final CelebrationKind kind;
  final VoidCallback onDone;

  @override
  State<CelebrationOverlayView> createState() => _CelebrationOverlayViewState();
}

class _CelebrationOverlayViewState extends State<CelebrationOverlayView>
    with SingleTickerProviderStateMixin {
  static const _envelope = Duration(milliseconds: 700);
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _envelope);

  String get _headline => switch (widget.kind) {
        StarsAwarded(:final count) => '+$count ⭐',
        TreatRedeemed(:final treatName) => '$treatName 🎉',
        StreakMilestone(:final days) => '$days-day streak! 🔥',
      };

  String get _announcement => switch (widget.kind) {
        StarsAwarded(:final count) => 'You earned $count stars!',
        TreatRedeemed(:final treatName) => 'You got $treatName!',
        StreakMilestone(:final days) => '$days day streak!',
      };

  @override
  void initState() {
    super.initState();
    // Post-frame: prefersReducedMotion needs MediaQuery, unavailable in initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.announce(_announcement, TextDirection.ltr);
      if (context.prefersReducedMotion) {
        // Static variant: the information, a beat to read it, no movement.
        Future<void>.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) widget.onDone();
        });
      } else {
        HapticFeedback.mediumImpact();
        _controller.forward().whenComplete(widget.onDone);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = context.prefersReducedMotion;
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!.copyWith(
          color: context.tokens.ink,
          fontWeight: FontWeight.bold,
        );

    if (reduced) {
      return IgnorePointer(
        child: Center(child: Text(_headline, style: headlineStyle)),
      );
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final pop = kCelebrationOvershoot
              .transform(Interval(0.0, 0.55).transform(t));
          final fadeOut = t < 0.8 ? 1.0 : 1.0 - (t - 0.8) / 0.2;
          return Opacity(
            opacity: fadeOut.clamp(0.0, 1.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(320, 320),
                  painter: StarBurstPainter(
                    progress: t,
                    colors: [
                      context.tokens.starGold,
                      context.tokens.sprout,
                      context.tokens.brick,
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.6 + 0.4 * pop,
                  child: Text(_headline, style: headlineStyle),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

NB: check the exact token getter names in `app_tokens.dart` (`starGold`, `sprout`, `brick` — adjust to what exists; the Fill Rule table in DESIGN.md §5 lists them). If `brick` isn't a token, use `brickDeep`.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/presentation/motion/celebration_overlay_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Full analyze + test, commit**

```bash
flutter analyze && flutter test
git add lib/presentation/motion/celebration_overlay.dart test/presentation/motion/celebration_overlay_test.dart
git commit -m "feat(motion): celebration overlay — burst, headline, haptic, reduced-motion variant"
```

---

### Task 5: Celebration listener (queue → overlay, one at a time)

**Files:**
- Create: `lib/presentation/motion/celebration_listener.dart`
- Modify: `lib/presentation/screens/main_screen.dart:34` (wrap the `IndexedStack`)
- Test: `test/presentation/motion/celebration_listener_test.dart` (create)

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/celebration_listener.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';

void main() {
  testWidgets('two queued celebrations play sequentially, never stacked',
      (tester) async {
    // The auth repository is mocked because Task 7 activates the star-award
    // watcher inside CelebrationListener — without this override the real
    // AuthNotifier.build would touch FirebaseAuth and crash the test.
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: appLightTheme,
          home: const Scaffold(
            body: CelebrationListener(child: SizedBox.expand()),
          ),
        ),
      ),
    );

    container.read(celebrationQueueProvider.notifier)
      ..celebrate(const StarsAwarded(10))
      ..celebrate(const StreakMilestone(3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // First plays alone.
    expect(find.textContaining('+10'), findsOneWidget);
    expect(find.textContaining('streak'), findsNothing);

    // After the first envelope, the second plays.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('+10'), findsNothing);
    expect(find.textContaining('3-day streak'), findsOneWidget);

    // Then silence.
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.textContaining('streak'), findsNothing);
    expect(container.read(celebrationQueueProvider), isEmpty);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/presentation/motion/celebration_listener_test.dart`
Expected: FAIL — `CelebrationListener` doesn't exist.

- [ ] **Step 3: Implement**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/celebration_overlay.dart';

/// Bridges the celebration queue to the screen: plays the queue's head as an
/// overlay above [child], advancing when each one finishes. Mounted once,
/// above the tab stack in MainScreen.
class CelebrationListener extends ConsumerWidget {
  const CelebrationListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(celebrationQueueProvider);
    return Stack(
      children: [
        child,
        if (queue.isNotEmpty)
          Positioned.fill(
            child: CelebrationOverlayView(
              // Keyed by the enqueue sequence number: a NEW head (even an
              // identical kind) restarts the show; a mid-show enqueue does
              // not (the head's seq is unchanged).
              key: ValueKey(queue.first.seq),
              kind: queue.first.kind,
              onDone: () =>
                  ref.read(celebrationQueueProvider.notifier).advance(),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test, then wire into MainScreen**

Run: `flutter test test/presentation/motion/celebration_listener_test.dart` → PASS.

In `main_screen.dart`, wrap the body:

```dart
body: CelebrationListener(
  child: IndexedStack(index: currentIndex, children: _screens),
),
```

(add the import `package:hoque_family_chores/presentation/motion/celebration_listener.dart`).

- [ ] **Step 5: Full suite, commit**

```bash
flutter analyze && flutter test
git add lib/presentation/motion/celebration_listener.dart test/presentation/motion/celebration_listener_test.dart lib/presentation/screens/main_screen.dart
git commit -m "feat(motion): celebration listener above the tab stack"
```

---

### Task 6: Trigger — treat redeemed (local)

**Files:**
- Modify: `lib/presentation/screens/rewards_screen.dart:383-397` (the success fold of `_claim`)
- Test: create `test/presentation/rewards_claim_celebration_test.dart` (no rewards-screen test currently exists — verified) following the style of `test/presentation/tasks_tab_test.dart` (mock repositories, real providers).

- [ ] **Step 1: Write the failing test** — claim a reward through the real notifier/use-case with mock repos, assert `celebrationQueueProvider` ends with `[TreatRedeemed('<title>')]`.

- [ ] **Step 2: Run to verify failure.**

- [ ] **Step 3: Implement** — in the success fold of `_claim` (after the `analytics.log` call), replace the success `SnackBar` with:

```dart
ref.read(celebrationQueueProvider.notifier)
    .celebrate(TreatRedeemed(reward.title));
```

The celebration replaces the "You got it!" snackbar — two simultaneous notices would break "one celebration moment per screen." Keep the FAILURE snackbar untouched.

- [ ] **Step 4: Run the test → PASS. Full suite + analyze.**

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(motion): celebrate treat redemption (replaces success snackbar)"
```

---

### Task 7: Trigger — stars awarded (stream-driven, baseline on cold start)

**Files:**
- Create: `lib/presentation/motion/star_award_watcher.dart`
- Test: `test/presentation/motion/star_award_watcher_test.dart` (create)

- [ ] **Step 1: Write the failing tests**

Test through a `ProviderContainer` with `authNotifierProvider` overridden to a controllable fake (see `test/presentation/auth_notifier_child_join_test.dart` for the mock-repo pattern; here it's simpler to override the provider itself with a `Notifier` stub you can mutate):

1. First user emission (points=50) → queue stays EMPTY (cold-start baseline, spec §2).
2. Points 50 → 60 → queue gets `StarsAwarded(10)`.
3. Points 60 → 45 (spend) → queue unchanged (decreases never celebrate).
4. User id changes (sign-out/in) → baseline resets; the new user's first emission celebrates nothing.
5. Same state emitted twice (rebuild) → no duplicate celebration.
6. The real-world claim sequence: points 60 → (treat claimed, `authNotifierProvider` re-emits) 45 → 45 again → nothing celebrates from the watcher (the treat celebration comes from Task 6's local trigger, not from here).

- [ ] **Step 2: Run to verify failure.**

- [ ] **Step 3: Implement**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';

part 'star_award_watcher.g.dart';

/// Watches the signed-in user's star balance and celebrates increases.
///
/// Cold start sets a baseline (spec §2): the first emission for a user records
/// state and celebrates nothing, so history never replays at launch. Only
/// deltas observed after the baseline celebrate. Decreases (spending) are the
/// treat flow's job, not ours.
@Riverpod(keepAlive: true)
class StarAwardWatcher extends _$StarAwardWatcher {
  String? _userId;
  int? _points;

  @override
  void build() {
    ref.listen(authNotifierProvider, (_, next) {
      final user = next.user;
      if (user == null) {
        _userId = null;
        _points = null;
        return;
      }
      final sameUser = user.id.value == _userId;
      final previous = _points;
      _userId = user.id.value;
      _points = user.points.value;
      if (!sameUser || previous == null) return; // baseline, no celebration
      final delta = user.points.value - previous;
      if (delta > 0) {
        ref
            .read(celebrationQueueProvider.notifier)
            .celebrate(StarsAwarded(delta));
      }
    });
  }
}
```

Activate it in `CelebrationListener.build` (one line, keeps all wiring in the module): `ref.watch(starAwardWatcherProvider);`

This is safe for Task 5's listener test because that test already overrides `authRepositoryProvider` with `MockAuthRepository` (the override was put there for exactly this moment — without it, the real `AuthNotifier.build` would touch FirebaseAuth and crash). Verify Task 5's test still passes after activation.

- [ ] **Step 4: Codegen + tests**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/presentation/motion/`
Expected: PASS.

- [ ] **Step 5: Full suite, commit**

```bash
git commit -am "feat(motion): stream-driven stars-awarded celebration with cold-start baseline"
```

---

### Task 8: Trigger — streak milestone

**Files:**
- Create: `lib/presentation/motion/streak_milestone_watcher.dart`
- Modify: `lib/presentation/screens/home_screen.dart:179` (report the computed streak)
- Test: `test/presentation/motion/streak_milestone_watcher_test.dart` (create)

- [ ] **Step 1: Write the failing tests**

Milestones: `{3, 7, 14, 30, 50, 100}`.

1. First report (streak=7) → nothing (baseline).
2. 2 → 3 → `StreakMilestone(3)`.
3. 3 → 4 → nothing (not a milestone).
4. 6 → 7 → 7 reported again (home rebuild) → exactly one `StreakMilestone(7)`.
5. 7 → 0 (streak broken) → nothing, and a later 0 → 3 celebrates again.
6. **Deferral (crash guard):** a widget test that calls `report()` from inside a `build` method (a minimal `Consumer` whose builder reports a milestone crossing) and pumps a microtask — no "modify provider during build" exception, and the celebration lands in the queue afterwards. This is the case the pure-container tests can't catch.

Because `report()` is called from `HomeScreen.build`, it must NEVER mutate `celebrationQueueProvider` synchronously — flutter_riverpod throws "Tried to modify a provider while the widget tree was building." The implementation defers.

- [ ] **Step 2: Run to verify failure.**

- [ ] **Step 3: Implement**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';

part 'streak_milestone_watcher.g.dart';

const Set<int> kStreakMilestones = {3, 7, 14, 30, 50, 100};

/// Session-scoped streak milestone detector. Home reports the live streak
/// (it already computes it from the task stream); crossing INTO a milestone
/// during the session celebrates once. The first report is the baseline
/// (spec §2) — launching the app on day 7 must not celebrate day 7.
@Riverpod(keepAlive: true)
class StreakMilestoneWatcher extends _$StreakMilestoneWatcher {
  int? _last;

  @override
  void build() {}

  void report(int streakDays) {
    final previous = _last;
    _last = streakDays;
    if (previous == null) return; // baseline
    if (streakDays > previous && kStreakMilestones.contains(streakDays)) {
      // Deferred: report() is called from HomeScreen.build, and mutating a
      // provider during build throws. A microtask lands after this frame's
      // build phase.
      Future.microtask(() => ref
          .read(celebrationQueueProvider.notifier)
          .celebrate(StreakMilestone(streakDays)));
    }
  }
}
```

In `home_screen.dart`, right after `final streak = streakDays(tasks, currentUser.id, now);`:

```dart
ref.read(streakMilestoneWatcherProvider.notifier).report(streak);
```

(`build` in home is already reactive to the task stream, so approvals landing while the app is open re-run this line with the new streak.)

- [ ] **Step 4: Codegen + tests + full suite.**

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(motion): streak milestone celebrations, session-baselined"
```

---

### Task 9: `CelebrationCard` adopts the vocabulary + amend DESIGN.md

**Files:**
- Modify: `lib/presentation/widgets/home/celebration_card.dart`
- Modify: `DESIGN.md` (motion don'ts, ~line 505, and §"Motion" ~line 451)

- [ ] **Step 0: CelebrationCard adoption (spec Phase 1 requirement).** The card already uses `kMotionCurve` and the reduced-motion gate, but hardcodes a 600ms entrance duration outside any named tier. Replace the hardcoded `Duration(milliseconds: 600)` with `kMotionEntranceDuration` so the card speaks the vocabulary. Run its existing test: `flutter test test/presentation/celebration_card_test.dart` → PASS (adjust any hardcoded 600ms expectation in the test to the token).

- [ ] **Step 1: Amend the bounce-ban don't** to read:

```markdown
- **Don't** use bounce or elastic easing (`Curves.elasticOut`,
  `Curves.bounceOut`) in everyday motion. ONE exception, owner-approved
  (2026-07-29): the three payoff celebrations (stars awarded, treat
  redeemed, streak milestone) may use a single bounded overshoot
  (`easeOutBack`), one-shot per event, ≤700ms, never perpetual, always
  reduced-motion gated, and defined only inside `lib/presentation/motion/`
  (enforced by `motion_carveout_test.dart`). "One celebration moment per
  screen" still applies — celebrations queue, never stack.
```

- [ ] **Step 2: Extend the Motion note (~line 451)** to mention the snappy tier consts and point to the spec: `docs/superpowers/specs/2026-07-29-motion-ux-design.md`.

- [ ] **Step 3: Commit**

```bash
git add DESIGN.md
git commit -m "docs: DESIGN.md motion carve-out for payoff celebrations"
```

---

### Task 10: Finish line

- [ ] **Step 1:** `flutter analyze && flutter test` — clean and fully green.
- [ ] **Step 2:** Run the app on the iOS 18.5 simulator (NOT iOS 26 — debug builds DartInit-crash there, see memory) and eyeball one celebration end-to-end: claim a treat in the demo family.
- [ ] **Step 3:** Use @superpowers:finishing-a-development-branch — push branch, PR to main, squash-merge per repo convention.
