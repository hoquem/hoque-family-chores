# Design Spec: Auth Redesign — OAuth Parents + Accountless Kids

**Date:** 2026-07-09
**Status:** Approved (revised after spec review v1)
**Author:** Mahmud + Claude

## 1. Problem & Goals

Today every family member — parents and children alike — is a full Firebase Auth
user created via email/password, with a `role` field. This has two problems:

1. **Poor UX**, especially for children, who must manage an email and password.
2. **Weak integrity.** All chore/points logic runs client-side against Firestore.
   Security rules currently let a signed-in child write their own `points` field
   directly, so a child can self-award points without parental approval.

### Goals

- Parents sign in with **Sign in with Apple** and **Google** (no password).
- Children use the app on **their own devices** with **no account** — entry is a
  **family invite code + a PIN**.
- **Airtight integrity**: no client (parent or child) can write points, set a task
  `approved`, or alter a task's reward value; those happen server-side only.
- Keep an email/password path solely for **App Review**, hidden from normal users.

### Non-goals

- Data migration — this is a **clean break** (§8).
- Push notifications, Android polish, or feature work beyond auth.

## 2. Identity Model

Two mechanisms, **one `users/{id}` collection** so task assignment
(`assignedToId`), member queries (`where familyId ==`), and points display keep
working with minimal change.

| | Parents | Children |
|---|---|---|
| Auth | Firebase Auth: Apple / Google OAuth | Firebase Auth: **custom token** (uid = child profile id) |
| Account | Identity provider | None — no email, password, or OAuth |
| Entry | "Sign in with Apple / Google" | Family invite code → pick profile → PIN |
| Role source | `users/{uid}.role` (Firestore doc) | Token claim `role: 'child'` + `familyId` |
| Email | Present | `null` |
| Reinstall | Provider re-login | Re-enter code + PIN (points persist on the profile) |

The child's Firebase Auth user is **pre-created when the parent adds the child**
(`createChild`, §4.2), which also sets its `role`/`familyId` custom claims. Later,
`childSignIn` (§4.3) mints a bare `createCustomToken(childId)`; the claims already
resident on the user record merge into every ID token, so security rules can rely
on `request.auth.token.role`/`familyId` from the first sign-in onward.

**Role model simplified (adopting review):** the role enum collapses to
`{ parent, child }`. `guardian` and `other` are removed. Any adult who signs in is
`parent` (all adults are admins); children are `child`. This is done during the
clean break, so no migration of old roles is needed.

## 3. Data Model Changes

- **`User.email` → nullable** (`Email?`). Children have no email; we do not
  fabricate one. **Task: audit every `.email` call site app-wide** (display,
  mapping, analytics, any lookup-by-email), not just the entity/tests.
- **Child profile** = `users/{childId}`: `role: child`, `email: null`, `points`,
  `familyId`, `name`, optional avatar. `assignedToId` already references a user id.
- **Existing family model is retained** (not re-invented): `families/{familyId}`
  (`name`, `creatorId`, `memberIds`, `inviteCode`) and `familyInvites/{code}` →
  `familyId`, with the current **client-side** `CreateFamilyUseCase` /
  `JoinFamilyUseCase`. A parent creating a family becomes its `creator` and gets
  their `familyId` set (write-once, §5); a second adult joining via invite code
  likewise gets `familyId` set write-once. Invite-code generation lives on the
  family doc; a parent can **rotate** it (§6). `listChildren` (§4.1) and the picker
  assume this model.
- **Task reward value is server-trusted.** Each task carries an explicit
  `pointValue` set only at creation by a parent (or Cloud Function). Rules forbid
  any child write to `pointValue`. `approveTask` awards **`task.pointValue`** — it
  never trusts a points amount supplied by a client at approval time. (Closes
  review B1.)
- **`childCredentials/{childId}`** — new **server-only** collection holding the
  salted PIN hash, salt, and attempt counters/timestamps. Rules deny all client
  read/write; only Cloud Functions touch it. (A separate collection is required
  because Firestore cannot hide a single field on an otherwise-readable doc.)

## 4. Cloud Functions (Firebase, Blaze plan)

All callables are protected by **Firebase App Check**. The child-facing callables
(`listChildren`, `childSignIn`) are the brute-force surface and App Check is
mandatory on them.

1. **`listChildren({ inviteCode })`** — *unauthenticated*, App-Check-gated,
   rate-limited. Resolves the invite code to a family and returns that family's
   child profiles (`childId`, `name`, `avatar`) so the pre-auth device can render
   the picker. Returns nothing else. Rate-limited: max 10 calls per device
   (App Check token) per 10 minutes. (Closes review B3 — the §6 avatar grid now has
   a data source.)

