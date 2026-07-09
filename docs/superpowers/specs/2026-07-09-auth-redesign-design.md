# Design Spec: Auth Redesign — OAuth Parents + Accountless Kids

**Date:** 2026-07-09
**Status:** Approved (pending spec review)
**Author:** Mahmud + Claude

## 1. Problem & Goals

Today every family member — parents and children alike — is a full Firebase Auth
user created via email/password, with a `role` field (`parent` / `child` /
`guardian`). This has two problems:

1. **Poor UX**, especially for children, who must manage an email address and
   password. Account-creation friction is the biggest onboarding drop-off.
2. **Weak integrity.** All chore/points logic runs client-side against Firestore.
   Security rules currently let a signed-in child write their own `points` field
   directly (`allow update: if request.auth.uid == userId` on `users/{userId}`),
   so a child can self-award points without parental approval.

### Goals

- Parents/guardians sign in with **Sign in with Apple** and **Google** (no
  password to manage).
- Children use the app on **their own devices** with **no account** — entry is a
  **family invite code + a PIN**, nothing more.
- **Airtight points integrity**: no client (parent or child) can write points or
  approve a task directly; that happens server-side only.
- Keep an email/password path solely for **App Review**, hidden from normal users.

### Non-goals

- Migrating existing data. This is a **clean break** (see §8).
- Push notifications, Android-specific polish, or any feature work beyond auth.
- Parent custom claims (parent role stays derived from the Firestore user doc).

## 2. Identity Model

Two mechanisms, **one `users/{id}` collection** so task assignment
(`assignedToId`), family member queries (`where familyId ==`), and points display
keep working with minimal change.

| | Parents / guardians | Children |
|---|---|---|
| Auth mechanism | Firebase Auth: Apple / Google OAuth | Firebase Auth: **custom token** (uid = child profile id) |
| Account | Real identity provider | None — no email, no password, no OAuth |
| Entry | Tap "Sign in with Apple / Google" | Family invite code → pick profile → PIN |
| Role source | `users/{uid}.role` (Firestore doc) | Token claim `role: 'child'` + `familyId` |
| Email | Present | `null` |
| Session across reinstall | Provider re-login | Re-enter code + PIN (points persist on the profile, not the session) |

The child custom token is minted by a Cloud Function (see §4) as
`createCustomToken(childId, { role: 'child', familyId })`. Firebase creates the
auth user on first `signInWithCustomToken`. The token claims (`role`, `familyId`)
are read directly by security rules — no `setCustomUserClaims` round-trip needed.

From the child's point of view there is **no account**: "type the family code and
your PIN." Under the hood it is a Firebase custom-token session; we are transparent
that this exists because it is what lets a child's own device reach Firestore
securely.

## 3. Data Model Changes

- **`User.email` becomes nullable** (`Email?`). Children have no email; we do not
  fabricate one (per the "no fallbacks that hide issues" principle). Ripples to the
  `User` entity, `copyWith`, Firestore mapping, and entity tests.
- **Child profile** = a `users/{childId}` document: `role: child`, `email: null`,
  `points`, `familyId`, `name`, optional avatar. `assignedToId` on tasks already
  references a user id, so task assignment is unchanged.
- **`childCredentials/{childId}`** — a new server-only collection holding the
  **hashed** PIN (and salt, attempt counters). Security rules deny **all** client
  reads and writes; only Cloud Functions (Admin SDK, which bypasses rules) touch
  it. Field-level read hiding is not possible in Firestore, so the PIN hash must
  live in its own locked collection, never on the readable `users` doc.

## 4. Cloud Functions (Firebase, Blaze plan)

Three callable functions. All validate the caller and the target family.

