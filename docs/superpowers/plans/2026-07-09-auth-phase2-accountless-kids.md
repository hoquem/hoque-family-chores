# Auth Phase 2 — Accountless Kids Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let children use the app on their own devices with no account — family invite code + PIN backed by a Firebase custom token — and move points/approval server-side so no device can self-award. Remove the visible email/password path (kept only as a hidden App Review entry).

**Architecture:** Add Firebase **Cloud Functions** (TypeScript) for the operations that must be trusted: `createChild`, `listChildren`, `childSignIn`, `approveTask`, `resetChildPin`/`deleteChild`. Children are Firebase Auth users created by `createChild` (uid = child profile id) with `role`/`familyId` custom claims; they sign in via a server-minted custom token. Firestore rules make `points`, task `pointValue`, and the `approved` status **server-only**, and constrain child writes to an allowlist. Requires the **Blaze** plan and **App Check**. Delivered as a clean break (existing data wiped; demo account recreated).

**Tech Stack:** Flutter + Riverpod, Firebase Auth (custom tokens + claims), Cloud Firestore + security rules, Firebase Cloud Functions (Node/TypeScript, Admin SDK), Firebase App Check, `@firebase/rules-unit-testing` + Firestore emulator for tests. Spec: `docs/superpowers/specs/2026-07-09-auth-redesign-design.md` (§3–§8).

**Reference skills:** @superpowers:test-driven-development, @superpowers:systematic-debugging, @superpowers:verification-before-completion. Consult context7 for `firebase-admin`, `firebase-functions`, `firebase_app_check`, and the Firestore rules-testing library.

**Prerequisite:** Phase 1 merged and shipped. Start on a fresh branch `feature/auth-phase2-kids`.

---

## File Structure

- **Create** `functions/` — TypeScript Cloud Functions project (`src/index.ts`, `src/createChild.ts`, `src/listChildren.ts`, `src/childSignIn.ts`, `src/approveTask.ts`, `src/childAdmin.ts`, `src/pin.ts`, `test/*`).
- **Modify** `firebase.json` — add `functions` config; keep `firestore.rules`.
- **Modify** `firestore.rules` — server-only points/pointValue/approved, role/familyId rules, child transition allowlist, `childCredentials` locked.
- **Create** `test/firestore/rules.test.js` — rules unit tests (emulator).
- **Modify** `lib/domain/entities/user.dart` — `Email? email`; collapse `UserRole` to `{ parent, child }`.
- **Modify** `lib/domain/entities/task.dart` (+ mappers) — ensure the task reward field is server-trusted (write-once); no rename.
- **Modify** `lib/domain/repositories/auth_repository.dart` + `firebase_auth_repository.dart` — `signInWithCustomToken`, child sign-out/cache-clear.
- **Create** `lib/data/functions/functions_client.dart` — typed wrappers over the callables.
- **Create** `lib/presentation/screens/manage_children_screen.dart`, `lib/presentation/screens/kid_onboarding_screen.dart`.
- **Modify** `lib/main.dart` — route off the repository's `authStateChanges` (consolidate the two auth-truth sources).
- **Modify** `lib/domain/usecases/task/approve_task_usecase.dart` — call `approveTask` function instead of client points write.
- **Modify** `lib/presentation/screens/login_screen.dart` — hidden email gesture; remove visible email/password.
- **Modify** many `.email` call sites (audit).

---

## Task 0: Enable Blaze + scaffold Cloud Functions

