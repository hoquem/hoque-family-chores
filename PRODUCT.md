# Product

## Register

product

## Users

Two roles share one app, and the design must serve both without two separate
design systems.

- **Children (primary, daily-driver user).** Range roughly 5 to early-teens.
  They open the app to see *their* work for today: missions, streak, level,
  leaderboard standing. Context is short, frequent sessions, often on a
  shared family phone, in the kitchen or living room, ambient light varies
  (morning before school, evening after dinner). Many are still learning to
  read; some have developing motor control. They want a reason to open the app
  and a dead-simple path from "what do I do" to "I did it." Motivation comes
  from points, stars, streaks, and celebration, not from a productivity
  checklist.
- **Parents / guardians (manager user).** Create the family, set invite code,
  create and assign tasks, approve or reject completed work, see the
  approval queue. Context is quick, purposeful check-ins ("anything waiting
  for me?"), not leisurely browsing. They need trust and clarity: a clean
  approval queue, obvious state, no fumbling. They will hand the phone to a
  child and want the child surface to be safe and self-explanatory.

Job to be done: make family chores trackable and *fun* so kids want to
participate and parents can run the household without nagging.

## Product Purpose

A family-chores app that gamifies responsibility: parents create and assign
tasks, children claim and complete them, completion flows through an approval
step, and a points / levels / streaks / weekly-leaderboard system rewards
participation. Success looks like kids opening the app unprompted to do their
missions and parents clearing an approval queue in seconds. Apple and Google
sign-in for parents; anonymous join-by-code for kids (no email/password
needed).

## Brand Personality

**Playful. Encouraging. Trustworthy.**

- *Playful*: celebration, streaks, stars, medals, friendly greeting. The
  app is allowed to be loud at moments of achievement.
- *Encouraging*: never punitive. Overdue and "needs revision" states
  are framed as "still to do" / "try again," not failure. Progress is
  shown as forward motion (level progress bar), never as a deficit.
- *Trustworthy*: a parent hands this to their child. It must feel safe,
  legible, and un-sleazy. No dark patterns, no manufactured urgency, no
  ads-shaped surfaces.

Real-world references in the right lane (playful progression, kid-legible,
parent-trustworthy): Duolingo (streaks, friendly progression, one
celebration at a time without clutter), Khan Academy Kids (large, legible,
warm, never babyish to an older kid). Both are playful *and* trusted by
parents, which is the exact tension this app lives in.

## Anti-references

What this must explicitly NOT look like:

- **The default Flutter / Material 3 template.** Purple-from-seed, grey
  card stack, out-of-the-box look that reads as "a Flutter tutorial."
  The current app is in this state; it must look deliberately *this*
  family's app, not the framework's demo. (See the impeccable audit.)
- **A babyish toddler toy app.** Comic-Sans-adjacent, over-cartoonish,
  patronizing to an 8-12 year old or a teen in the family. Playful is not
  the same as infantile; older kids in the family will reject it.
- **A corporate SaaS dashboard.** Dense data tables, navy/grey, enterprise
  tone, hero-metric cards. Wrong context: this is a home, not a reporting
  tool. Parents' management surfaces are clean and calm, not spreadsheet-y.
- **Cluttered gamification.** Confetti, popups, badges, and animations all
  competing for attention. One celebration moment at a time. Dopamine earned
  by real completion, not manufactured by noise.

## Design Principles

Strategic principles derived from the above. These guide every design pass;
they are NOT visual rules (colors, radii, fonts live in DESIGN.md).

1. **Playful, never babyish.** Delight is for kids of all ages in the
   family, including teens. Calibrate celebration to be warm, not infantile.
2. **One moment at a time.** A single celebration, a single streak nudge, a
   single attention-grabbing element per screen. Motion and emphasis are
   scarce resources, spent deliberately, never stacked.
3. **The tool disappears into the chore.** Product register: earned
   familiarity over novelty. Standard, predictable affordances so the
   interface doesn't get in the way of either a kid doing a task or a parent
   approving one.
4. **Read it like a kid reads.** Legibility for emerging readers: large
   minimum text sizes, generous spacing, and status conveyed by icon + label,
   never by color alone. A 6-year-old and a parent should both parse a task
   row in one glance.
5. **Earned identity, not the template.** Reject the out-of-the-box look.
   Every default (the M3 purple seed, the grey card stack, the default
   progress indicator) is a starting point to replace, not a decision to
   keep. The app should look intentionally designed for *this* family.

## Accessibility & Inclusion

Kids span a wide age and ability range; the app is handed to children.
Accessibility is a product requirement, not a nicety.

- **WCAG AA minimum** across the app: 4.5:1 body contrast, 3:1 large text,
  full keyboard / assistive-tech support via explicit `Semantics` on every
  non-standard gesture, image, and emoji status indicator.
- **44px minimum touch targets** (iOS HIG / WCAG 2.5.5) on every interactive
  element, sized for small hands and developing motor control.
- **Reduced-motion support.** Honor the platform reduced-motion setting:
  the perpetual pulse badge and any bounce / elastic easing must be gated.
  Motion conveys state (progress, completion), never decoration.
- **Young-reader legibility.** Larger minimum body text than a typical
  product app, generous line spacing, and status reinforced with an icon and
  word, not color alone (pending / approved / overdue). Emerging readers
  should never have to decode color to understand state.