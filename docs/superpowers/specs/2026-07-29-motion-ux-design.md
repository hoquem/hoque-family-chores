# Motion & Animation — Design

**Status:** approved, not started
**Date:** 2026-07-29
**Goal:** Give Chores Star a deliberate motion language — quiet, snappy
feedback for everyday actions and a real celebration when stars pay off —
without new dependencies and without breaking the Fridge Door design system's
calm-gamification stance.

## Decisions (with product owner)

- **Scope: both tiers, phased.** Define the full motion language now; ship
  the celebration moments first, then roll the everyday tier out screen by
  screen.
- **Pure Flutter code.** No Lottie, no Rive, no new packages, no asset bytes.
  Physics curves, custom painters, implicit/explicit animations only.
- **Personality: hybrid.** *Snappy & crisp* is the default for every everyday
  action; *bouncy & playful* is reserved exclusively for star payoffs. The
  everyday tier staying quiet is what makes the payoffs land.
- **The three payoff moments:** stars awarded (approval lands), treat
  redeemed, streak milestone. Level-ups and the weekly leaderboard stay in
  the snappy tier.
- **DESIGN.md carve-out (owner-approved).** DESIGN.md bans bounce/elastic
  easing and mandates "one celebration moment per screen." The ban stands for
  all everyday motion; the three payoff moments get a documented exception:
  a single bounded overshoot (`easeOutBack`-family), one-shot per event,
  ≤700ms, never perpetual, always reduced-motion gated. "One celebration
  moment per screen" remains law (celebrations queue, never stack).
  DESIGN.md's motion section is amended as part of phase 1.

## 1. Motion vocabulary (`lib/presentation/theme/motion.dart`)

Extend the existing file — do NOT create a parallel token system. It already
holds `kMotionDuration` (220ms), `kMotionCurve` (`easeOutQuart`) and the
`context.prefersReducedMotion` gate (OS reduce-motion **or** screen-reader
navigation). Motion does not vary by light/dark theme, so plain consts +
the BuildContext extension stay the right shape (no `ThemeExtension`).

Two named tiers:

**Snappy (everyday — the default):**

| Name | Duration | Curve | Use |
|---|---|---|---|
| `tap` | 120ms | easeOutCubic | press feedback, toggles |
| `state` | 220ms (existing `kMotionDuration`) | easeOutQuart (existing) | status pills, action-row swaps |
| `entrance` | 250ms | easeOutCubic + slight upward slide | tiles/cards appearing |
| `exit` | 150ms | easeInCubic | anything leaving |

Exits are always faster than entrances: things leave quickly, arrive gently.

**Bouncy (payoffs only):**

| Name | Duration | Curve | Use |
|---|---|---|---|
| `spring` | ~500ms | easeOutBack | star scale-ups, treat card pop |
| `celebrate` | ~700ms envelope | composed | full celebration sequence |

**Enforcement:** the bouncy values are private to the celebration module
(§2) — not exported from `motion.dart`'s public surface. Ordinary widgets
can only reach the snappy tier. A structural test (§5) backs this up.

**Reduced motion, decided once:** every animation passes through
`context.prefersReducedMotion`. When true, snappy durations collapse to zero
and celebrations render their static variant. The information is never
motion-only: stars still appear, states still change.

## 2. Celebration system (`lib/presentation/motion/celebration.dart`)

One module owning everything bouncy. Public API:

```dart
celebrate(context, CelebrationKind kind);
// kinds: starsAwarded(count) | treatRedeemed | streakMilestone(days)
```

**What plays:** an `OverlayEntry` above the current screen —

- a one-shot star-burst: 10–14 particles (star-gold, sprout, coral tokens)
  radiating with a single `easeOutBack` overshoot then gravity-fade, ~650ms,
  drawn by one `CustomPainter` on one ticker inside a `RepaintBoundary`
  (painted shapes, not widgets — one canvas pass, underlying screen never
  rebuilds);
