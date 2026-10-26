# Managed Child Profiles — Design

**Status:** approved design, not yet implemented
**Date:** 2026-10-26
**Goal:** Let a parent add a child who has no phone, so a family gets value
from Chores Star on day one with a single install. The child uses the app on
the parent's phone through a child view, and can move to a phone of their own
later without losing stars or history.

## Why

Usage on 2026-10-26 (`scripts/usage_report.py`): 41 families, only 8 with 2+
members; 5 families approved a chore in the last 30 days; 6 invites shared,
2 members joined by code. Today every member needs their own device and
account, so a solo parent has nobody to assign chores to and the board stays
empty. Invite nudges (1.4.5) improve a funnel that is starting too small.
Managed profiles remove the dependency on a second install.

## Decisions (with product owner)

- **Child view on a shared phone**, not "parent acts on their behalf". The
  child taps Done on their own chores in a child view on the parent's phone.
- **Switch back is a plain button**, no PIN or biometrics. This follows the
  trust-based product philosophy: everything the child does is visible, and
  only a parent's view can approve, so the child cannot mint stars.
- **Linking to the child's own phone is in v1.** Without it a child who gets
  a phone would start again at zero.
- **Approach A: the phone stays signed in as the parent.** Firebase Auth never
  switches on the shared phone; the app shows the child's view on top. Signing
  in as the child (custom token on the shared phone) was rejected because
  switching back would force the parent through Google/Apple sign-in again.
  A separate `families/{id}/kids` model was rejected because every star,
  leaderboard and assignee path would need a second branch.

## 1. Data and server

### Profile

A managed child is an ordinary `users/{childId}` document: `role: 'child'`,
`familyId`, `points: 0`, `name`, plus a new field `managed: true`. `childId` is
a Firestore auto-id; no Firebase Auth user exists for it until the child links
a phone. Because it is a normal member id in `families/{id}.memberIds`:

- chores, the assignee dropdown, the leaderboard, recurring rules and
  `approveTask` work unchanged (`approveTask` pays `task.assignedToId`);
- the existing `users` read rule (same `familyId`) already lets the family see
  the profile;
- `onAuthUserDeleted` never fires for it.

`notify(childId, ...)` writes an in-app notification (visible once the child
links a phone) and finds no FCM tokens, so no push is sent. No change needed.

### New Cloud Functions

| Function | Caller | Behaviour |
|---|---|---|
| `addManagedChild({familyId, name})` | parent/guardian in `familyId` | One transaction: refuse if the family already has 10 managed children; create the profile; `arrayUnion` the id into `memberIds`. Returns `{childId}`. |
| `removeManagedChild({familyId, childId})` | parent/guardian in `familyId` | Refuse unless the target is `managed` and in the family. Run `releaseDeletedMember` (memberCleanup.js) to release chores and unassign rules, then delete the profile and any link code for it. |
| `createLinkCode({familyId, childId})` | parent/guardian in `familyId` | Target must be `managed` and in the family. Delete any existing code for this child, write `profileLinks/{code}` `{childId, familyId, createdBy, expiresAt: now + 24h}`. Code: 12 characters from the invite-code alphabet. Returns `{code, expiresAt}`. |
| `redeemLinkCode({code})` | anyone, signed in or not | One transaction: code exists, not expired, child profile exists and is still `managed`; delete the code. Then return `{token: createCustomToken(childId)}`. Does **not** clear `managed` (see `onAuthUserCreated`). |
| `onAuthUserCreated` (v1 auth trigger) | system | If `users/{uid}` exists with `managed: true`, set `managed: false`. This is the only place `managed` is cleared, so it flips only once the child's phone has really signed in. |

### Changes to existing functions

- `claimReward` and `settleRedemption` accept an optional `forMemberId`.
  Accepted only when the caller is a parent/guardian in `familyId` **and** the
  target profile is `managed: true` in the same family; otherwise
  `permission-denied`. When present, stars move on the target's profile,
  `claimedBy` is the target, a new field `claimedVia` records the caller's uid,
  and `settleRedemption` checks `r.claimedBy === forMemberId` and notifies the
  target. Without `forMemberId` both behave exactly as today.
- `onAuthUserDeleted`: after releasing the deleted user, if the family has no
  parent/guardian left, remove its managed children the same way
  `removeManagedChild` does. Account deletion cannot be blocked (App Store
  requirement), so this is the only safe end state.

### Firestore rules

- `match /profileLinks/{code} { allow read, write: if false; }`
- `users` update: add `request.resource.data.get('managed', false) ==
  resource.data.get('managed', false)` so no client can set or clear it.
- No current client writes `managed`, so the rules can deploy ahead of the
  client build (see the rules-deploy-ordering note).

### Infrastructure

`createCustomToken` from Cloud Functions needs the functions' runtime service
account to hold **Service Account Token Creator** on itself
(`iam.serviceAccounts.signBlob`). Check and grant before deploying.

## 2. App

### Active member