- [ ] **Step 1 (USER):** Upgrade the Firebase project to **Blaze** (Console → Usage & billing → Modify plan; requires a card). Confirm via `firebase projects:list` / Console.
- [ ] **Step 2:** Scaffold functions: `firebase init functions` → TypeScript, ESLint on. This creates `functions/` and adds the `functions` block to `firebase.json`. **The scaffold defaults to firebase-functions v2** — all callables in this plan use the **v2** signature `onCall((request) => …)` with `request.auth`, `request.app`, `request.data` (NOT v1's `(data, context)` / `context.auth`). Import from `firebase-functions/v2/https`.
- [ ] **Step 3:** Add deps in `functions/`: `npm i firebase-admin firebase-functions` and dev deps `npm i -D @firebase/rules-unit-testing firebase-functions-test jest ts-jest @types/jest`.
- [ ] **Step 4:** Verify emulators start: `firebase emulators:start --only functions,firestore,auth` → all three boot.
- [ ] **Step 5:** Commit `functions/` scaffold + `firebase.json`.

---

## Task 1: Domain — nullable email + collapse role enum

**Files:** `lib/domain/entities/user.dart`, `lib/domain/entities/family_member.dart`, mappers in `lib/data/repositories/firebase_user_repository.dart`, `lib/data/repositories/firebase_family_repository.dart`, `lib/presentation/widgets/task_list_tile.dart`, `lib/presentation/screens/family_screen.dart`, `lib/domain/usecases/task/approve_task_usecase.dart`, and `firestore.rules` (`me().role in ['parent','guardian']`). `test/domain/entities/user_test.dart`.

**Known `guardian` references to remove** (from grep — all must be updated, and note `firestore.rules` is NOT caught by `flutter analyze`): `family_member.dart`, `user.dart`, `firebase_user_repository.dart`, `firebase_family_repository.dart`, `task_list_tile.dart`, `family_screen.dart`, `approve_task_usecase.dart`, `firestore.rules`.

- [ ] **Step 1:** Update `user_test.dart` — expect `UserRole` values `{ parent, child }` only; expect `email` accepts `null`; `isAdmin == (role == parent)`. Run → FAIL.
- [ ] **Step 2:** In `user.dart`: change `final Email email;` → `final Email? email;` (and `copyWith`, `props`). Collapse `enum UserRole { parent, child }`; update `displayName`, `isAdmin`, remove `isGuardian`/`guardian`/`other`.
- [ ] **Step 3:** Fix the Firestore mapper (`_mapFirestoreToUser`) to read a possibly-absent email; write `null`/omit for children. Update `family_member.dart` and every grep'd `guardian` call site.
- [ ] **Step 4:** `flutter analyze` — fix every resulting error (the `.email` call-site audit from spec §3). Notably `AuthNotifier.userEmail` (`state.user!.email.value`) must null-guard. **Also update `firestore.rules`** to drop `guardian` from `me().role in ['parent','guardian']` (analyze won't flag it) — coordinate with Task 9.
- [ ] **Step 5:** Run `flutter test` → green. Commit.

---

## Task 2: Task reward is server-trusted (no rename)

**Files:** `lib/domain/entities/task.dart` (+ mapper), `lib/domain/usecases/task/approve_task_usecase.dart`, tests

The `Task` entity already carries a reward field (a `Points` value object on the task). **Keep its existing name** — it lives in the `families/{fid}/tasks` collection, distinct from the user score in `users/{uid}`, so rules disambiguate by path; a rename is unnecessary churn.

- [ ] **Step 1:** Add a test asserting the approval path derives the awarded amount from the **task's** reward field, not from a client-supplied argument. Run → FAIL if approval currently accepts a points argument.
- [ ] **Step 2:** Refactor approval to read the amount from the task doc (prep for Task 6's `approveTask` + Task 9's rules making it write-once). Commit.

---

## Task 3: Cloud Function `createChild` (pre-create auth user + claims + hashed PIN)

**Files:** `functions/src/createChild.ts`, `functions/src/pin.ts`, `functions/test/createChild.test.ts`

- [ ] **Step 1: Write the failing emulator test** — calling `createChild` as a parent creates: a Firebase Auth user with `uid = childId` and custom claims `{ role: 'child', familyId }`; a `users/{childId}` doc (`role: child`, `email: null`, `points: 0`, `familyId`); a `childCredentials/{childId}` doc with a **hashed** pin (never plaintext). Calling as a non-parent throws `permission-denied`.
- [ ] **Step 2:** Run against emulator → FAIL.
- [ ] **Step 3: Implement (firebase-functions v2).** `pin.ts` exports `hashPin(pin, salt)` (scrypt) + `makeSalt()`. `createChild.ts`:
```ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { hashPin, makeSalt } from "./pin";

export const createChild = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  const caller = await admin.firestore().doc(`users/${uid}`).get();
  if (caller.get("role") !== "parent") {
    throw new HttpsError("permission-denied", "Parents only.");
  }
  const familyId = caller.get("familyId");
  const { name, pin, avatar } = request.data;
  if (!/^\d{4,6}$/.test(pin ?? "")) {
    throw new HttpsError("invalid-argument", "PIN must be 4-6 digits.");
  }
  const childId = admin.firestore().collection("users").doc().id;
  // Pre-create the auth user so setCustomUserClaims succeeds from token #1.
  await admin.auth().createUser({ uid: childId });
  await admin.auth().setCustomUserClaims(childId, { role: "child", familyId });
  const salt = makeSalt();
  await admin.firestore().doc(`users/${childId}`).set({
    name, email: null, role: "child", points: 0, familyId,
    avatar: avatar ?? null, joinedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await admin.firestore().doc(`childCredentials/${childId}`).set({
    salt, pinHash: hashPin(pin, salt), attempts: 0, lockedUntil: 0,
  });
  return { childId };
});
```
- [ ] **Step 4:** Run test → PASS. **Step 5:** Commit.

---

## Task 4: Cloud Function `listChildren` (unauthenticated, App-Check-gated, rate-limited)

**Files:** `functions/src/listChildren.ts`, test

- [ ] **Step 1: Failing test** — given a family with children, `listChildren({inviteCode})` returns `[{childId, name, avatar}]` and nothing else (no PII, no pinHash). Unknown code → empty list / `not-found`. Enforce App Check (`context.app` present). Verify a rate-limit counter blocks after 10 calls / 10 min per App Check token.
- [ ] **Step 2:** Emulator run → FAIL.
- [ ] **Step 3: Implement** — resolve `familyInvites/{code}` → familyId; query `users where familyId == && role == 'child'`; project to `{childId, name, avatar}`. Reject when `context.app == undefined` (App Check). Keep a simple counter doc keyed by the App Check token for rate limiting.
- [ ] **Step 4:** PASS. **Step 5:** Commit.

---

## Task 5: Cloud Function `childSignIn` (verify PIN, rate-limit, mint token)

**Files:** `functions/src/childSignIn.ts`, test

- [ ] **Step 1: Failing test** — correct `{inviteCode, childId, pin}` returns a custom token string; the token, once used, yields an ID token whose claims include `role: 'child'` + the right `familyId`. Wrong PIN increments `attempts`; after 5 wrong tries in 15 min, further tries throw `resource-exhausted` even with the correct PIN until `lockedUntil` passes. Requires App Check.
- [ ] **Step 2:** Emulator run → FAIL.
- [ ] **Step 3: Implement (v2):**
```ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { hashPin } from "./pin";

// enforceAppCheck rejects calls without a valid App Check token at the platform level.
export const childSignIn = onCall({ enforceAppCheck: true }, async (request) => {
  const { inviteCode, childId, pin } = request.data;
  const invite = await admin.firestore().doc(`familyInvites/${inviteCode}`).get();
  if (!invite.exists) throw new HttpsError("not-found", "Invalid code.");
  const familyId = invite.get("familyId");
  const child = await admin.firestore().doc(`users/${childId}`).get();
  if (!child.exists || child.get("familyId") !== familyId || child.get("role") !== "child") {
    throw new HttpsError("not-found", "No such child in this family.");
  }
  const credRef = admin.firestore().doc(`childCredentials/${childId}`);
  const cred = await credRef.get();
  const now = Date.now();
  if ((cred.get("lockedUntil") ?? 0) > now) {
    throw new HttpsError("resource-exhausted", "Too many attempts. Try later.");
  }
  if (hashPin(pin, cred.get("salt")) !== cred.get("pinHash")) {
    const attempts = (cred.get("attempts") ?? 0) + 1;
    await credRef.update(attempts >= 5
      ? { attempts, lockedUntil: now + 15 * 60 * 1000 }
      : { attempts });
    throw new HttpsError("permission-denied", "Wrong PIN.");
  }
  await credRef.update({ attempts: 0, lockedUntil: 0 });
  // Claims already live on the user record (set in createChild); no extra claims needed.
  const token = await admin.auth().createCustomToken(childId);
  return { token };
});
```

**App Check test harness:** `enforceAppCheck` rejects at the platform layer, which the
Firestore/functions emulator does not fully simulate. Test the *logic* with
`firebase-functions-test` (which lets you invoke the handler with a synthetic
`request` and bypass App Check), and verify real enforcement on-device in Task 8 —
do not rely on the emulator for the App-Check success path.
- [ ] **Step 4:** PASS. **Step 5:** Commit.

---

## Task 6: Cloud Function `approveTask` (parent-only, idempotent, awards `pointValue`)

**Files:** `functions/src/approveTask.ts`, test

**Status vocabulary reminder:** the real `TaskStatus` enum is
`{available, assigned, pendingApproval, needsRevision, completed}`. "Approve" means
`pendingApproval → completed` (there is no `approved` value); "claim" writes
`assigned`; "reject/send-back" writes `needsRevision`. Use these strings, not the
spec's earlier `claimed`/`approved`/`rejected`.

- [ ] **Step 1: Failing test** — a parent approving a `pendingApproval` task flips it to `completed` (and sets `approvedBy`/`approvedAt`) and increments the assignee's user-`points` by the task's stored reward, in one transaction. A **second** call (retry / two parents) is a no-op (already `completed`). A non-parent or cross-family caller throws `permission-denied`. Client-supplied point amounts are ignored (the reward is read from the task doc).
- [ ] **Step 2:** Emulator run → FAIL.
- [ ] **Step 3: Implement** (v2 `onCall`) with `runTransaction`: read the task; assert caller is a parent of `task.familyId`; assert `status != 'completed'`; set `status = 'completed'` + `approvedBy`/`approvedAt`; `points += <task reward>` on `users/{assignedToId}`.
- [ ] **Step 4:** PASS. **Step 5:** Commit.

---

## Task 7: Cloud Functions `resetChildPin` + `deleteChild` (with token revocation)

**Files:** `functions/src/childAdmin.ts`, test

- [ ] **Step 1: Failing test** — parent `resetChildPin` re-hashes the PIN, clears lock counters, and calls `revokeRefreshTokens(childId)` so an existing child session can no longer refresh. `deleteChild` removes `users/{childId}` + `childCredentials/{childId}`, `admin.auth().deleteUser(childId)`, and revokes. Non-parent → `permission-denied`.
- [ ] **Step 2:** FAIL → **Step 3:** Implement → **Step 4:** PASS → **Step 5:** Commit.

---

## Task 8: App Check

**Files:** `lib/main.dart` (activate), Firebase Console (enforce)

- [ ] **Step 1:** Add `firebase_app_check`; activate in `main()` before other Firebase use (`AppleProvider.appAttest` on iOS; debug provider for local/dev). 
- [ ] **Step 2 (USER):** Register the app for App Check in the Console (App Attest / DeviceCheck) and set the four callables to **enforced**.
- [ ] **Step 3:** Verify a real device call to `listChildren` succeeds and a call without a valid App Check token is rejected. Commit.

---

## Task 9: Firestore rules lockdown + rules tests

**Files:** `firestore.rules`, `test/firestore/rules.test.js`

- [ ] **Step 1: Write rules tests** (`@firebase/rules-unit-testing`, emulator) asserting (using the **real** `TaskStatus` values):
  - A child token **cannot** write `users/{self}.points`, `role`, or `familyId`.
  - A child **cannot** write a task's reward field, nor set `status: 'completed'`.
  - A child **can** do the allowlisted transitions: `available→assigned` (setting `assignedToId=self`), `assigned→available`, `assigned→pendingApproval`, `needsRevision→pendingApproval` — and only touching allowlisted fields.
  - A parent **cannot** client-write user `points` or set a task `completed` (must go through `approveTask`).
  - The task reward is settable by a parent only at task **create**, never on update.
  - `familyId` writable by the owning user only when previously empty (create/join), immutable after.
  - No one can read/write `childCredentials/{childId}`.
- [ ] **Step 2:** Run `firebase emulators:exec --only firestore "npm test"` → FAIL.
- [ ] **Step 3: Implement the rules** — add `isChild()` (`request.auth.token.role == 'child'`), field-diff allowlists (`request.resource.data.diff(resource.data).affectedKeys().hasOnly([...])`), transition guards, and the immutability/write-once conditions. Deny `points`/`pointValue`/`approved` writes to all clients.
- [ ] **Step 4:** Emulator tests → PASS.
- [ ] **Step 5:** Deploy rules to production (`firebase deploy --only firestore:rules`) is deferred to Task 17 (clean-break switchover). Commit.

---

## Task 10: Client — child custom-token sign-in

**Files:** `lib/data/functions/functions_client.dart`, `auth_repository.dart` (+ Firebase impl), `auth_notifier.dart`, tests

- [ ] **Step 1:** Add `FunctionsClient` wrapping `FirebaseFunctions.instance.httpsCallable('listChildren'|'createChild'|'childSignIn'|'approveTask'|...)` with typed args/returns. Unit-test argument shaping with a mock callable.
- [ ] **Step 2:** Add `signInWithCustomToken(String token)` to `AuthRepository` (+ Firebase impl `_auth.signInWithCustomToken`). Mock in tests.
- [ ] **Step 3:** Add `AuthNotifier.childSignIn(inviteCode, childId, pin)` → `FunctionsClient.childSignIn` → `repo.signInWithCustomToken(token)` → profile stream. Test with mocks that a child session ends `authenticated` with `role: child`.
- [ ] **Step 4:** Green. Commit.

---

## Task 11: UI — Manage Children (parent)

**Files:** `lib/presentation/screens/manage_children_screen.dart`, route from Family tab, widget test

- [ ] Add child (name + 4-6 digit PIN) → `createChild`; list children with edit / reset-PIN / remove → `resetChildPin`/`deleteChild`. Widget test: submitting the add form calls `createChild` with the entered values. TDD each interaction. Commit per behavior.

---

## Task 12: UI — kid onboarding flow

**Files:** `lib/presentation/screens/kid_onboarding_screen.dart`, widget test

- [ ] Screen 1: enter family code → `listChildren`. Screen 2: avatar grid of returned children → tap one. Screen 3: PIN entry → `childSignIn`. Handle `resource-exhausted` (locked) and wrong-PIN messaging. Widget-test the happy path with mocked `FunctionsClient`. Commit per screen.

---

## Task 13: Invite-code rotation (parent)

**Files:** Family screen + `FamilyRepository`/`CreateFamilyUseCase` helpers, widget test

- [ ] **Step 1:** Failing test — rotating generates a new `families/{id}.inviteCode`, writes the new `familyInvites/{newCode}` doc, and the **old** code no longer resolves (delete or invalidate the old `familyInvites` doc).
- [ ] **Step 2:** Implement a "Regenerate invite code" action (reuse the existing 6-char generator). Note: a rotated code does not affect already-signed-in children (their session is independent of the code).
- [ ] **Step 3:** PASS. Commit.

---

## Task 14: Shared-device session switching

**Files:** kid onboarding + auth repo

- [ ] **Step 1:** Failing test — switching from Child A to Child B on one device leaves no A data readable.
- [ ] **Step 2:** Stop all Firestore listeners / dispose the profile stream (`_stopUserProfileStream`) and any per-user providers.
- [ ] **Step 3:** `await FirebaseAuth.instance.signOut()`.
- [ ] **Step 4:** `await FirebaseFirestore.instance.terminate();` then `await FirebaseFirestore.instance.clearPersistence();` (clearPersistence throws if the client is still active — terminate first), then let the SDK reinitialize on next use. Guard with try/catch and @superpowers:systematic-debugging if it throws.
- [ ] **Step 5:** PASS. Commit.

---

## Task 15: Consolidate auth routing (main.dart)

**Files:** `lib/main.dart`, a new routing provider

- [ ] **Step 1:** Add an `authStateChanges` provider that exposes the repository stream (if it's a new `@riverpod` provider, run `dart run build_runner build --delete-conflicting-outputs`).
- [ ] **Step 2:** Replace the direct `FirebaseAuth.instance.authStateChanges()` `StreamBuilder` in `main.dart` with that provider.
- [ ] **Step 3 (red/green per session):** verify cold-start routing for (a) a parent OAuth session, (b) a child custom-token session, and (c) after sign-out → login. Each is a distinct check; record each.
- [ ] **Step 4:** Commit.

---

## Task 16: Route approval through `approveTask`

**Files:** `lib/domain/usecases/task/approve_task_usecase.dart`, `lib/domain/repositories/task_repository.dart`, `lib/data/repositories/firebase_task_repository.dart`

- [ ] **Step 1:** Replace the client-side status-flip + `addPoints` in `ApproveTaskUseCase` with a call to the `approveTask` callable.
- [ ] **Step 2:** **Retire the now-unreachable client path** — the existing `FirebaseTaskRepository.approveTask` (writes `completed` + non-atomic `addPoints`) will be denied by the locked rules; remove it (and its `TaskRepository` interface method) rather than leaving a silently-failing dead path. Update callers.
- [ ] **Step 3:** Update BDD `i_approve_the_task` / `points_should_be_awarded_to_the_child` steps to go through the function (emulator).
- [ ] **Step 4:** Green. Commit.

---

## Task 17: Hidden email path; remove visible email/password

**Files:** `login_screen.dart`, `registration_screen.dart` (retire), tests. **Gate: only after Tasks 10-14 work end-to-end** (children must have their new flow first).

- [ ] **Step 1:** Widget test — normal `LoginScreen` shows only Apple/Google (no email field, no registration link). Run → FAIL.
- [ ] **Step 2:** Remove the visible email form + the "Sign Up" registration link; retire `registration_screen.dart`.
- [ ] **Step 3:** Widget test — a hidden gesture (7 taps on the version label) reveals an email/password sheet. Run → FAIL.
- [ ] **Step 4:** Implement the gesture + sheet (email/password sign-in only, for the review demo account).
- [ ] **Step 5:** Both tests green. Commit.

---

## Task 18: Clean-break switchover + recreate demo account

**Note:** this requires the Phase 2 app already installed on the testers' devices — do a local/ad-hoc or internal-TestFlight build (Task 19) reachable by you and Alima **before** wiping, and ensure the demo data exists **before** any App Store Connect submission.

- [ ] **Step 1:** Deploy functions: `firebase deploy --only functions`.
- [ ] **Step 2:** Deploy the locked rules: `firebase deploy --only firestore:rules` (functions first, so no window where rules deny an operation that has no function yet).
- [ ] **Step 3 (USER, destructive):** Wipe existing Firestore + Auth users/families data (clean break, spec §8). Confirm intent — this deletes the live family irreversibly.
- [ ] **Step 4:** Recreate the **App Review demo** parent account (email/password) with a pre-populated family + sample children/chores; update App Store Connect "App Review Information" with credentials + the hidden-gesture instructions (spec §7).
- [ ] **Step 5:** Mahmud + Alima recreate their family via OAuth; add the kids via Manage Children.

---

## Task 19: Verify + ship

- [ ] `flutter analyze` clean; `flutter test` green; `firebase emulators:exec` function + rules tests green.
- [ ] On-device end-to-end (@superpowers:verification-before-completion): parent OAuth → create family → add child; child device → code + PIN → claim/complete a chore → parent approves → child's points increment; confirm a child **cannot** self-award (attempt a direct write, expect denied). Record observed results.
- [ ] Bump build number (≥ next after Phase 1); build → upload → TestFlight per `docs/DEPLOYMENT_CHECKLIST.md`.
- [ ] PR.

---

## Done criteria (Phase 2)

- Children sign in on their own devices with code + PIN; no accounts.
- User points, the task reward field, and approval are server-only; a child device provably cannot self-award (rules test + on-device check).
- App Check enforced on all callables; PIN reset revokes sessions.
- Visible email/password gone; hidden review path works; demo account recreated post-wipe.
- Blaze active; billing ~$0/mo.