- a "+N ⭐" counter that rolls up;
- one medium haptic (`HapticFeedback.mediumImpact`).

**Reduced-motion variant:** the "+N ⭐" fades in; no burst painter in the
tree at all.

**Queueing:** celebrations never overlap. Two events arriving together
(approve + streak) play sequentially — "one celebration moment per screen."
Nothing loops; every animation is one-shot and disposed.

**Who sees what (the important subtlety):** stars are usually awarded on
*someone else's* device. Triggers therefore come from two sources:

- **Local:** you redeem a treat → immediate celebration on your device.
- **Stream-driven:** a task you did flips to `completed`, or your star
  balance rises → *your* device celebrates when the event arrives. Dedupe by
  event (task id / balance transition), not by state, so rebuilds never
  re-fire it.

The approver gets a snappy confirmation only — it is not their payoff.

## 3. Phased rollout (each phase a separate shippable branch/PR)

**Phase 1 — payoffs first:** motion.dart tiers; celebration module; wire the
three triggers (stars awarded = stream-driven for the doer; treat redeemed =
local; streak milestone = computed on home load); amend DESIGN.md with the
carve-out. The existing home `CelebrationCard` adopts the new vocabulary so
the app has one celebration language, not two.

**Phase 2 — everyday snappy tier**, small reusable primitives:

- **Press feedback:** ~4% scale-down on tap (120ms) for tiles and primary
  buttons — highest-value micro-interaction in the app.
- **Status changes:** `StatusPill` cross-fades/slides between states; the
  tile action row animates its swap instead of popping.
- **List entrances:** short stagger (250ms, slight upward slide) on first
  load only; reorders animate rather than jump.
- **Star balances:** shared `AnimatedStarCount` — counts roll rather than
  teleport (snappy tier; the bouncy roll exists only inside celebrations).
- **Badge repair:** the pending-approval badge's perpetual pulse (a
  documented DESIGN.md violation) becomes a one-shot attention draw when the
  count *increases*, then rests.

**Phase 3 — explicitly deferred (YAGNI until the pilot asks):** hero
transition tile → details; animated bottom-nav tab transitions.

## 4. Accessibility & performance

- `context.prefersReducedMotion` gates everything; gate the animation, never
  the information (PRODUCT.md requirement).
- Celebrations announce via `SemanticsService.announce` ("You earned 10
  stars!") so VoiceOver users get the payoff too.
- No flashing: particles scale/fade, never blink or strobe —
  photosensitivity-safe by construction.
- Motion never carries meaning alone; it decorates a state change already
  shown as icon + label (existing DESIGN.md rule).
- Nothing animates offscreen; all controllers one-shot and disposed; list
  entrance runs once (has-entered flag), so scrolling stays cold.
- Zero new dependencies; zero bundle-size cost.

## 5. Testing

- **Celebration behavior:** pump through the envelope — overlay appears,
  "+N ⭐" shown, gone after ~700ms, controllers disposed. Queue test: two
  celebrations fired together play sequentially, never stacked.
- **Reduced motion:** same tests under `disableAnimations: true` — static
  variant renders, no burst painter in the tree.
- **Doer's payoff:** notifier test — profile stream emits a star increase /
  my task flips to completed → exactly one celebration request; unrelated
  rebuilds emit none.
- **Everyday tier:** press-feedback (pointer down → scale transform; up →
  restored), star-counter (pump halfway → intermediate value),
  entrance-runs-once (rebuild → no second stagger).
- **Carve-out enforced mechanically:** a structural test scans `lib/` and
  fails if `elasticOut`, `bounceOut`, or `easeOutBack` appears outside
  `lib/presentation/motion/` — same spirit as `token_contrast_test.dart`.
- No golden tests: animation goldens are flaky; the behavior assertions
  above cover what matters.

## Out of scope

- Lottie/Rive or any asset-based animation.
- Page-route/hero transitions and nav animation (phase 3, deferred).
- Sound effects.
- Any change to Firestore rules, Cloud Functions, or data models — this is
  presentation-layer only.