1. **`createChild({ name, pin, avatar? })`** — caller must be an authenticated
   parent/guardian of a family. Generates `childId`, writes `users/{childId}`
   (role child, points 0, email null, familyId = caller's family) and
   `childCredentials/{childId}` (hashed PIN). Returns the child profile.

2. **`childSignIn({ inviteCode, childId, pin })`** — resolves `inviteCode` →
   family, verifies `childId` belongs to that family, verifies the PIN against the
   stored hash with **server-side rate limiting** (lockout after N failed
   attempts). On success returns a custom token
   `createCustomToken(childId, { role: 'child', familyId })`. The client calls
   `signInWithCustomToken`.

3. **`approveTask({ taskId })`** — caller must be a parent/guardian of the task's
   family. Atomically flips the task to `approved` **and** increments the assigned
   child's `points`. This is the only path that writes points or the `approved`
   status.

PIN hashing: a slow salted hash (bcrypt/scrypt) server-side. Rate limiting uses
attempt counters + timestamps in `childCredentials` to make a 4-digit PIN
non-brute-forceable.

Optional later helpers (not in core scope): `resetChildPin`, `deleteChild`.

## 5. Security Rules

The rules become the enforcement backbone:

- **`points` field and `approved` task status: writable only by the Admin SDK.**
  Every client write that sets `points` or transitions a task to `approved` is
  **denied**. Only `approveTask` (which bypasses rules) can do it. This closes the
  self-award gap for everyone, parent and child.
- **Children** (identified by `request.auth.token.role == 'child'` and matching
  `request.auth.token.familyId`): may read their family and its tasks; may
  transition **their own** assigned tasks `available → claimed` and
  `assigned → pendingApproval`; may **not** write any `points`, may **not** set
  `approved`, may **not** write other members' docs or `childCredentials`.
- **Parents/guardians** (role from their `users/{uid}` doc): may create/edit tasks,
  create/manage child profiles, manage the family — but still cannot client-write
  `points` or `approved` (those go through `approveTask`).
- **`childCredentials/{childId}`**: `allow read, write: if false` (server only).

## 6. UI Changes

- **Login screen**: "Sign in with Apple" + "Continue with Google" as the primary
  actions. The email/password form is removed from normal view (see §7 for the
  hidden review path and the Phase 1 exception).
- **New "Manage Children" screen** (parents): add child (name + set PIN), edit,
  remove, reset PIN. Reachable from the Family tab.
- **New kid onboarding flow** (kid's device): enter family code → tap your profile
  (avatar grid) → enter PIN. No signup form.
- The **parent/child toggle on "join family" is removed**. Everyone who signs in is
  a parent/guardian; children never "join" — a parent creates them. A family
  creator becomes `parent`; a subsequent OAuth joiner becomes `guardian`
  (both are admins).

## 7. Hidden Email/Password Path for App Review

The app requires login, so App Review needs a working demo account without an
Apple/Google identity. We keep the **email/password provider enabled** in Firebase
but expose it only through a **hidden gesture** (e.g., long-press or 7 taps on the
app logo / version label) that reveals an email+password form. A pre-created parent
demo account (with a pre-populated family + sample children and chores) is handed to
reviewers via the App Store Connect "App Review Information" notes, along with the
gesture instructions. Normal users never see it.

## 8. Migration — Clean Break

Existing accounts and family data are **discarded**. On the switchover, the live
testers (Mahmud, Alima) recreate their family via OAuth and re-add the children;
existing points and chore history are wiped. This is **destructive and
irreversible**, accepted as the simplest path given the app is still in family
beta with a handful of users. No data-migration code is written.

## 9. Sequencing — Two Shippable Phases

Ordered so nothing breaks mid-flight.

### Phase 1 — OAuth for parents (free tier, ships first, independent)

- Add `sign_in_with_apple` + `google_sign_in`; extend `AuthRepository` with
  `signInWithApple()` / `signInWithGoogle()` (+ expose `authStateChanges`).
- Firebase Console: enable Apple + Google providers. Xcode: add the **Sign in with
  Apple** capability; add the Google reversed-client-id URL scheme to `Info.plist`.
  Apple capability is auto-managed by the cloud-signing pipeline
  (`-allowProvisioningUpdates`); the App ID capability may need enabling in the
  Developer portal.
- Login screen shows Apple + Google. **Email/password stays fully visible in
  Phase 1** because children still use it — do not hide or remove it yet.
- New OAuth users with no family land in the existing create/join onboarding;
  drop the parent/child role toggle (all are parents/guardians).
- Ships to TestFlight on its own; gets Sign in with Apple through review early.

### Phase 2 — Accountless kids (Blaze plan)

- Enable **Blaze** on the Firebase project.
- Add the three Cloud Functions (§4); add the child-profile data model (§3);
  build the "Manage Children" UI and the kid onboarding flow (§6).
- Move approve→points to `approveTask`; **lock the rules** (§5) so points/approved
  are server-only.
- **Remove the visible email/password signup + login last**, only after the kid
  custom-token flow works end-to-end — leaving only the hidden review path (§7).
  This ordering guarantees children are never locked out during the transition.
- Clean-break switchover (§8); ship to TestFlight.

## 10. Testing Impact

- **Entity tests** (`user_test.dart`) change for nullable email and any role-model
  updates.
- **`MockAuthRepository`** gains OAuth methods + `authStateChanges`.
- **BDD feature tests** under `test/features/task/` encode "child is a logged-in
  user" (`i_am_logged_in_as_a_child`, `i_approve_the_task`, `points_should_be_
  awarded_to_the_child`); these are reworked so a child is a custom-token profile
  and approval/points go through `approveTask`.
- **New tests**: Cloud Functions (createChild / childSignIn PIN + rate-limit /
  approveTask authorization + atomic points); security-rules tests
  (child cannot write points or self-approve; childCredentials is unreadable);
  OAuth sign-in mapping.

## 11. Risks & Open Items

- **Blaze billing posture**: card on file; real cost ~$0/mo at family scale but no
  longer "never billed." Accepted.
- **Apple Sign in review**: requires the capability + correct entitlement; the
  hidden demo path must be reliable or review will fail on "can't create account."
- **PIN security** rests entirely on server-side hashing + rate limiting; a
  rules-only or client-side PIN check would be brute-forceable and is explicitly
  rejected.
- **Two sources of auth truth today**: `main.dart` routes off
  `FirebaseAuth.instance.authStateChanges()` directly while content uses the
  `AuthNotifier`. The redesign should consolidate on the repository/notifier so the
  child custom-token session and OAuth session are handled uniformly.