2. **`createChild({ name, pin, avatar? })`** — caller must be an authenticated
   parent of a family. Generates `childId`, then **pre-creates the Firebase Auth
   user** (`admin.auth().createUser({ uid: childId })`) and immediately
   `setCustomUserClaims(childId, { role: 'child', familyId })`, then writes
   `users/{childId}` + `childCredentials/{childId}` (hashed PIN). Pre-creating the
   auth user is what makes claims durable: `setCustomUserClaims` claims persist
   across ID-token refresh, so we never depend on `createCustomToken`'s ephemeral
   developer-claims. (Fixes review B2 cleanly; dissolves the former verification
   task.)

3. **`childSignIn({ inviteCode, childId, pin })`** — App-Check-gated. Verifies
   `childId` belongs to the code's family, verifies the PIN against the stored hash
   with **server-side rate limiting** (see policy below). On success mints
   `createCustomToken(childId)` — no extra claims needed, because `role`/`familyId`
   already live on the auth user's custom claims (set in `createChild`) and are
   merged into every ID token. Client then calls `signInWithCustomToken`.

4. **`approveTask({ taskId })`** — caller must be a parent of the task's family.
   In a transaction: assert current status is **not already** `approved`
   (idempotent — a retry or a second parent no-ops), flip to `approved`, and
   increment the assigned child's `points` by the server-trusted `task.pointValue`.
   (Closes review B1 + idempotency should-fix.)

5. **`resetChildPin({ childId, newPin })`** — **core scope** (promoted from
   optional). Parent-only. Re-hashes the PIN **and calls
   `admin.auth().revokeRefreshTokens(childId)`** so a compromised session is cut off
   immediately rather than lingering up to the ~1h token lifetime. `deleteChild`
   behaves the same (delete docs + revoke).

**Rate-limit policy (explicit):** max 5 PIN attempts per child per rolling 15
minutes; on exceed, lock that child for 15 minutes. Lock auto-clears; a parent may
also `resetChildPin` to clear immediately. Counters live in `childCredentials`.

**PIN hashing note:** a salted slow hash is used, but the real protection for a
4-digit PIN is the **server-only locked collection + rate limiting** — a leaked
hash dump falls to all 10,000 candidates regardless of cost factor. We rely on the
former, not hash strength.

## 5. Security Rules

- **`points`: writable only by the Admin SDK.** Any client write (parent or child)
  that sets `points` is **denied** — only `approveTask` does it.
- **`pointValue` and the `approved` status: write-once at creation / server-only.**
  A parent may set `pointValue` **only at task creation** (never on update); the
  `approved` transition is Admin-SDK-only (`approveTask`). Both are denied to
  children entirely.
- **`role` is immutable after creation.** No self-escalation to `parent`.
- **`familyId` is write-once**: settable by the owning user only when its prior
  value is empty/null (the create/join-family onboarding write, §6), immutable
  thereafter. No hopping families. (This is what lets the existing client-side
  `CreateFamilyUseCase`/`JoinFamilyUseCase` populate it; §3.)
- **Children** (`request.auth.token.role == 'child'`, matching `familyId`): may read
  their family and its tasks; may write **only their own** assigned tasks, and only
  the allowlisted fields, via
  `request.resource.data.diff(resource.data).affectedKeys().hasOnly([...])` — the
  allowlist is `status`, `assignedToId`, `completedAt`, `updatedAt` (+ any
  submission-note/photo field), finalized against the `Task` model. Never
  `pointValue`. Permitted **status transitions** (full table, closes review B4):

  | From | To | Meaning |
  |---|---|---|
  | `available` | `claimed` (sets `assignedToId = self`) | child claims |
  | `claimed` | `available` (clears `assignedToId`) | child unclaims |
  | `claimed` / `assigned` | `pendingApproval` | child submits |
  | `needsRevision` | `pendingApproval` | child resubmits after send-back |

  All other transitions (`approved`, `rejected`, `needsRevision`, parent assignment)
  are parent/function only. `rejected` is terminal for the child.
- **Parents**: create/edit tasks (including `pointValue` at creation), manage child
  profiles, manage the family — but still cannot client-write `points`/`approved`.
- **`childCredentials/{childId}`**: `allow read, write: if false`.

## 6. UI Changes

- **Login screen**: "Sign in with Apple" + "Continue with Google" primary. Email
  form removed from normal view (§7 hidden path; §9 Phase 1 exception).
- **New "Manage Children"** (parents): add child (name + PIN), edit, remove, reset
  PIN. In the Family tab.
- **New kid onboarding** (kid device): enter family code → `listChildren` renders
  the avatar grid → tap your profile → enter PIN → `childSignIn`.
- **Shared-device switching:** before a new child onboards on a device where
  another child is signed in, the app **explicitly signs out the current child and
  clears the local Firestore cache** so sessions/data don't bleed across kids.
- **First-run for a new OAuth parent:** on first successful OAuth sign-in with no
  existing `users/{uid}`, the app creates the doc (`role: parent`, `familyId`
  empty) in a single onboarding write, then routes to create/join-family. Until a
  family exists the user can read/write only their own doc. The parent/child join
  toggle is gone (all adults are parents).
