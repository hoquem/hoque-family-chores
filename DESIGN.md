---
name: Chores Star
description: The Fridge Door — a warm, chunky, kid-first family chores app.
colors:
  marigold: "#E08A1E"
  marigold-deep: "#B86A12"
  star-gold: "#FFB300"
  coral: "#FF6B5C"
  sprout: "#4CAF50"
  sprout-deep: "#2E7D32"
  amber-warn: "#F59E0B"
  amber-warn-deep: "#935F06"
  carrot: "#FB8C00"
  carrot-deep: "#9E5600"
  brick: "#C6412A"
  brick-deep: "#9E3022"
  cream-bg: "#FBF7F0"
  surface: "#FCF9F4"
  ink: "#241D14"
  ink-soft: "#5C5346"
  ink-muted: "#8A8067"
  line: "#E8E0D2"
  warm-charcoal: "#1E1812"
  warm-charcoal-surface: "#2A2218"
typography:
  display:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", system-ui, sans-serif"
    fontSize: "32px"
    fontWeight: 700
    lineHeight: 1.2
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", system-ui, sans-serif"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.25
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", system-ui, sans-serif"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.45
  body-small:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.4
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "0.02em"
rounded:
  sm: "8px"
  md: "12px"
  lg: "16px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  xxl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.marigold}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: "16px 24px"
    typography: "{typography.label}"
    height: "48px"
  button-primary-pressed:
    backgroundColor: "{colors.marigold-deep}"
    textColor: "{colors.ink}"
  button-tonal:
    backgroundColor: "{colors.star-gold}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: "16px 24px"
    height: "48px"
  button-outlined-danger:
    backgroundColor: "transparent"
    textColor: "{colors.brick}"
    rounded: "{rounded.lg}"
    padding: "16px 24px"
    height: "48px"
  card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
  status-pill:
    backgroundColor: "12% tint of the status color"
    textColor: "{colors.ink}"
    iconColor: "the status color's -deep variant"
    rounded: "{rounded.pill}"
    padding: "4px 10px"
    typography: "{typography.label}"
  input:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "16px"
  nav-item-active:
    textColor: "{colors.marigold-deep}"
  nav-item-inactive:
    textColor: "{colors.ink-muted}"
---

# Design System: Hoque Family Chores

## 1. Overview

**Creative North Star: "The Fridge Door"**

This is the family star chart on the fridge door, modernized. Kids' progress
lives front and center — today's missions, streak, level, the weekly
leaderboard — and parents manage quietly behind it (the approval queue,
family setup). The fridge door is warm, homey, and a little proud; it is the
first thing a kid checks in the morning and the thing a parent glances at to
see what still needs a stamp. Progress is shown as *forward motion* (a level
bar filling, a streak line growing), never as a deficit. Celebration is
earned by real completion, not manufactured by noise.

The system is **chunky and warm**: big rounded corners, generous padding,
large tap targets, bold labels, warm-tinted neutrals. It is legible to a
6-year-old still learning to read and trustworthy to a parent handing over the
phone. Density is low on kid surfaces (one clear mission row, one
celebration at a time) and tuned up just enough on parent surfaces (the
approval queue) to clear in seconds — but never to SaaS-density.

This system explicitly rejects (pulled from PRODUCT.md): **the default
Flutter / Material 3 template** (purple-from-seed + grey card stack that
reads as a tutorial), **the babyish toddler toy app** (Comic-Sans-adjacent,
patronizing to older kids and teens), **the corporate SaaS dashboard**
(dense data tables, navy/grey, hero-metric cards), and **cluttered
gamification** (confetti, popups, and animations competing for attention).

**Key Characteristics:**

- Warm, sunlit palette (amber/marigold primary, star-gold reward, coral
  celebration) on warm-tinted neutrals — never pure white, never pure black,
  never default purple.
- Chunky shapes: 16px corners on cards and buttons, 12px on inputs, full
  pills on status. Min 48px tap targets throughout.
- One celebration moment per screen. Motion conveys state (progress,
  completion), never decoration.
