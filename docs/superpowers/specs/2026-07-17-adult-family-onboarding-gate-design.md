# Adult Family Onboarding Gate — Design (TASK-454)

**Status:** approved design, ready for implementation plan
**Date:** 2026-07-17
**Issue:** TASK-454 — "Apple/Google sign-ins need a way to join an existing family"

## Problem

An adult who signs in with Apple or Google is silently made a `parent` with **no
family** (`familyId` empty) and dropped on the **Home** tab. The only way to
create or join a family is buried two taps away inside the **Family** tab.
Nothing tells a new user to create a family or join one, so a second parent has
no obvious path into an existing family.

## Key finding: the capability already exists

This is a **UX/onboarding** problem, not a missing feature. Already present and
working:

- `JoinFamilyUseCase` (`lib/domain/usecases/family/join_family_usecase.dart`) is
  **role-parameterized** and auth-agnostic: it resolves an invite code to a
  family, adds the user to `memberIds`, and links the profile with the given
  role. An authenticated OAuth adult can call it directly.
- The invite-code lookup (`familyInvites/{code}` → `familyId`), code generation,
  and `addUserToFamily` membership write all exist.
- A create/join UI already lives inside the Family tab
  (`_FamilyOnboardingView` in `family_screen.dart`), including an invite-code
  field and a role switch.
- **Firestore rules already permit** every write an adult-join performs: a
  non-member may add only themselves to `memberIds` (families update rule),
  `familyInvites` is readable by code, and a user may self-update their own
  `familyId`/`role`. **No rules changes.**

So the work is: make create-vs-join a clear first-run step, and let a joiner
pick their adult role. No new backend, no new rules.

## Decisions (locked with product owner)

1. **Hard gate.** No family ⇒ the onboarding screen is the whole app (plus a
   Sign out affordance). The tabs are unreachable until a family exists. The app
   is useless without a family, and this removes the "lost on Home tab"
   confusion.
2. **Join role:** the joiner picks **parent or guardian** (both are
   admin-equivalent today; a joining adult is never a child).
3. **Create role:** the founder is **always parent** — no picker on create.

## Design

### 1. The gate (`_FamilyGate`) — the only new routing

A small widget in the authenticated branch of `main.dart` that watches
`authNotifierProvider`:

- profile still loading → existing splash/spinner;
- signed in **and** `user.familyId.isEmpty` → `FamilyOnboardingScreen`;
- signed in **and** has a family → `MainScreen` (today's behaviour).

Because it watches the streamed profile, completing a create or join flips
`familyId` from empty to set and the gate swaps to `MainScreen` automatically —
no manual navigation. The gate carries a **Sign out** action for the
wrong-account case.

No `go_router` change: `main.dart` currently routes with a `StreamBuilder`;
`_FamilyGate` slots into the `hasData` branch.

### 2. `FamilyOnboardingScreen` — extraction, not new UI

Lift the existing `_FamilyOnboardingView` (the create card + join card) out of
`family_screen.dart` into a standalone `FamilyOnboardingScreen`, used by **both**
the gate and the Family tab (DRY — one create/join surface). One change: the
**Join** card's parent/child switch becomes a **parent / guardian** picker. The
**Create** card is unchanged ("you'll be the parent").

The Family tab keeps rendering this screen for the (now rare) case of an
in-app user with no family; the gate makes it the first thing a new adult sees.

### 3. Backend — reuse unchanged

- **Join** → `FamilyOnboardingNotifier.joinFamily` → `JoinFamilyUseCase`, passing
  the picked role (`UserRole.parent` or `UserRole.guardian`).
- **Create** → `CreateFamilyUseCase` (creator → parent), unchanged.
- The provisional `role: parent` set at OAuth sign-in (`_afterOAuth`) is simply
  overwritten by whichever path completes, and is harmless meanwhile (a
  family-less user has no family-scoped rights).

## Data flow (join, the new-path case)

1. Adult signs in with Apple/Google → profile created `role: parent`,
   `familyId: empty` (existing).
2. `_FamilyGate` sees empty family → shows `FamilyOnboardingScreen`.
3. Adult taps Join, enters the invite code, picks parent or guardian.
4. `JoinFamilyUseCase(role: picked)` resolves the code, adds them to `memberIds`,
   sets their `familyId` + `role`.
5. Streamed profile updates → gate swaps to `MainScreen`.

## Edge cases

- **Children never hit the gate.** Child join (pre-auth, anonymous, from the
  login screen) is atomic and gives the child a family before they reach
  `MainScreen`; a failed child-join rolls back the account entirely.
- **Email/password path** (hidden, reviewer-only) quirkily defaults new users to
  `child`; the gate fixes this for free — they create/join into parent/guardian.
- **Wrong invite code** → existing `JoinFamilyUseCase` failure surfaces on the
  screen (unchanged behaviour). Sign out is available.

## Out of scope (note, do not build)

- "Leave / switch family" from within a family.
- Approval-before-join (leaked-code protection) — the code is shared privately,
  same trust model as child-join.
- Reconciling the email/password default-role quirk beyond what the gate fixes.

## Testing

- **Widget:** `_FamilyGate` shows `FamilyOnboardingScreen` when `familyId`
  empty, `MainScreen` when set.
- **Widget:** the Join card passes the chosen role (`guardian`) through to the
  notifier/use case.
- **Use case:** `JoinFamilyUseCase(role: guardian)` links the family and sets
  role guardian (fake/mocked repos).
- Existing child-join, create-family, and family-screen tests stay green.

## Files

- **Modify:** `lib/main.dart` (add `_FamilyGate` in the authenticated branch).
- **Create:** `lib/presentation/screens/family_onboarding_screen.dart` (extracted
  create/join surface + parent/guardian join picker).
- **Modify:** `lib/presentation/screens/family_screen.dart` (use the extracted
  screen; remove the inlined `_FamilyOnboardingView`).
- **Reuse unchanged:** `join_family_usecase.dart`, `create_family_usecase.dart`,
  `family_onboarding_notifier.dart`, `firestore.rules`.
- **Tests:** gate widget test, onboarding role-pass widget test, join-as-guardian
  use-case test.