- **Invite-code rotation:** a parent can regenerate the family invite code (old
  code stops resolving) to recover from a leaked code.

## 7. Hidden Email/Password Path for App Review

The email/password provider stays enabled but is reachable only via a **hidden
gesture** (e.g., 7 taps on the version label) that reveals an email form. A
pre-created parent demo account with a pre-populated family + sample children/chores
is given to reviewers in App Store Connect "App Review Information," with the
gesture instructions. **This demo account is (re)provisioned as an explicit Phase 2
rollout step *after* the clean-break wipe (§8)** — it must not be swept away with the
discarded data, or review fails on "can't sign in."

## 8. Migration — Clean Break

Existing accounts and family data are **discarded**. Live testers (Mahmud, Alima)
recreate their family via OAuth and re-add children; existing points/history are
wiped. Destructive and irreversible, accepted given the small family beta. No
migration code. The App Review demo account is recreated afterward (§7).

## 9. Sequencing — Two Shippable Phases

### Phase 1 — OAuth for parents (free tier, ships first, independent)

- Add `sign_in_with_apple` + `google_sign_in`; extend `AuthRepository` with
  `signInWithApple()` / `signInWithGoogle()` + expose `authStateChanges`.
- Firebase Console: enable Apple + Google providers. Xcode: add **Sign in with
  Apple** capability; add Google reversed-client-id URL scheme to `Info.plist`.
- **OAuth account-collision handling:** decide and implement a linking strategy for
  Firebase's one-account-per-email (a parent using Google then Apple on the same
  address triggers `account-exists-with-different-credential`); handle Apple "Hide
  My Email" relay addresses. Specify before coding Phase 1.
- Login shows Apple + Google. **Email/password stays fully visible in Phase 1**
  because existing children still use it. Toggle removal is scoped to the *new OAuth
  path only*; no new children are onboarded via email during Phase 1 (the beta
  family's children already exist).
- Ships to TestFlight independently; gets Sign in with Apple through review early.

### Phase 2 — Accountless kids (Blaze plan)

- Enable **Blaze**.
- Add the Cloud Functions (§4); add child-profile model + `pointValue` (§3); build
  "Manage Children" + kid onboarding (§6).
- Move approve→points into `approveTask`; **lock the rules** (§5).
- **Consolidate the two auth-truth sources** (`main.dart`'s direct
  `FirebaseAuth.authStateChanges()` vs `AuthNotifier`) onto the
  repository/notifier, so OAuth and child custom-token sessions route uniformly.
  (Assigned here per review; load-bearing for child routing.)
- **Remove the visible email/password path last**, only after the kid flow works
  end-to-end — leaving only the hidden review path (§7). Children are never locked
  out mid-transition.
- Clean-break switchover (§8) + recreate demo account (§7); ship.

## 10. Testing Impact

- **Entity tests** for nullable email + collapsed role enum.
- **`MockAuthRepository`** gains OAuth methods + `authStateChanges`.
- **BDD feature tests** (`test/features/task/`, e.g. `i_am_logged_in_as_a_child`,
  `i_approve_the_task`, `points_should_be_awarded_to_the_child`) reworked: a child
  is a custom-token profile; approval/points go through `approveTask`.
- **New tests**: Cloud Functions (createChild; childSignIn PIN + rate-limit +
  App Check; approveTask authorization, idempotency, atomic award of `pointValue`;
  resetChildPin revocation); security-rules tests (child cannot write
  points/pointValue/approved, cannot change role/familyId, cannot read
  childCredentials; full transition table incl. `needsRevision→pendingApproval`);
  OAuth mapping + account-collision.

## 11. Risks & Open Items

- **Child claims durability:** resolved by design — `createChild` pre-creates the
  auth user and sets `setCustomUserClaims` (§4.2), whose claims are documented to
  persist across ID-token refresh. No dependence on `createCustomToken` ephemeral
  claims, so no empirical verification task remains.
- **OAuth account collision (specify before coding Phase 1):** linking strategy for
  Firebase one-account-per-email and Apple "Hide My Email" relay addresses (§9).
- **Blaze billing:** card on file; ~$0/mo at family scale. Accepted.
- **Apple Sign in review:** needs the capability + reliable hidden demo path.
- **COPPA / Apple Kids Category:** children under 13 use this on their own devices.
  Mitigation: we collect **no child email or PII** beyond a parent-entered display
  name and avatar; no ads, no tracking. Confirm against Apple's current
  kids/family guidelines; do **not** enroll in the Kids Category unless required
  (it triggers stricter review). State the data-collected posture in the privacy
  policy.
- **App Check provisioning:** requires registering the app with App Check
  (DeviceCheck/App Attest on iOS) before the callables can enforce it.