- Status is always icon + label, never color alone — a kid who can't decode
  hue still reads state.
- Flat by default; depth is warm tonal layering, not heavy shadows.

## 2. Colors: The Fridge Door Palette

A warm, sunlit palette built on a marigold primary and a star-gold reward
color (already the app's ⭐ currency), with warm-tinted neutrals and a small
functional status set that is *always* reinforced by icon + label.

### Primary

- **Marigold** (#E08A1E): the brand primary. Selected nav item, primary
  buttons (filled), progress-bar fill, current-selection highlight. Warm
  and confident without being neon or babyish. On marigold, use **Ink**
  (#241D14) text for AA contrast (marigold is light; dark text, not white).
- **Toasted Marigold** (#B86A12): pressed/hover state of the primary, and the
  variant used when white text is required (AA on white). Deeper and warmer.

### Secondary

- **Star Gold** (#FFB300): the reward currency — points, stars, streaks, the
  FAB, reward badges. Carryover from the existing app; it is the ⭐ color.
  On star-gold always use **Ink** text (star-gold + white fails contrast).
- **Coral** (#FF6B5C): celebration accent only — the "all done" moment, a
  rare high-five. Large/decorative use; never for body text or small UI.

### Neutral

- **Cream** (#FBF7F0): the app background. Warm off-white, tinted toward
  marigold. Replaces pure white surfaces.
- **Surface** (#FCF9F4): card and elevated-container background, a hair
  warmer/lighter than the page.
- **Ink** (#241D14): primary text and on-marigold text. Warm near-black,
  never pure #000.
- **Ink Soft** (#5C5346): secondary text, captions, metadata. AA on cream
  (~6.5:1).
- **Ink Muted** (#8A8067): hints, placeholders, disabled. AA for large text
  only (~3.3:1) — pair with an icon or use for non-essential copy.
- **Line** (#E8E0D2): warm hairline borders and dividers.

### Functional Status (always icon + label, never color alone)

Status color conveys *aliveness*, not identity — the icon and the word carry
identity. An unclaimed task is **neutral** (it hasn't started); the moment it
is assigned it becomes **warm**. This is the Status-Never-Alone Rule made
concrete, and it closes the 5-state mapping the current code fudges.

| Task state | Color | Icon | Label |
|---|---|---|---|
| Available (ready to claim) | Ink-Soft neutral — *no saturated hue* | ○ `circle_outlined` | "Available" |
| Assigned / in-progress | Carrot (#FB8C00) | ▶ `play_circle` | "In progress" |
| Pending approval | Amber Warn (#F59E0B) | ⏳ `hourglass_top` | "Waiting" |
| Needs revision | Brick (#C6412A) | ↩ `undo` | "Try again" |
| Completed | Sprout (#4CAF50) | ✓ `check_circle` | "Done" |
| Overdue (state of any active task) | Brick (#C6412A) | ⚠ `warning` | "Overdue" |

- **Available is neutral on purpose.** An unclaimed task hasn't earned a
  saturated color yet; an open circle + "Available" reads correctly and keeps
  the warm hues for *live* work. This replaces the current `Colors.blue`.
- **Brick** (#C6412A) replaces the current `Colors.red` / `#F44336` —
  warmer, sits inside the family.
- **Carrot** (#FB8C00) is deliberately distinct from Amber Warn so "in
  progress" and "waiting" never read as the same state.

### Contrast Pairs (normative)

Computed from the token hexes, not estimated. An earlier revision of this
table was eyeballed and three rows were wrong — one of them inverted a
pass/fail and shipped a failing pairing as "AA". These are asserted by
``test/presentation/theme/token_contrast_test.dart``; change a token and the
test tells you what it costs.

| Foreground | Background | Ratio | Use |
|---|---|---|---|
| Ink #241D14 | Cream #FBF7F0 | 15.60:1 | body text (AAA) |
| Ink-Soft #5C5346 | Cream #FBF7F0 | 7.07:1 | secondary text (AA) |
| Ink #241D14 | Marigold #E08A1E | 6.20:1 | primary button text (AA) |
| Ink #241D14 | Star Gold #FFB300 | 9.28:1 | tonal button / FAB icon (AAA) |
| Ink-Muted #8A8067 | Cream #FBF7F0 | 3.67:1 | large text / hints only — never body |
| Ink #241D14 | any 12% status tint | 13.2–14.3:1 | status pill label |
| status -deep | its own 12% tint | 4.3–5.7:1 | status pill icon (needs 3:1) |

**Prohibited:** white on Marigold (2.68:1) and white on Star Gold (1.79:1) —
both far under 4.5:1. Use Ink on every light brand surface.

**Also prohibited:** Cream on Toasted Marigold. A previous revision listed this
at "~4.6:1 (AA)" as the white-text variant; it is actually **3.85:1 and fails**
for body text. There is no white-text variant in this palette — marigold-deep
is a background for Ink text and a tone for icons, not a way to get white text.

### Dark Theme (planned; not yet in code)

- **Warm Charcoal** (#1E1812) background, **Warm Charcoal Surface** (#2A2218)
  cards, with marigold/star-gold carried over and ink inverted to cream tones.
  The warm undertone must survive the inversion — never a neutral zinc dark
  mode. (Implementation target for the `colorize` pass.)

### Named Rules

**The Warm-Neutral Rule.** Every neutral is tinted toward marigold. Pure
`#FFFFFF` and pure `#000000` are prohibited. Even a 0.005–0.01 chroma tilt
toward the brand hue is required.

**The One-Celebration Rule.** Coral and full-saturation accents appear on one
moment per screen at most. A celebration card earns coral; a screen with a
coral celebration plus a coral button has failed.

**The Status-Never-Alone Rule.** No status is conveyed by color alone. Every
status pill carries an icon and a word (e.g. ⏳ "Waiting", ✓ "Done"). This is
young-reader legibility made structural; it is not optional.

**The Ink-Label Rule.** Status text is Ink, never the status color. A
full-saturation hue on a 12% tint of itself tops out at 3.97:1 and bottoms out
at 1.84:1, so a pill that "looks like its status" is the least readable text in
the app — for the readers least able to cope with it. The hue lives in the tint
and the icon; the word is Ink. See §2 Contrast Pairs.

## 3. Typography

**Display Font:** System sans (-apple-system / SF Pro on iOS, Roboto on
Android, Segoe UI fallback) — the product register's earned-familiarity
default. No display pairing; one well-tuned sans carries everything.

**Body Font:** Same system sans.

**Character:** Chunky and friendly. Sizes skew larger than a typical product
app to serve emerging readers; weights lean bold for headings and labels.
The warmth comes from size and weight, not from a novelty face.

### Hierarchy

- **Display** (700, 32px, 1.2): greeting ("Hi Aisha! 👋"), celebration titles.
  Rare — one per screen at most.
- **Headline** (700, 24px, 1.25): screen-level titles, family name, the
  splash wordmark.
- **Title** (600, 18px, 1.3): card titles ("Today's Missions", "This Week's
  Stars"), section headers.
- **Body** (400, 16px, 1.45): the default. Larger than a typical app's 14px
  on purpose — young-reader legibility. Max line length 65–75ch for prose;
  task rows can run denser.
- **Body Small** (400, 14px, 1.4): secondary info, timestamps, metadata.
  Never below 14px — 11px and 12px statuses in the current code are
  prohibited.
- **Label** (600, 14px, 1.2, +0.02em): buttons, chips, list-item trailing
  counts. Bold and slightly tracked for tap-target legibility.

### Named Rules

**The 14px Floor Rule.** No text below 14px anywhere. The current 11px
"Awaiting Approval" and 12px task descriptions are violations; promote them
to 14px minimum.

**The Bold-Label Rule.** Button and status labels are 600 weight, never 400.
A kid taps what they can read at a glance.

## 4. Elevation

Flat by default. Depth is conveyed by **warm tonal layering** — a card is a
slightly lighter warm surface on the cream page with a warm hairline — not
by heavy shadows. This keeps the fridge-door feel (paper, not glass).

### Shadow Vocabulary

- **Ambient** (`0 1px 3px rgba(36,29,20,0.08)`): the only default shadow, on
  cards and inputs at rest. Barely there.
- **Lifted** (`0 4px 12px rgba(36,29,20,0.12)`): reserved for state — the FAB,
  a pressed/active action button, a dragged task tile. Never decorative.

### Named Rules

**The Flat-By-Default Rule.** Surfaces are flat tonal layers at rest.
Shadows appear only as a response to state (press, lift, focus). A static
card with a heavy drop shadow is a SaaS-dashboard tell and is prohibited.

**The No-Glass Rule.** Backdrop-filter / glassmorphism is prohibited. Depth
is opaque warm surfaces, never frosted blur.

## 5. Components

### Buttons

- **Shape:** 16px corners (lg), min 48px height, 16px 24px padding.
- **Primary (filled):** Marigold fill, **Ink** text (not white — marigold is
  light). For the one primary action per screen.
- **Tonal:** Star-gold fill, Ink text. Secondary actions (e.g. "Join
  family").
- **Outlined danger:** transparent, Brick text + Brick border. Reject /
  cancel / delete.
- **Text:** Ink-soft, no border. Tertiary (e.g. "Forgot Password?").
- **Hover / Focus:** tonal shift to the deep variant (Toasted Marigold) +
  a 2px marigold focus ring at 50% alpha. Press = Lifted shadow.
- **States required:** default, hover, focus, active, disabled, loading.
  Loading = spinner in place of label, button dims to 60%.

### Chips / Status Pills

Implemented once, in ``lib/presentation/widgets/status_pill.dart``. Build the
pill by using that widget, not by re-deriving the mapping at the call site —
three call sites each rolled their own and all three drifted.

- **Style:** full pill (999px), alpha-12% tint of the status color as
  background, an **Ink** label at 14px/600, and a leading icon in the status
  color's **-deep** variant. Never a bare colored dot.
- **Why the label is Ink, not the status color.** A full-saturation status
  color on a 12% tint of itself cannot reach AA: amber lands at 1.84:1,
  carrot 2.01:1, sprout 2.33:1, and even brick only 3.97:1, against a 4.5:1
  floor. Ink on the same tint is 13–14:1. Identity still comes from the icon
  and the word; the hue conveys aliveness through the tint and the icon, which
  is all the Status-Never-Alone Rule asks of it.
- **Why the icon is the -deep variant.** As a meaningful graphic it owes 3:1
  (WCAG 1.4.11); the base tones give 1.84–2.33:1 on their own tint. The deep
  siblings clear it at 4.3–5.7:1.
- **State:** per task status (Sprout/Amber/Carrot/Brick); each pill ships
  with its icon + label by default.
- ``test/presentation/theme/token_contrast_test.dart`` asserts all of the
  above against the real token values, including that the base tones still
  fail — so "just use the status color" cannot quietly come back.

### Cards / Containers

- **Corner:** 16px (lg).
- **Background:** Surface (#FCF9F4), warm hairline (Line) optional.
- **Shadow:** Ambient at rest, none needed for most. Never nested.
- **Internal padding:** 16px (lg).
- **Anti-pattern:** the current Task Details screen stacks a Card per
  section — that is prohibited here. One card groups related content;
  sections inside use dividers, not more cards.

### Inputs / Fields

- **Style:** OutlineInputBorder, 12px (md) corners, 16px padding, large
  label (Label style).
- **Focus:** 2px marigold border + marigold focus ring.
- **Error:** Brick border + Brick errorText inline below (never a SnackBar
  for field validation).
- **Disabled:** Ink-muted label, no border.

### Navigation

- **Bottom nav,** 4 items (Home, Tasks, Family, Profile). Fixed type.
- **Active:** Marigold-deep icon + label, bold.
- **Inactive:** Ink-muted. Min 48px tap target per item (the current default
  is acceptable; keep it).
- **FAB:** Star-gold circular, **Ink** plus icon (star-gold is light; white
  on it fails contrast — see Prohibited above), Lifted shadow. One per screen.

### Progress

- **LinearProgressIndicator:** chunky 12–16px track, Cream track, Marigold
  fill. Conveys level progress only.

### Avatars

- **Circular,** initial in bold Ink, 28–56px. The current `CircleAvatar`
  default is the right shape; tint its background toward marigold (currently
  `primaryColorLight`).

### Signature Component: Today's Missions

The kid's daily entry point. A single card listing today's missions as
chunky list rows: a large tap circle (tap to complete), the mission title in
Body, and the "+N ⭐" reward in Label. Waiting rows show ⏳ + "Waiting";
done rows show ✓ + strikethrough title. Empty state: "No missions today 🎈".
This is the fridge door's main column — it must parse in one glance for a
6-year-old.

**Flutter implementation notes.** Depth = `BoxShadow` on a `BoxDecoration`
(Ambient/Lifted) or Material tonal `elevation`; **never `BackdropFilter`**
for depth (the No-Glass Rule). Motion uses `Curves.easeOutQuart` /
`Curves.easeOutExpo`, 150–250ms, gated by `MediaQuery.accessibleNavigation`
so the OS reduced-motion setting disables celebration. The current
`Curves.elasticOut` (CelebrationCard) and `AnimationController..repeat()`
pulse (PendingApprovalBadge) are both prohibited. Color tokens become a
`ThemeExtension<CustomColors>` (the existing `success`/`starGold` scaffold,
extended with `marigold`, `ink`, `cream`, `line`, and the status set) read
via `Theme.of(context).extension<CustomColors>()!`; `ColorScheme.fromSeed` is
reseeded to marigold.

## 6. Do's and Don'ts

### Do:

- **Do** tint every neutral toward marigold; use Cream (#FBF7F0) backgrounds
  and Ink (#241D14) text. Pure `#FFFFFF` and `#000000` are prohibited.
- **Do** make every interactive element at least 48×48px and every button
  16px corners, 600-weight label.
- **Do** pair every status color with an icon and a word (⏳ "Waiting", ✓
  "Done", ⚠ "Overdue"). Status never rides on color alone.
- **Do** keep body text at 16px and never below 14px (the 14px Floor Rule).
- **Do** use one celebration moment per screen; let coral and full-saturation
  accents be rare.
- **Do** convey depth with warm tonal layering + the Ambient shadow; reserve
  the Lifted shadow for state (press, FAB, drag).
- **Do** honor the platform reduced-motion setting: gate the pulse badge and
  any celebration animation; use ease-out-quart, never elastic/bounce.
- **Do** keep the app's gamification warm and earned — points, streaks,
  levels, a weekly leaderboard — in service of the fridge-door metaphor.

### Don't:

- **Don't** ship the default Flutter / Material 3 look — no purple-from-seed
  (`#6750A4`), no grey card stack. This is the project's stated
  anti-reference and the current state of the code; the `colorize` pass
  replaces it.
- **Don't** make it babyish: no Comic-Sans-adjacent faces, no over-cartoonish
  illustrations that patronize an 8–12 year old or a teen. Playful is not
  infantile.
- **Don't** build a corporate SaaS dashboard: no dense data tables, no
  navy/grey, no hero-metric cards (big number over tiny label). The current
  Task Details "Points" card is exactly this template and must be demoted.
- **Don't** clutter with gamification: no stacked confetti, no competing
  animations, no perpetual pulse. One moment at a time.
- **Don't** use gradient text (`background-clip: text`), glassmorphism
  (`backdrop-filter`), or side-stripe borders (`border-left > 1px` as an
  accent). All prohibited.
- **Don't** use bounce or elastic easing (`Curves.elasticOut`,
  `Curves.bounceOut`). The current CelebrationCard's `elasticOut` is a
  violation.
- **Don't** stack a Card per section (the current Task Details pattern). One
  card groups; dividers separate.
- **Don't** convey status, urgency, or meaning by color alone — always icon +
  label. A kid who can't decode hue must still read state.
- **Don't** run a perpetual animation when offscreen (the current pulsing
  approval badge). Motion conveys state, never decoration, and stops when
  not visible.