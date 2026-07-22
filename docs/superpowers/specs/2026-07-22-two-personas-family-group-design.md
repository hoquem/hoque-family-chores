# Two Personas: Family & Group — Design Sketch

> **Status:** Backlog / future work. This is a *design sketch*, not an approved
> implementation plan. When we're ready to build, it gets its own spec → plan →
> implementation cycle.
>
> **Conceived:** 2026-07-22 · **App:** Chores Star
> (`com.hoque.familychores` / `com.hoque.hoqueFamilyChores`)

## Vision

Chores Star solves "who does which chores, and is it fair?" for families. The
identical problem exists in **any communal living arrangement**: student
accommodation, shared houses / HMOs, flat-shares, even small teams. The engine
already generalizes — tasks, claiming, photo proof, anyone-but-the-doer
approval, points, streaks, leaderboard. What is family-specific is only the
**skin**: kid-flavored copy (stars ⭐, Treats, "I'll do it!"), the parent/child
role asymmetry, and the kids' home hub.

So: after authentication, a user creating a space chooses one of **two
personas** —

- **Family** — parents & kids. The current app, unchanged.
- **Group** — housemates, student halls, teams. Same engine, adult-oriented
  wording, flat roles, no Treats.

## Decisions (settled during brainstorm)

1. **Depth: copy + roles reskin, not structural changes.** Same flows, same
   engine, same Cloud Functions. Group mode changes wording, hides the kids'
   trappings, and flattens roles. No new mechanics.
2. **Economy in group mode: points + leaderboard, no Treats.** Earning points,
   streaks, and the weekly leaderboard stay (renamed from stars ⭐) — that is
   the fairness signal an HMO actually wants. The Treats/redemption tab is
   hidden: redemption has no natural payer between equals.
3. **Store: one app, broadened listing.** Group mode ships inside Chores Star;
   widen keywords/description ("flatmates, house share, student halls,
   roommate chores"). A white-labeled second listing ("House Chores", adult
   branding) is a noted future option, not part of this work.

## Architecture

### 1. Persona is a property of the space, not the user

`FamilyEntity` (`lib/domain/entities/family.dart` → Firestore
`families/{id}`) gains one field:

```
groupType: "family" | "group"     # absent ⇒ "family"
```

- **Zero migration:** every existing family document lacks the field and is
  treated as `family`.
- All members of a space see the same persona; a user who later belongs to
  both a family and a flat-share gets the right skin in each.
- The `families` collection, `familyId` value objects, and repository names
  keep their internal names — a rename would touch hundreds of call sites for
  zero user-visible value.
- v1: the type is **fixed at creation** (no switching later — avoids
  "what happens to Treats/kid members when a family becomes a group?").

### 2. Onboarding fork

`FamilyOnboardingScreen` (the first-run gate and the Family tab's empty
state) gains one prior question: *"Who is this space for?"* →

- **Family** — exactly the current create/join flow, including the separate
  child-join path (`child_join_screen.dart`). Untouched.
- **Group** — creator names the space (`groupType: "group"`), gets the same
  invite code; joiners enter through the same invite-code flow as adults.
  The child-join path is hidden in group spaces.

Joining is persona-blind: the invite code resolves the space, and the space's
`groupType` decides everything downstream.

### 3. Roles: reuse the existing enum, no rules changes

`UserRole` (`lib/domain/entities/user.dart`) is
`parent | child | guardian | other`, with `isAdmin => parent || guardian`.
The Firestore security rules and the server-side economy (`approveTask`)
already key off these.

**In group mode every member is stored with an admin-capable role**
(`parent` internally), *displayed* as "Member" ("Admin" for the creator).
Consequences, all free:

- Everyone can create/edit/delete tasks — correct for adult peers.
- The existing approval rule — any member **except the doer** approves —
  already fits groups perfectly. No new approval mechanics.
- **Zero Firestore-rules changes and zero Cloud Functions changes.** This is
  the load-bearing simplification of the whole design; if it ever breaks
  (e.g. rules later gain family-specific parent logic), the design must be
  revisited rather than patched around.
- Role *display names* become persona-dependent (see PersonaStrings), since
  `UserRole.displayName` currently hardcodes "Parent"/"Child".

### 4. PersonaStrings — the core build

Family copy is currently hardcoded across widgets (`task_list_tile.dart`,
`task_details_screen.dart`, `add_task_screen.dart`, `help_button.dart`,
`rewards_notifier.dart`, …). The feature centralizes it: a **PersonaStrings**
resolver (provider derived from the current space's `groupType`) that every
screen reads instead of literals.

| Concept | Family (today, unchanged) | Group |
|---|---|---|
| Currency | stars ⭐ | points |
| Claim | "I'll do it!" | "Claim" |
| Complete | "I've done it!" | "Done" |
| Approve | "Give the stars ⭐" | "Approve" |
| Reject | "Send back" | "Send back" |
| Unclaimed | "Up for grabs" | "Up for grabs" (already neutral) |
| Rewards tab | Treats | **hidden** |
| Home | kids' hub (missions, celebration) | neutral dashboard: "Today's tasks", streaks, leaderboard |
| Roles | Parent / Child / Guardian | Admin / Member |

Notes:

- The kids' home hub (`lib/presentation/widgets/home/today_missions_card.dart`
  and friends) is replaced in group mode by a neutral dashboard reusing the
  same providers (`home_stats.dart` streaks/leaderboard work unchanged — they
  are persona-independent math).
- Notification copy goes through the same resolver (a group member should not
  be told to "give the stars ⭐").
- Open question: keep or mute the celebration confetti in group mode.

### 5. What explicitly does NOT change

- Task lifecycle, photo proof, overdue handling, ordering.
- Server-side economy (`approveTask` etc.) — points accrue identically.
- Firestore security rules.
- Family persona pixel-for-pixel: **this feature must be provably zero-risk
  to the shipped family experience.**

## Synergy with TASK-468 (self-maintaining app)

Rotation-assigned auto-generated chores
(`docs/superpowers/specs/2026-07-22-self-maintaining-app-design.md`) are
arguably *more* valuable for groups — "whose turn is the bathroom" is the
canonical HMO argument. The two backlog items compound: build order should
consider shipping personas before or alongside rule-engine rotation so groups
get it from day one.

## Testing strategy

- Unit tests on the PersonaStrings resolver (both personas, every key).
- Widget tests run the key screens (task list, task details, add task, home,
  onboarding) under **both** personas — the mock-service layer already
  supports fabricating spaces, so this is cheap.
- A regression guard that the family persona's copy is byte-identical to
  today's strings (protects the shipped experience during the refactor).

## Open questions for the implementation spec

- Persona label in the UI: "Group" vs "House" vs "Household"?
- Confetti/celebration in group mode: keep (cheap delight) or mute?
- Should the neutral group dashboard show the approval queue more prominently
  (adults approve each other constantly)?
- Store-listing update timing: with the feature release or after group-mode
  feedback from a pilot house?
- Future: white-label second listing from the same persona layer.