A new `ActiveMemberNotifier` (Riverpod, keepAlive) holds `null` (the signed-in
user, the normal case) or the managed child currently using the phone. It is
not persisted: a cold start always opens the parent's view. It resets to
`null` when the child's profile is removed or stops being `managed`.

Existing use cases already take a `userId`. `CompleteTaskUseCase` checks
`task.assignedToId == userId`, so the child view passes `childId` and Done
works unchanged. The same holds for claiming an up-for-grabs chore
(`ClaimTaskUseCase`).

### Child view

`ChildModeScreen` is a separate, small shell, not `MainScreen`. About 29
presentation files read the signed-in user from `authNotifierProvider`; a
separate shell leaves all of them untouched.

- Header: the child's avatar, name, star count, and a prominent
  **"Back to {parent's name}"** button that sets the active member to `null`.
- **My chores** tab: the child's assigned chores with Done (photo-proof chores
  use the phone's camera as they do today), and up-for-grabs chores with Take.
- **Treats** tab: the family's treats with Claim, and the child's open claims
  with settle, both calling the functions with `forMemberId`.
- No adding, editing, deleting or approving. Approval happens in the parent's
  view as today.

### Adding a managed child

- **Invite your family** screen (shown right after creating a family) and the
  Home invite card: a second action, **"Add a child without a phone"**, next
  to Share invite. This is the activation entry point.
- **Family** screen: the same action in the members area.
- The add sheet asks for a name only, then calls `addManagedChild`.
- Managed children show a small "No phone" label in the Family list and on
  their member page.

### Managed child's member page (parent/guardian only)

- **Hand the phone to {name}**: sets the active member and opens
  `ChildModeScreen`.
- **Move {name} to their own phone**: calls `createLinkCode`, shows the code
  (grouped like invite codes), its expiry, and the steps for the child's phone.
- **Remove {name}**: confirmation dialog, then `removeManagedChild`.

### Linking on the child's phone

The existing "I'm a kid" screen (`child_join_screen.dart`) gains a link:
*"Already in your family on a parent's phone? Use a link code."* It calls
`redeemLinkCode`, then `FirebaseAuth.signInWithCustomToken(token)`, and lands
on the normal home screen as that child, with their stars and history.

### Leaving the family

`LeaveFamilyUseCase` refuses with "Remove or move {name} first" when the
leaver is the family's only parent/guardian and managed children remain.

### Measurement

New analytics events: `managed_child_added`, `child_mode_entered`,
`link_code_redeemed`. `scripts/usage_report.py` reports them and the number of
managed profiles. Its "active families" count already includes chores
approved for managed children, which becomes the success measure (families
approving chores weekly), rather than families with 2+ signed-in members.

## 3. Errors and edge cases

- **Link sign-in fails after redeem** (e.g. network drop): the code is used up
  but `managed` is still true, because only `onAuthUserCreated` clears it. The
  parent makes a new code. The error says so: "That didn't finish. Ask a
  parent for a new code."
- **Link code errors** each get their own message: expired ("This code has
  expired. Ask a parent for a new one."), unknown/used, or the child has been
  removed.
- **Child removed or linked while the child view is open:** the view closes
  and returns to the parent's view.
- **Last adult deletes their account:** handled in `onAuthUserDeleted` (above).
- **Older app versions:** a managed child appears as an ordinary member.
  Nothing breaks; older clients cannot open the child view or claim treats for
  the child.
- **Limits:** 10 managed children per family. A 12-character code (about 60
  bits) expiring in 24 hours is not practical to guess.
- **Duplicate names** are allowed, as they are for real members.

## 4. Testing

- **Emulator tests**, `test/rules/managed_child.test.mjs`, in the style of
  `functions_economy.test.mjs`:
  - add/remove: parent, guardian, child caller, parent of another family;
    the 10-child cap; remove refuses a non-managed member.
  - `forMemberId` on claim and settle: accepted for a managed child in the
    caller's family; refused for a child caller, another family's parent, and
    a non-managed target; stars move on the target, `claimedVia` recorded.
  - link codes: expiry, single use, one active code per child, refuse after
    removal; `onAuthUserCreated` clears `managed`.
  - `onAuthUserDeleted` removes managed children when the last adult goes.
  - rules: a client cannot write `managed` or read `profileLinks`.
- **Dart unit tests (test-first):** `ActiveMemberNotifier`, the pure "who may
  act for whom" decision, the leave-family refusal, link-code use case error
  mapping.
- **Widget tests:** `ChildModeScreen` shows only the child's chores and the
  family's treats; Back returns to the parent; the add-child sheet.
- **Manual check on the simulator**, never the live family board: add a child,
  hand over, mark Done, go back, approve, stars arrive; claim and settle a
  treat in the child view; link the child on a second simulator and confirm
  stars and history came across.

## Out of scope

- A lock (PIN or biometrics) on the child view.
- Persisting the child view across app restarts.
- Managed adults or guardians.
- Moving an existing signed-in member back to managed.
