# Managed Child Profiles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A parent can add a child who has no phone, hand their phone to that child in a child view, and later move the child onto a phone of their own with stars and history intact.

**Architecture:** A managed child is an ordinary `users/{childId}` profile with `managed: true` and no Firebase Auth user. Cloud Functions own creating, removing and linking it (custom token). On the shared phone Firebase stays signed in as the parent; `ChildModeScreen` is a pushed full-screen route that passes the child's id into the existing use cases, and `TaskDetailsScreen` / `RewardsScreen` gain an `actingAs` parameter. Treat claims and settles for the child go through the existing functions with a new `forMemberId` argument.

**Tech Stack:** Flutter 3.47.5 / Dart, Riverpod (hand-written providers only), Firebase Auth / Firestore / Cloud Functions (Node, firebase-functions v6, firebase-admin v12), Firebase emulators for server tests.

**Spec:** `docs/superpowers/specs/2026-10-26-managed-child-profiles-design.md`

**One deliberate deviation from the spec:** the spec names an `ActiveMemberNotifier`. The plan realises "who is using the phone" as the `ChildModeScreen` route itself (the route holds the child id; popping it returns to the parent). That gives the spec's behaviour (never persisted, cold start opens the parent's view, closes itself when the child is removed or linked) with no global state. Update the spec's section 2 "Active member" paragraph in Task 9.

## Global Constraints

- **build_runner is broken on this toolchain.** Never run it. Every new provider is hand-written (`Provider`, `StreamProvider`, `NotifierProvider`), placed at the bottom of `lib/di/riverpod_container.dart` or in the file that uses it. Do not add `@riverpod` annotations. Adding a method to an existing `@riverpod` class (e.g. `AuthNotifier`) is fine.
- **`points` and `managed` are server-owned.** No client code writes either field.
- **Max 10 managed children per family.** Link codes: 12 characters from `ABCDEFGHJKMNPQRSTUVWXYZ23456789`, valid 24 hours, single use, one active code per child.
- **Analytics params carry no names or free text** (children are users). Event names: `managedChildAdded`, `childModeEntered`, `linkCodeRedeemed`.
- **Copy:** "Add a child without a phone", "Hand the phone to {name}", "Move {name} to their own phone", "Remove {name}", "Back to {parent name}", "No phone", "Already in your family on a parent's phone? Use a link code."
- **Docstrings** use reStructuredText (`:param x:`, `:returns:`), matching the codebase.
- **Rules deploy:** the rules changes are safe to deploy ahead of the client (no current client writes `managed` or `profileLinks`).
- **Manual testing never touches the live family board.** Use the simulator and a throwaway family.
- **Commits:** imperative one-line summary, body explains why when not obvious, ending with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Never stage `ios/Runner.xcodeproj/project.pbxproj` (pre-existing unrelated change).

## Commands

- Server tests: `cd test/rules && npm run test:managed` (rules) and `npm run test:managedFunctions` (functions + auth + firestore emulators). Existing suite to keep green: `npm run test:functions`, `npm test`.
- Dart: `flutter test <path>`; full suite `flutter test`; analyzer `flutter analyze`.

## File Map

**Server**
- Create `functions/managedChildren.js`: all managed-child server logic (add, remove, link codes, act-for check, last-adult cleanup, linked flip). Pure module taking `db`/`auth`, like `memberCleanup.js`.
- Modify `functions/index.js`: thin callables/triggers wiring the module; `forMemberId` in `claimReward` and `settleRedemption`; last-adult cleanup in `onAuthUserDeleted`.
- Modify `firestore.rules`: `managed` immutable for clients; `profileLinks` closed.
- Create `test/rules/managed_lock.test.mjs` (rules), `test/rules/managed_child.test.mjs` (functions). Modify `test/rules/package.json`, `test/rules/README.md`.

**Dart domain/data**
- Modify `lib/domain/entities/user.dart`: `isManaged`.
- Modify `lib/data/repositories/firebase_user_repository.dart`, `lib/data/repositories/firebase_family_repository.dart`: map `managed`.
- Create `lib/data/services/callable.dart`: shared callable + error mapping (extracted from `EconomyFunctions`).
- Modify `lib/data/services/economy_functions.dart`: use `callable.dart`; `forMemberId`.
- Modify `lib/domain/repositories/reward_repository.dart`, `lib/data/repositories/firebase_reward_repository.dart`, `test/mocks/mock_reward_repository.dart`: `forMemberId`.
- Create `lib/domain/repositories/managed_child_repository.dart`, `lib/data/services/managed_child_functions.dart`, `test/mocks/mock_managed_child_repository.dart`.
- Modify `lib/domain/repositories/auth_repository.dart`, `lib/data/repositories/firebase_auth_repository.dart`, `test/mocks/mock_auth_repository.dart`: `signInWithCustomToken`.
- Create `lib/domain/services/managed_child_policy.dart`.
- Create `lib/domain/usecases/family/add_managed_child_usecase.dart`, `lib/domain/usecases/family/link_child_device_usecase.dart`.
- Modify `lib/domain/usecases/family/leave_family_usecase.dart`, `lib/domain/usecases/reward/claim_reward_usecase.dart`, `lib/domain/usecases/reward/settle_redemption_usecase.dart`.
- Modify `lib/di/riverpod_container.dart`: hand-written providers.
- Modify `lib/core/analytics/analytics.dart`: three events.

**Dart presentation**
- Modify `lib/presentation/screens/task_details_screen.dart`, `lib/presentation/screens/rewards_screen.dart`, `lib/presentation/providers/riverpod/rewards_notifier.dart`: `actingAs` / on-behalf refunds.
- Create `lib/presentation/screens/child_mode_screen.dart`.
- Create `lib/presentation/widgets/add_managed_child_sheet.dart`.
- Modify `lib/presentation/screens/invite_your_family_screen.dart`, `lib/presentation/widgets/home/invite_family_card.dart`, `lib/presentation/screens/home_screen.dart`, `lib/presentation/screens/family_screen.dart`, `lib/presentation/screens/member_detail_screen.dart`.
- Create `lib/presentation/screens/link_child_device_screen.dart`; modify `lib/presentation/screens/child_join_screen.dart`, `lib/presentation/providers/riverpod/auth_notifier.dart`.
- Modify `scripts/usage_report.py`.

---

### Task 1: Firestore rules lock `managed` and close `profileLinks`

**Files:**
- Modify: `firestore.rules` (users `create` and `update` rules near lines 28-58; add a `profileLinks` match block after `familyInvites`)
- Create: `test/rules/managed_lock.test.mjs`
- Modify: `test/rules/package.json`, `test/rules/README.md`

**Interfaces:**
- Produces: clients can never write `managed`; no client access to `profileLinks/{code}`.

- [ ] **Step 1: Write the failing rules test**

`test/rules/managed_lock.test.mjs`:

```js
// `managed` marks a child profile with no sign-in of its own. Only the Cloud
// Functions may set or clear it: a client that could flip it could make
// itself a link-code target, or strip a managed child of the parent's
// on-behalf protections. `profileLinks` holds live link codes, which are
// bearer credentials for a child's account, so no client may touch them.
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

const RULES = fileURLToPath(new URL('../../firestore.rules', import.meta.url));

const testEnv = await initializeTestEnvironment({
  projectId: 'demo-hoque',
  firestore: { rules: readFileSync(RULES, 'utf8'), host: '127.0.0.1', port: 8080 },
});

await testEnv.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, 'users/alice'), { familyId: 'famA', role: 'parent', points: 0, name: 'Alice' });
  await setDoc(doc(db, 'users/kid'), { familyId: 'famA', role: 'child', points: 0, name: 'Kid', managed: true });
  await setDoc(doc(db, 'families/famA'), { memberIds: ['alice', 'kid'], creatorId: 'alice' });
  await setDoc(doc(db, 'profileLinks/ABCDEFGHJKMN'), { childId: 'kid', familyId: 'famA' });
});

const alice = testEnv.authenticatedContext('alice').firestore();
const newbie = testEnv.authenticatedContext('newbie').firestore();

let pass = 0, fail = 0;
async function check(name, promise, shouldSucceed) {
  try {
    await (shouldSucceed ? assertSucceeds(promise) : assertFails(promise));
    console.log(`  ok   ${name}`);
    pass++;
  } catch (e) {
    console.log(`  FAIL ${name} :: ${e.message}`);
    fail++;
  }
}

console.log('\n-- managed is server-owned --');
await check('signing up with managed: true is rejected',
  setDoc(doc(newbie, 'users/newbie'), { familyId: '', role: 'child', points: 0, managed: true }), false);
await check('signing up without managed still works',
  setDoc(doc(newbie, 'users/newbie'), { familyId: '', role: 'child', points: 0 }), true);
await check('a parent CANNOT clear managed on a family child',
  updateDoc(doc(alice, 'users/kid'), { managed: false }), false);
await check('a user CANNOT set managed on themselves',
  updateDoc(doc(alice, 'users/alice'), { managed: true }), false);
await check('a parent CAN still rename a managed child',
  updateDoc(doc(alice, 'users/kid'), { name: 'Kiddo' }), true);
await check('a family member CAN read a managed child',
  getDoc(doc(alice, 'users/kid')), true);

console.log('\n-- profileLinks are closed to every client --');
await check('a parent CANNOT read a link code',
  getDoc(doc(alice, 'profileLinks/ABCDEFGHJKMN')), false);
await check('a parent CANNOT write a link code',
  setDoc(doc(alice, 'profileLinks/ZZZZZZZZZZZZ'), { childId: 'kid', familyId: 'famA' }), false);

console.log(`\n${pass} passed, ${fail} failed`);
await testEnv.cleanup();
process.exit(fail > 0 ? 1 : 0);
```

Add to `test/rules/package.json` `scripts`:

```json
"test:managed": "firebase emulators:exec --only firestore --project demo-hoque \"node managed_lock.test.mjs\"",
```

and append ` && npm run test:managed` to the end of the `"test"` script.

- [ ] **Step 2: Run it and watch it fail**

Run: `cd test/rules && npm run test:managed`
Expected: FAIL on "signing up with managed: true is rejected", "a parent CANNOT clear managed", "a user CANNOT set managed", "a parent CANNOT read a link code", "a parent CANNOT write a link code".

- [ ] **Step 3: Change the rules**

In `match /users/{userId}`, extend `allow create` with one more conjunct:

```
      allow create: if isSignedIn() && request.auth.uid == userId
        && (!('points' in request.resource.data)
            || request.resource.data.points == 0)
        && (!('familyId' in request.resource.data)
            || request.resource.data.familyId == '')
        // `managed` (a child with no sign-in of their own) is set only by the
        // addManagedChild Cloud Function.
        && !('managed' in request.resource.data);
```

and add a line right after `request.resource.data.points == resource.data.points` in `allow update`:

```
      allow update: if isSignedIn()
        && request.resource.data.points == resource.data.points
        // Only the Cloud Functions set or clear `managed`: it decides who a
        // link code may sign in as, and who a parent may act for.
        && request.resource.data.get('managed', false) == resource.data.get('managed', false)
        && ((request.auth.uid == userId
```

(leave the rest of the rule unchanged). Then, after the `familyInvites` block, add:

```
    // Live link codes for moving a managed child onto their own phone. A code
    // is a bearer credential for the child's account, so only the Cloud
    // Functions (admin) read or write these.
    match /profileLinks/{code} {
      allow read, write: if false;
    }
```

Update the comment above `allow update` that lists the locked-down fields to mention `managed`.

- [ ] **Step 4: Run the new suite and the existing rules suites**

Run: `cd test/rules && npm run test:managed && npm test`
Expected: `managed_lock`: 8 passed, 0 failed. All other suites unchanged (0 failed).

- [ ] **Step 5: Document and commit**

Add a row to the table in `test/rules/README.md`:

```
| `managed_lock` | No client sets or clears `managed`, and no client reads or writes `profileLinks`; renaming a managed child still works. |
```

```bash
git add firestore.rules test/rules/managed_lock.test.mjs test/rules/package.json test/rules/README.md
git commit -m "Lock managed profiles and link codes to the server" -m "Managed child profiles and their link codes are created and changed only by Cloud Functions; a client that could flip managed could make itself a link-code target." -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: `addManagedChild` and `removeManagedChild` functions

**Files:**
- Create: `functions/managedChildren.js`
- Modify: `functions/index.js` (require the module; export two callables next to `approveTask`)
- Create: `test/rules/managed_child.test.mjs`
- Modify: `test/rules/package.json`

**Interfaces:**
- Produces (module, used by Tasks 3-4):
  - `MAX_MANAGED_CHILDREN = 10`
  - `requireAdultIn(tx, db, uid, familyId) -> Promise<object>` (caller profile data; throws `permission-denied`)
  - `requireManagedChildIn(tx, db, childId, familyId) -> Promise<object>` (child profile data; throws `not-found`)
  - `addManagedChild(db, uid, { familyId, name }) -> Promise<{ childId }>`
  - `removeManagedChild(db, uid, { familyId, childId }) -> Promise<void>`
  - `releaseManagedChild(db, childId) -> Promise<void>` (release + delete link codes + delete profile; no auth checks)
- Produces (callables): `addManagedChild({familyId, name}) -> {childId}`, `removeManagedChild({familyId, childId}) -> {ok: true}`

- [ ] **Step 1: Write the failing functions test**

`test/rules/managed_child.test.mjs` (Tasks 3 and 4 append sections to this file before the final summary block):

```js
// Managed child profiles: a child with no phone of their own, added by a
// parent, used on the parent's phone, and later linked to their own phone.
// Runs against the functions + firestore + auth emulators.
import adminPkg from 'firebase-admin';
import { initializeApp } from 'firebase/app';
import { getAuth, connectAuthEmulator, signInWithCustomToken, signOut } from 'firebase/auth';
import { getFunctions, connectFunctionsEmulator, httpsCallable } from 'firebase/functions';

const PROJECT = 'demo-hoque';
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';

adminPkg.initializeApp({ projectId: PROJECT });
const adb = adminPkg.firestore();
const aauth = adminPkg.auth();

for (const uid of ['mum', 'dad', 'teen', 'otherMum']) {
  await aauth.createUser({ uid }).catch(() => {});
}
await adb.doc('users/mum').set({ familyId: 'famA', role: 'parent', points: 0, name: 'Mum' });
await adb.doc('users/dad').set({ familyId: 'famA', role: 'guardian', points: 0, name: 'Dad' });
await adb.doc('users/teen').set({ familyId: 'famA', role: 'child', points: 0, name: 'Teen' });
await adb.doc('users/otherMum').set({ familyId: 'famB', role: 'parent', points: 0, name: 'Other' });
await adb.doc('families/famA').set({ memberIds: ['mum', 'dad', 'teen'], creatorId: 'mum' });
await adb.doc('families/famB').set({ memberIds: ['otherMum'], creatorId: 'otherMum' });

const app = initializeApp({ projectId: PROJECT, apiKey: 'fake-api-key' });
const auth = getAuth(app);
connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
const functions = getFunctions(app);
connectFunctionsEmulator(functions, '127.0.0.1', 5001);

async function callAs(uid, name, data) {
  const token = await aauth.createCustomToken(uid);
  await signInWithCustomToken(auth, token);
  return httpsCallable(functions, name)(data);
}
async function callSignedOut(name, data) {
  await signOut(auth);
  return httpsCallable(functions, name)(data);
}
const profile = async (uid) => (await adb.doc(`users/${uid}`).get()).data();
const exists = async (path) => (await adb.doc(path).get()).exists;
const memberIds = async (fid) => (await adb.doc(`families/${fid}`).get()).data().memberIds;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function waitFor(pred, ms = 20000) {
  const end = Date.now() + ms;
  while (Date.now() < end) { if (await pred()) return true; await sleep(250); }
  return false;
}

let pass = 0, fail = 0;
async function expectOk(name, promise) {
  try { const r = await promise; console.log(`  ok   ${name}`); pass++; return r; }
  catch (e) { console.log(`  FAIL ${name} :: ${e.code || e.message}`); fail++; return null; }
}
async function expectFail(name, code, promise) {
  try { await promise; console.log(`  FAIL ${name} :: expected error ${code}, succeeded`); fail++; }
  catch (e) {
    if (String(e.code).includes(code)) { console.log(`  ok   ${name} (${e.code})`); pass++; }
    else { console.log(`  FAIL ${name} :: got ${e.code}, wanted ${code}`); fail++; }
  }
}
async function expectEq(name, actual, expected) {
  const a = await actual;
  if (a === expected) { console.log(`  ok   ${name} (=${a})`); pass++; }
  else { console.log(`  FAIL ${name} :: got ${a}, wanted ${expected}`); fail++; }
}

console.log('\n-- addManagedChild --');
const added = await expectOk('a parent adds a child without a phone',
  callAs('mum', 'addManagedChild', { familyId: 'famA', name: '  Amira  ' }));
const amira = added?.data?.childId;
await expectEq('the child profile is managed', (async () => (await profile(amira)).managed)(), true);
await expectEq('the child profile is a child', (async () => (await profile(amira)).role)(), 'child');
await expectEq('the name is trimmed', (async () => (await profile(amira)).name)(), 'Amira');
await expectEq('the child starts with 0 stars', (async () => (await profile(amira)).points)(), 0);
await expectEq('the child is on the roster', (async () => (await memberIds('famA')).includes(amira))(), true);
await expectEq('no auth user exists for the child',
  aauth.getUser(amira).then(() => true, () => false), false);
await expectOk('a guardian can add one too',
  callAs('dad', 'addManagedChild', { familyId: 'famA', name: 'Zayn' }));
await expectFail('a child cannot add one', 'permission-denied',
  callAs('teen', 'addManagedChild', { familyId: 'famA', name: 'X' }));
await expectFail("another family's parent cannot add one", 'permission-denied',
  callAs('otherMum', 'addManagedChild', { familyId: 'famA', name: 'X' }));
await expectFail('a blank name is refused', 'invalid-argument',
  callAs('mum', 'addManagedChild', { familyId: 'famA', name: '   ' }));

console.log('\n-- the 10-child cap --');
for (let i = 0; i < 8; i++) {
  await callAs('mum', 'addManagedChild', { familyId: 'famA', name: `Kid ${i}` });
}
await expectFail('an eleventh managed child is refused', 'failed-precondition',
  callAs('mum', 'addManagedChild', { familyId: 'famA', name: 'One too many' }));

console.log('\n-- removeManagedChild --');
await adb.doc('families/famA/tasks/amiraChore').set({ title: 'tidy', status: 'assigned', assignedToId: amira, points: 5 });
const zaynId = (await adb.collection('users').where('name', '==', 'Zayn').get()).docs[0].id;
await expectFail('a child cannot remove one', 'permission-denied',
  callAs('teen', 'removeManagedChild', { familyId: 'famA', childId: zaynId }));
await expectFail('a signed-in member who is not managed cannot be removed this way', 'not-found',
  callAs('mum', 'removeManagedChild', { familyId: 'famA', childId: 'teen' }));
await expectOk('a parent removes a managed child',
  callAs('mum', 'removeManagedChild', { familyId: 'famA', childId: zaynId }));
await expectEq('the profile is gone', exists(`users/${zaynId}`), false);
await expectEq('the child is off the roster', (async () => (await memberIds('famA')).includes(zaynId))(), false);
await expectEq('the teen is untouched', exists('users/teen'), true);

// --- Task 3 and Task 4 sections go here ---

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail > 0 ? 1 : 0);
```

Add to `test/rules/package.json` `scripts`:

```json
"test:managedFunctions": "firebase emulators:exec --only functions,firestore,auth --project demo-hoque \"node managed_child.test.mjs\"",
```

- [ ] **Step 2: Run it and watch it fail**

Run: `cd test/rules && npm run test:managedFunctions`
Expected: FAIL on the first call with `not-found` / `internal` (function does not exist).

- [ ] **Step 3: Write the module**

`functions/managedChildren.js`:

```js
// Managed child profiles: a child with no phone of their own. The profile is
// an ordinary users/{childId} doc with `managed: true` and no auth user, so
// chores, stars, the leaderboard and approveTask treat it like any member.
// Everything that creates, removes, links or acts for one lives here, on the
// trusted server; the Firestore rules forbid clients from touching `managed`
// or `profileLinks`. Pure module: takes db/auth, never calls initializeApp.
const { HttpsError } = require('firebase-functions/v2/https');
const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const { randomInt } = require('crypto');
const { releaseDeletedMember } = require('./memberCleanup');

const MAX_MANAGED_CHILDREN = 10;
const MAX_NAME_LENGTH = 50;

const isAdultRole = (role) => role === 'parent' || role === 'guardian';

/**
 * Read the caller's profile and require a parent or guardian in ``familyId``.
 *
 * :param tx: the running transaction (all reads go through it).
 * :param db: Firestore admin instance.
 * :param uid: the caller's uid.
 * :param familyId: the family the call acts on.
 * :returns: the caller's profile data.
 */
async function requireAdultIn(tx, db, uid, familyId) {
  const snap = await tx.get(db.doc(`users/${uid}`));
  if (!snap.exists) throw new HttpsError('permission-denied', 'No profile found.');
  const me = snap.data();
  if (me.familyId !== familyId || !isAdultRole(me.role)) {
    throw new HttpsError('permission-denied', 'Only a parent or guardian in this family can do that.');
  }
  return me;
}

/**
 * Read ``childId`` and require a managed child of ``familyId``.
 *
 * :returns: the child's profile data.
 */
async function requireManagedChildIn(tx, db, childId, familyId) {
  const snap = await tx.get(db.doc(`users/${childId}`));
  const child = snap.exists ? snap.data() : null;
  if (!child || child.managed !== true || child.familyId !== familyId) {
    throw new HttpsError('not-found', "That child isn't in this family without a phone any more.");
  }
  return child;
}

/**
 * Create a managed child profile and add it to the family roster, atomically.
 *
 * :param db: Firestore admin instance.
 * :param uid: the calling parent or guardian.
 * :param args: ``{ familyId, name }``.
 * :returns: ``{ childId }``.
 */
async function addManagedChild(db, uid, { familyId, name }) {
  const trimmed = String(name || '').trim();
  if (!trimmed) throw new HttpsError('invalid-argument', 'Please enter a name.');
  if (trimmed.length > MAX_NAME_LENGTH) {
    throw new HttpsError('invalid-argument', 'That name is too long.');
  }
  const familyRef = db.doc(`families/${familyId}`);
  const childRef = db.collection('users').doc();
  await db.runTransaction(async (tx) => {
    await requireAdultIn(tx, db, uid, familyId);
    const family = await tx.get(familyRef);
    if (!family.exists) throw new HttpsError('not-found', 'Family not found.');
    const existing = await tx.get(
      db.collection('users').where('familyId', '==', familyId).where('managed', '==', true),
    );
    if (existing.size >= MAX_MANAGED_CHILDREN) {
      throw new HttpsError(
        'failed-precondition',
        `A family can have up to ${MAX_MANAGED_CHILDREN} children without a phone.`,
      );
    }
    const now = Timestamp.now();
    tx.set(childRef, {
      name: trimmed,
      role: 'child',
      familyId,
      points: 0,
      managed: true,
      createdBy: uid,
      joinedAt: now,
      updatedAt: now,
    });
    tx.update(familyRef, { memberIds: FieldValue.arrayUnion(childRef.id) });
  });
  return { childId: childRef.id };
}

/**
 * Release a managed child's chores and roster place, delete any link code
 * for them, then delete the profile. No permission checks: callers check.
 *
 * Order matters for a retry: the profile goes last, so a run that dies part
 * way leaves a profile the caller's checks still accept, and every step
 * before it is idempotent.
 */
async function releaseManagedChild(db, childId) {
  await releaseDeletedMember(db, childId);
  const codes = await db.collection('profileLinks').where('childId', '==', childId).get();
  await Promise.all(codes.docs.map((d) => d.ref.delete()));
  await db.doc(`users/${childId}`).delete();
}

/**
 * Remove a managed child from their family for good.
 *
 * :param args: ``{ familyId, childId }``.
 */
async function removeManagedChild(db, uid, { familyId, childId }) {
  await db.runTransaction(async (tx) => {
    await requireAdultIn(tx, db, uid, familyId);
    await requireManagedChildIn(tx, db, childId, familyId);
  });
  await releaseManagedChild(db, childId);
}

module.exports = {
  MAX_MANAGED_CHILDREN,
  isAdultRole,
  requireAdultIn,
  requireManagedChildIn,
  addManagedChild,
  removeManagedChild,
  releaseManagedChild,
};
```

- [ ] **Step 4: Wire the callables**

In `functions/index.js`, after the `require('./choreGuide')` line add:

```js
const managed = require('./managedChildren');
```

and after the `approveTask` export add:

```js
// Managed children: a child with no phone, added by a parent. See
// functions/managedChildren.js and
// docs/superpowers/specs/2026-10-26-managed-child-profiles-design.md.
exports.addManagedChild = onCall(async (request) => {
  const uid = requireAuth(request);
  const { familyId } = requireArgs(request.data, ['familyId']);
  return managed.addManagedChild(db, uid, { familyId, name: request.data.name });
});

exports.removeManagedChild = onCall(async (request) => {
  const uid = requireAuth(request);
  const { familyId, childId } = requireArgs(request.data, ['familyId', 'childId']);
  await managed.removeManagedChild(db, uid, { familyId, childId });
  return { ok: true };
});
```

(`name` is passed through un-required so a blank name reaches the module's friendly `invalid-argument` message.)

- [ ] **Step 5: Run the test and see it pass**

Run: `cd test/rules && npm run test:managedFunctions`
Expected: all checks `ok`, `0 failed`.

- [ ] **Step 6: Keep the existing economy suite green**

Run: `cd test/rules && npm run test:functions`
Expected: `0 failed`.

- [ ] **Step 7: Commit**

```bash
git add functions/managedChildren.js functions/index.js test/rules/managed_child.test.mjs test/rules/package.json
git commit -m "Add Cloud Functions to add and remove a child without a phone" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Claim and settle treats on a managed child's behalf (`forMemberId`)

**Files:**
- Modify: `functions/managedChildren.js` (add `requireMayActFor`)
- Modify: `functions/index.js` (`claimReward`, `settleRedemption`)
- Modify: `test/rules/managed_child.test.mjs` (append a section)

**Interfaces:**
- Consumes: `requireAdultIn`, `requireManagedChildIn` (Task 2).
- Produces: `requireMayActFor(tx, db, uid, memberId, familyId)`; callables `claimReward({familyId, rewardId, forMemberId?})` and `settleRedemption({familyId, redemptionId, happened, forMemberId?})`. Redemption docs gain `claimedVia` (caller uid) when claimed on behalf.

- [ ] **Step 1: Append the failing tests**

Insert before the `// --- Task 3 and Task 4 sections go here ---` marker:

```js
console.log('\n-- forMemberId: claim and settle for a managed child --');
await adb.doc(`users/${amira}`).update({ points: 50 });
await adb.doc('families/famA/rewards/park').set({ title: 'park', cost: 20, timeframe: 'openEnded', createdBy: 'mum' });
await expectFail('a child cannot claim for a managed child', 'permission-denied',
  callAs('teen', 'claimReward', { familyId: 'famA', rewardId: 'park', forMemberId: amira }));
await expectFail("another family's parent cannot claim for her", 'permission-denied',
  callAs('otherMum', 'claimReward', { familyId: 'famA', rewardId: 'park', forMemberId: amira }));
await expectFail('a parent cannot claim for a signed-in child', 'not-found',
  callAs('mum', 'claimReward', { familyId: 'famA', rewardId: 'park', forMemberId: 'teen' }));
const claim = await expectOk('a parent claims for the managed child',
  callAs('mum', 'claimReward', { familyId: 'famA', rewardId: 'park', forMemberId: amira }));
const claimId = claim?.data?.redemptionId;
await expectEq('the child paid 20 (50 -> 30)', (async () => (await profile(amira)).points)(), 30);
await expectEq("the parent's stars are untouched", (async () => (await profile('mum')).points)(), 0);
const redPath = `families/famA/redemptions/${claimId}`;
await expectEq('claimedBy is the child', (async () => (await adb.doc(redPath).get()).data().claimedBy)(), amira);
await expectEq('claimedVia is the parent', (async () => (await adb.doc(redPath).get()).data().claimedVia)(), 'mum');
await expectFail('settling without forMemberId is refused (the parent did not claim it)', 'permission-denied',
  callAs('mum', 'settleRedemption', { familyId: 'famA', redemptionId: claimId, happened: false }));
await expectOk('a parent refunds it for the child',
  callAs('dad', 'settleRedemption', { familyId: 'famA', redemptionId: claimId, happened: false, forMemberId: amira }));
await expectEq('the child got 20 back (30 -> 50)', (async () => (await profile(amira)).points)(), 50);
await expectEq('the parent still has 0', (async () => (await profile('mum')).points)(), 0);
```

- [ ] **Step 2: Run and watch the new checks fail**

Run: `cd test/rules && npm run test:managedFunctions`
Expected: "a child cannot claim for a managed child" fails (the claim succeeds against the teen's own balance) or other new checks fail; Task 2 checks still pass.

- [ ] **Step 3: Add `requireMayActFor` to the module**

In `functions/managedChildren.js`, add before `module.exports`, and export it:

```js
/**
 * Require that ``uid`` may act for ``memberId`` on the shared phone: a parent
 * or guardian in ``familyId`` acting for a managed child of that family.
 */
async function requireMayActFor(tx, db, uid, memberId, familyId) {
  await requireAdultIn(tx, db, uid, familyId);
  await requireManagedChildIn(tx, db, memberId, familyId);
}
```

- [ ] **Step 4: Change `claimReward`**

In `functions/index.js` `exports.claimReward`, replace:

```js
  const claimerRef = db.doc(`users/${uid}`);
```

with:

```js
  // On the shared phone a parent claims for a managed child (a child with no
  // phone of their own); the stars and the claim are the child's.
  const forMemberId = request.data && request.data.forMemberId;
  const claimerId = forMemberId || uid;
  const claimerRef = db.doc(`users/${claimerId}`);
```

Inside the transaction, as the first statement:

```js
    if (forMemberId) await managed.requireMayActFor(tx, db, uid, forMemberId, familyId);
```

and in the `tx.set(redemptionRef, {...})` object replace `claimedBy: uid,` with:

```js
      claimedBy: claimerId,
      ...(forMemberId ? { claimedVia: uid } : {}),
```

Leave `notifyFamily(familyId, uid, ...)` as is: the caller is the one holding the phone, so they are the one not to notify.

- [ ] **Step 5: Change `settleRedemption`**

In `exports.settleRedemption`, replace:

```js
  const settlerRef = db.doc(`users/${uid}`);
```

with:

```js
  const forMemberId = request.data && request.data.forMemberId;
  const settlerId = forMemberId || uid;
  const settlerRef = db.doc(`users/${settlerId}`);
```

Inside the transaction, as the first statement:

```js
    if (forMemberId) await managed.requireMayActFor(tx, db, uid, forMemberId, familyId);
```

Replace `if (r.claimedBy !== uid) {` with `if (r.claimedBy !== settlerId) {`, and in the trailing `notify(uid, ...)` call replace the first argument `uid` with `settlerId`.

- [ ] **Step 6: Run both functions suites**

Run: `cd test/rules && npm run test:managedFunctions && npm run test:functions`
Expected: both `0 failed`.

- [ ] **Step 7: Commit**

```bash
git add functions/managedChildren.js functions/index.js test/rules/managed_child.test.mjs
git commit -m "Let a parent claim and settle treats for a child without a phone" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Link codes, the linked flip, and last-adult cleanup

**Files:**
- Modify: `functions/managedChildren.js`
- Modify: `functions/index.js` (two callables, `onAuthUserCreated`, `onAuthUserDeleted`)
- Modify: `test/rules/managed_child.test.mjs` (append)

**Interfaces:**
- Produces (module): `newLinkCode() -> string`, `createLinkCode(db, uid, {familyId, childId}) -> {code, expiresAt}` (`expiresAt` in epoch ms), `redeemLinkCode(db, auth, {code}) -> {token}`, `markLinked(db, uid) -> Promise<void>`, `removeOrphanedManagedChildren(db, familyIds) -> Promise<number>`.
- Produces (callables/triggers): `createLinkCode`, `redeemLinkCode` (no auth required), `onAuthUserCreated`; `onAuthUserDeleted` additionally removes managed children of families left with no adult.
- Error contract the app relies on (Task 7 shows these messages verbatim): unknown or used code: `not-found` "That code didn't work. Check it, or ask a parent for a new one."; expired: `failed-precondition` "This code has expired. Ask a parent for a new one."; child removed or already linked: `failed-precondition` "This code is no longer valid. Ask a parent for a new one."

- [ ] **Step 1: Append the failing tests**

Insert before the `// --- Task 3 and Task 4 sections go here ---` marker:

```js
console.log('\n-- link codes --');
await expectFail('a child cannot make a link code', 'permission-denied',
  callAs('teen', 'createLinkCode', { familyId: 'famA', childId: amira }));
const first = await expectOk('a parent makes a link code',
  callAs('mum', 'createLinkCode', { familyId: 'famA', childId: amira }));
const second = await expectOk('making another replaces it',
  callAs('mum', 'createLinkCode', { familyId: 'famA', childId: amira }));
const code1 = first?.data?.code;
const code2 = second?.data?.code;
await expectEq('the code is 12 characters', code2?.length, 12);
await expectEq('the code expires in about 24h',
  Math.round((second?.data?.expiresAt - Date.now()) / 3600000), 24);
await expectFail('the replaced code no longer works', 'not-found',
  callSignedOut('redeemLinkCode', { code: code1 }));
await adb.doc(`profileLinks/${code2}`).update({ expiresAt: adminPkg.firestore.Timestamp.fromMillis(Date.now() - 1000) });
await expectFail('an expired code is refused', 'failed-precondition',
  callSignedOut('redeemLinkCode', { code: code2 }));

const live = await callAs('mum', 'createLinkCode', { familyId: 'famA', childId: amira });
const spaced = `${live.data.code.slice(0, 4)} ${live.data.code.slice(4, 8)}-${live.data.code.slice(8)}`.toLowerCase();
const redeemed = await expectOk('the child redeems it signed out, spaced and lower-case',
  callSignedOut('redeemLinkCode', { code: spaced }));
await expectEq('the code is used up', exists(`profileLinks/${live.data.code}`), false);
await expectEq('still managed until the phone actually signs in',
  (async () => (await profile(amira)).managed)(), true);
await signInWithCustomToken(auth, redeemed.data.token);
await expectEq('the phone is signed in as the child', auth.currentUser?.uid, amira);
await expectEq('onAuthUserCreated clears managed',
  waitFor(async () => (await profile(amira)).managed === false), true);
await expectEq('her stars came with her', (async () => (await profile(amira)).points)(), 50);
await expectFail('a linked child can no longer get a code', 'not-found',
  callAs('mum', 'createLinkCode', { familyId: 'famA', childId: amira }));

console.log('\n-- the last adult deletes their account --');
await aauth.createUser({ uid: 'soloMum' }).catch(() => {});
await adb.doc('users/soloMum').set({ familyId: 'famC', role: 'parent', points: 0, name: 'Solo' });
await adb.doc('families/famC').set({ memberIds: ['soloMum'], creatorId: 'soloMum' });
const soloKid = (await callAs('soloMum', 'addManagedChild', { familyId: 'famC', name: 'Solo kid' })).data.childId;
// The app deletes the profile first, then the auth user (see onAuthUserDeleted).
await adb.doc('users/soloMum').delete();
await aauth.deleteUser('soloMum');
await expectEq('the orphaned managed child is removed',
  waitFor(async () => !(await exists(`users/${soloKid}`))), true);

console.log('\n-- a family that still has an adult keeps its managed children --');
const keepKid = (await callAs('mum', 'addManagedChild', { familyId: 'famA', name: 'Keep' })).data.childId;
await adb.doc('users/dad').delete();
await aauth.deleteUser('dad');
await sleep(4000); // let onAuthUserDeleted run
await expectEq('mum is still there, so the child stays', exists(`users/${keepKid}`), true);
```

- [ ] **Step 2: Run and watch them fail**

Run: `cd test/rules && npm run test:managedFunctions`
Expected: FAIL from "a child cannot make a link code" onwards (functions missing).

- [ ] **Step 3: Add link codes and cleanup to the module**

In `functions/managedChildren.js`, add (and export every new name):

```js
const LINK_CODE_TTL_MS = 24 * 60 * 60 * 1000;
// Same alphabet and length as family invite codes (create_family_usecase.dart):
// no 0/O, 1/I/L, so a code read aloud survives the trip.
const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const CODE_LENGTH = 12;

function newLinkCode() {
  let code = '';
  for (let i = 0; i < CODE_LENGTH; i++) code += CODE_ALPHABET[randomInt(CODE_ALPHABET.length)];
  return code;
}

// Mirrors normaliseInviteCode in join_family_usecase.dart: spaces, dashes and
// case are how people write a long code down, not a different code.
const normaliseCode = (raw) => String(raw || '').toUpperCase().replace(/[^A-Z0-9]/g, '');

/**
 * Mint a one-time code that moves a managed child onto their own phone,
 * replacing any earlier code for that child.
 *
 * :returns: ``{ code, expiresAt }`` with ``expiresAt`` in epoch milliseconds.
 */
async function createLinkCode(db, uid, { familyId, childId }) {
  const code = newLinkCode();
  const expiresAt = Timestamp.fromMillis(Date.now() + LINK_CODE_TTL_MS);
  await db.runTransaction(async (tx) => {
    await requireAdultIn(tx, db, uid, familyId);
    await requireManagedChildIn(tx, db, childId, familyId);
    const old = await tx.get(db.collection('profileLinks').where('childId', '==', childId));
    for (const d of old.docs) tx.delete(d.ref);
    tx.set(db.doc(`profileLinks/${code}`), { childId, familyId, createdBy: uid, expiresAt });
  });
  return { code, expiresAt: expiresAt.toMillis() };
}

/**
 * Spend a link code and return a custom token for the child's existing uid.
 *
 * Does NOT clear ``managed``: the code is used up here, but the phone has not
 * signed in yet. ``markLinked`` (onAuthUserCreated) clears it once it has, so
 * a sign-in that fails leaves the child managed and a parent can make a new
 * code.
 *
 * :returns: ``{ token }``.
 */
async function redeemLinkCode(db, auth, { code }) {
  const id = normaliseCode(code);
  if (!id) throw new HttpsError('invalid-argument', 'Please enter the code.');
  const ref = db.doc(`profileLinks/${id}`);
  let childId;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new HttpsError('not-found', "That code didn't work. Check it, or ask a parent for a new one.");
    }
    const link = snap.data();
    const child = await tx.get(db.doc(`users/${link.childId}`));
    if (link.expiresAt.toMillis() < Date.now()) {
      throw new HttpsError('failed-precondition', 'This code has expired. Ask a parent for a new one.');
    }
    if (!child.exists || child.data().managed !== true) {
      throw new HttpsError('failed-precondition', 'This code is no longer valid. Ask a parent for a new one.');
    }
    tx.delete(ref);
    childId = link.childId;
  });
  return { token: await auth.createCustomToken(childId) };
}

/**
 * Clear ``managed`` once a managed child's uid really has signed in.
 */
async function markLinked(db, uid) {
  const ref = db.doc(`users/${uid}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists && snap.data().managed === true) {
      tx.update(ref, { managed: false, updatedAt: Timestamp.now() });
    }
  });
}

/**
 * Remove the managed children of any family in ``familyIds`` that has no
 * signed-in parent or guardian left. Nobody would be left who can hand them
 * the phone, approve their chores, or link them.
 *
 * :returns: how many managed children were removed.
 */
async function removeOrphanedManagedChildren(db, familyIds) {
  let removed = 0;
  for (const familyId of familyIds) {
    const members = await db.collection('users').where('familyId', '==', familyId).get();
    const hasAdult = members.docs.some((d) => isAdultRole(d.data().role) && d.data().managed !== true);
    if (hasAdult) continue;
    for (const d of members.docs.filter((m) => m.data().managed === true)) {
      await releaseManagedChild(db, d.id);
      removed++;
    }
  }
  return removed;
}
```

- [ ] **Step 4: Wire callables and triggers**

In `functions/index.js` add `const { getAuth } = require('firebase-admin/auth');` with the other admin requires, then after the `removeManagedChild` export:

```js
exports.createLinkCode = onCall(async (request) => {
  const uid = requireAuth(request);
  const { familyId, childId } = requireArgs(request.data, ['familyId', 'childId']);
  return managed.createLinkCode(db, uid, { familyId, childId });
});

// No requireAuth: the child's phone is signed out when it redeems. The code
// itself is the credential (12 characters, 24 hours, single use).
exports.redeemLinkCode = onCall(async (request) => {
  return managed.redeemLinkCode(db, getAuth(), { code: request.data && request.data.code });
});

// The only place `managed` is cleared: once a managed child's uid has really
// signed in on their own phone (custom-token sign-in creates the auth user).
exports.onAuthUserCreated = functionsV1.auth.user().onCreate(async (user) => {
  await managed.markLinked(db, user.uid);
});
```

In `exports.onAuthUserDeleted`, after the existing `console.log(...)`:

```js
  // A family left with no adult has nobody to hand the phone to its managed
  // children, approve their chores, or link them; account deletion cannot be
  // blocked (App Store rule), so remove them.
  const orphans = await managed.removeOrphanedManagedChildren(db, result.families);
  if (orphans > 0) {
    console.log(`[accountDeleted] ${user.uid}: removed ${orphans} managed children left with no adult`);
  }
```

- [ ] **Step 5: Run both suites**

Run: `cd test/rules && npm run test:managedFunctions && npm run test:functions`
Expected: both `0 failed`.

- [ ] **Step 6: Commit**

```bash
git add functions/managedChildren.js functions/index.js test/rules/managed_child.test.mjs
git commit -m "Add link codes that move a child without a phone onto their own phone" -m "managed is cleared only by onAuthUserCreated, so a link whose sign-in fails leaves the child managed and the parent can make a new code. A family whose last adult deletes their account loses its managed children, since nobody is left to look after them." -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: `User.isManaged` and the managed-child policy

**Files:**
- Modify: `lib/domain/entities/user.dart`
- Modify: `lib/data/repositories/firebase_user_repository.dart` (`mapFirestoreToUser`, ~line 144)
- Modify: `lib/data/repositories/firebase_family_repository.dart` (`_mapFirestoreToUser`, ~line 276)
- Create: `lib/domain/services/managed_child_policy.dart`
- Test: `test/domain/entities/user_managed_test.dart`, `test/domain/services/managed_child_policy_test.dart`

**Interfaces:**
- Produces: `User.isManaged` (bool, default `false`, in `copyWith` and `props`); `bool canActForMember({required User viewer, required User member})`.

- [ ] **Step 1: Write the failing tests**

`test/domain/entities/user_managed_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/repositories/firebase_user_repository.dart';

void main() {
  final base = {
    'name': 'Amira',
    'familyId': 'fam_1',
    'role': 'child',
    'points': 0,
  };

  test('a profile with managed: true maps to isManaged', () {
    final user =
        FirebaseUserRepository.mapFirestoreToUser({...base, 'managed': true}, 'kid');
    expect(user.isManaged, isTrue);
  });

  test('a profile without managed is not managed', () {
    final user = FirebaseUserRepository.mapFirestoreToUser(base, 'kid');
    expect(user.isManaged, isFalse);
  });

  test('isManaged takes part in equality', () {
    final a = FirebaseUserRepository.mapFirestoreToUser(base, 'kid');
    expect(a == a.copyWith(isManaged: true), isFalse);
  });
}
```

`test/domain/services/managed_child_policy_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/services/managed_child_policy.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

User _user(String id, UserRole role, {String family = 'fam_1', bool managed = false}) => User(
      id: UserId(id),
      name: id,
      familyId: FamilyId(family),
      role: role,
      points: Points(0),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isManaged: managed,
    );

void main() {
  final kid = _user('kid', UserRole.child, managed: true);

  test('a parent may act for a managed child in their family', () {
    expect(canActForMember(viewer: _user('mum', UserRole.parent), member: kid), isTrue);
  });

  test('a guardian may too', () {
    expect(canActForMember(viewer: _user('gran', UserRole.guardian), member: kid), isTrue);
  });

  test('a child may not', () {
    expect(canActForMember(viewer: _user('teen', UserRole.child), member: kid), isFalse);
  });

  test("another family's parent may not", () {
    expect(
      canActForMember(viewer: _user('other', UserRole.parent, family: 'fam_2'), member: kid),
      isFalse,
    );
  });

  test('nobody acts for a member who signs in themselves', () {
    expect(
      canActForMember(viewer: _user('mum', UserRole.parent), member: _user('teen', UserRole.child)),
      isFalse,
    );
  });
}
```

- [ ] **Step 2: Run and watch them fail**

Run: `flutter test test/domain/entities/user_managed_test.dart test/domain/services/managed_child_policy_test.dart`
Expected: compile errors (`isManaged` and `managed_child_policy.dart` do not exist).

- [ ] **Step 3: Add `isManaged` to `User`**

In `lib/domain/entities/user.dart` add the field after `updatedAt`:

```dart
  /// A child with no sign-in of their own, added by a parent and used on the
  /// parent's phone. Server-owned: only the Cloud Functions set or clear the
  /// `managed` field, so no mapper writes it back.
  final bool isManaged;
```

constructor parameter `this.isManaged = false,`, `copyWith` parameter `bool? isManaged,` with `isManaged: isManaged ?? this.isManaged,`, and append `isManaged,` to `props`.

- [ ] **Step 4: Map it**

In both `FirebaseUserRepository.mapFirestoreToUser` and `FirebaseFamilyRepository._mapFirestoreToUser`, add to the `User(...)` constructor call:

```dart
        isManaged: data['managed'] == true,
```

Do not add `managed` to either `_mapUserToFirestore`.

- [ ] **Step 5: Write the policy**

`lib/domain/services/managed_child_policy.dart`:

```dart
import '../entities/user.dart';

/// Whether [viewer] may act for [member] on a shared phone: hand them the
/// phone, claim or settle treats for them, link or remove them.
///
/// Mirrors the server's ``requireMayActFor`` (functions/managedChildren.js),
/// which is the real guard; this only decides what the app offers.
///
/// :param viewer: the signed-in user holding the phone.
/// :param member: the family member to act for.
/// :returns: true only for a parent or guardian and a managed child of the
///     same family.
bool canActForMember({required User viewer, required User member}) =>
    viewer.role.isAdmin &&
    member.isManaged &&
    member.familyId == viewer.familyId;
```

- [ ] **Step 6: Run the tests**

Run: `flutter test test/domain/entities/user_managed_test.dart test/domain/services/managed_child_policy_test.dart`
Expected: all pass.

- [ ] **Step 7: Run the whole suite and the analyzer**

Run: `flutter analyze && flutter test`
Expected: no new analyzer issues; all tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/domain/entities/user.dart lib/data/repositories/firebase_user_repository.dart lib/data/repositories/firebase_family_repository.dart lib/domain/services/managed_child_policy.dart test/domain/entities/user_managed_test.dart test/domain/services/managed_child_policy_test.dart
git commit -m "Read managed child profiles into User.isManaged" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Client plumbing: callables, `forMemberId`, custom-token sign-in

**Files:**
- Create: `lib/data/services/callable.dart`
- Modify: `lib/data/services/economy_functions.dart`
- Modify: `lib/domain/repositories/reward_repository.dart`, `lib/data/repositories/firebase_reward_repository.dart`, `test/mocks/mock_reward_repository.dart`
- Create: `lib/domain/repositories/managed_child_repository.dart`, `lib/data/services/managed_child_functions.dart`, `test/mocks/mock_managed_child_repository.dart`
- Modify: `lib/domain/repositories/auth_repository.dart`, `lib/data/repositories/firebase_auth_repository.dart`, `test/mocks/mock_auth_repository.dart`
- Modify: `lib/domain/usecases/reward/claim_reward_usecase.dart`, `lib/domain/usecases/reward/settle_redemption_usecase.dart`
- Modify: `lib/di/riverpod_container.dart`
- Test: `test/domain/usecases/reward/claim_reward_usecase_test.dart`, `test/domain/usecases/reward/settle_redemption_usecase_test.dart` (add cases)

**Interfaces:**
- Produces:
  - `Future<Map<String, dynamic>?> callFunction(FirebaseFunctions functions, String name, Map<String, dynamic> data)` throwing `DataException` subtypes.
  - `RewardRepository.claimReward(FamilyId, String rewardId, {UserId? forMemberId})`, `RewardRepository.settleRedemption(FamilyId, String redemptionId, {required bool happened, UserId? forMemberId})`.
  - `ClaimRewardUseCase.call({required Reward reward, UserId? forMemberId})`.
  - `SettleRedemptionUseCase.call({required Redemption redemption, required UserId actor, required bool happened, bool onBehalf = false})`: when `onBehalf`, sends `forMemberId: actor`.
  - `class LinkCode { final String code; final DateTime expiresAt; }`
  - `abstract class ManagedChildRepository { Future<UserId> addManagedChild(FamilyId, String name); Future<void> removeManagedChild(FamilyId, UserId childId); Future<LinkCode> createLinkCode(FamilyId, UserId childId); Future<String> redeemLinkCode(String code); }`
  - `AuthRepository.signInWithCustomToken(String token) -> Future<dynamic>` (returns the Firebase user).
  - Providers: `managedChildRepositoryProvider` (`Provider<ManagedChildRepository>`).
  - `MockManagedChildRepository` records calls in `added`, `removed`, `linkCodesFor`; `redeemLinkCode` returns the code itself as the token (the mock auth repo signs in with the token as the uid).

- [ ] **Step 1: Write the failing use-case tests**

Both files use mocktail (`_MockRewardRepository`) with fixtures `_reward()` / `_familyId` (claim) and `_claim({claimedBy, status})` / `_sibling` / `_familyId` (settle).

Append to `test/domain/usecases/reward/claim_reward_usecase_test.dart` inside `main()`:

```dart
  test('claiming for a managed child passes them to the server', () async {
    registerFallbackValue(UserId('fallback'));
    final repo = _MockRewardRepository();
    when(() => repo.claimReward(any(), any(),
            forMemberId: any(named: 'forMemberId')))
        .thenAnswer((_) async => 'r1');

    final result = await ClaimRewardUseCase(repo)(
      reward: _reward(),
      forMemberId: UserId('kid'),
    );

    expect(result.isRight(), isTrue);
    verify(() => repo.claimReward(_familyId, 'reward1',
        forMemberId: UserId('kid'))).called(1);
  });
```

Append to `test/domain/usecases/reward/settle_redemption_usecase_test.dart` inside `main()`:

```dart
  test('settling on behalf of a managed child passes them to the server',
      () async {
    registerFallbackValue(UserId('fallback'));
    final repo = _MockRewardRepository();
    when(() => repo.settleRedemption(any(), any(),
        happened: any(named: 'happened'),
        forMemberId: any(named: 'forMemberId'))).thenAnswer((_) async {});

    final result = await SettleRedemptionUseCase(repo)(
      redemption: _claim(claimedBy: _sibling),
      actor: _sibling,
      happened: false,
      onBehalf: true,
    );

    expect(result.isRight(), isTrue);
    verify(() => repo.settleRedemption(_familyId, 'r1',
        happened: false, forMemberId: _sibling)).called(1);
  });

  test('settling your own claim sends no forMemberId', () async {
    final repo = _MockRewardRepository();
    when(() => repo.settleRedemption(any(), any(),
        happened: any(named: 'happened'),
        forMemberId: any(named: 'forMemberId'))).thenAnswer((_) async {});

    await SettleRedemptionUseCase(repo)(
      redemption: _claim(claimedBy: _sibling),
      actor: _sibling,
      happened: true,
    );

    verify(() => repo.settleRedemption(_familyId, 'r1',
        happened: true, forMemberId: null)).called(1);
  });
```

Existing stubs in these files (`claimReward(any(), any())`, `settleRedemption(any(), any(), happened: ...)`) keep matching: an omitted named argument in a mocktail matcher matches the `null` the use case now passes.

- [ ] **Step 2: Run and watch them fail**

Run: `flutter test test/domain/usecases/reward/`
Expected: compile errors (`forMemberId`, `onBehalf` unknown).

- [ ] **Step 3: Extract the callable helper**

`lib/data/services/callable.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';

import '../../core/error/exceptions.dart';

/// Calls the Cloud Function [name] and maps its errors to the app's
/// [DataException] types, so use cases can surface the server's friendly
/// message.
///
/// :param functions: the Functions instance to call through.
/// :param name: the callable's exported name.
/// :param data: the request payload.
/// :returns: the response map, or null when the function returns nothing.
Future<Map<String, dynamic>?> callFunction(
  FirebaseFunctions functions,
  String name,
  Map<String, dynamic> data,
) async {
  try {
    final result = await functions.httpsCallable(name).call(data);
    return (result.data as Map?)?.cast<String, dynamic>();
  } on FirebaseFunctionsException catch (e) {
    throw _map(e);
  } catch (e) {
    throw ServerException('$name failed: $e', code: 'FUNCTION_ERROR');
  }
}

DataException _map(FirebaseFunctionsException e) {
  final message = e.message ?? 'Something went wrong.';
  switch (e.code) {
    case 'permission-denied':
      return PermissionException(message, code: e.code);
    case 'not-found':
      return NotFoundException(message, code: e.code);
    case 'failed-precondition':
    case 'invalid-argument':
      return ValidationException(message, code: e.code);
    case 'unauthenticated':
      return AuthException(message, code: e.code);
    default:
      return ServerException(message, code: e.code);
  }
}
```

In `lib/data/services/economy_functions.dart`: delete `_call` and `_map`, import `callable.dart` and `../../domain/value_objects/user_id.dart`, and make the methods:

```dart
  Future<void> approveTask(FamilyId familyId, TaskId taskId) => callFunction(
        _functions,
        'approveTask',
        {'familyId': familyId.value, 'taskId': taskId.value},
      );

  /// Returns the new redemption's id. [forMemberId] claims for a managed
  /// child on the shared phone.
  Future<String> claimReward(
    FamilyId familyId,
    String rewardId, {
    UserId? forMemberId,
  }) async {
    final data = await callFunction(_functions, 'claimReward', {
      'familyId': familyId.value,
      'rewardId': rewardId,
      if (forMemberId != null) 'forMemberId': forMemberId.value,
    });
    return (data?['redemptionId'] as String?) ?? '';
  }

  Future<void> settleRedemption(
    FamilyId familyId,
    String redemptionId, {
    required bool happened,
    UserId? forMemberId,
  }) =>
      callFunction(_functions, 'settleRedemption', {
        'familyId': familyId.value,
        'redemptionId': redemptionId,
        'happened': happened,
        if (forMemberId != null) 'forMemberId': forMemberId.value,
      });
```

- [ ] **Step 4: Thread `forMemberId` through the reward repository**

`lib/domain/repositories/reward_repository.dart`:

```dart
  /// Claims a reward: deducts the stars and records the redemption, server-side
  /// (Cloud Function), so it can never spend stars the claimant doesn't have.
  /// [forMemberId] claims for a managed child on the shared phone.
  /// Returns the new redemption's id.
  Future<String> claimReward(
    FamilyId familyId,
    String rewardId, {
    UserId? forMemberId,
  });

  /// Settles a claim (fulfilled or refunded) server-side. A refund returns the
  /// stars. Only the claimant may settle their own claim, or a parent for a
  /// managed child ([forMemberId]).
  Future<void> settleRedemption(
    FamilyId familyId,
    String redemptionId, {
    required bool happened,
    UserId? forMemberId,
  });
```

`lib/data/repositories/firebase_reward_repository.dart`: add the same optional parameters to both overrides and pass them to `_economy.claimReward(familyId, rewardId, forMemberId: forMemberId)` and `_economy.settleRedemption(familyId, redemptionId, happened: happened, forMemberId: forMemberId)`.

`test/mocks/mock_reward_repository.dart`: add `{UserId? forMemberId}` to `claimReward` and set `claimedBy: forMemberId ?? claimant,`; add `UserId? forMemberId,` to `settleRedemption`'s named parameters (body unchanged).

- [ ] **Step 5: Use cases**

`ClaimRewardUseCase.call`:

```dart
  /// :param reward: the treat to claim.
  /// :param forMemberId: a managed child to claim for on the shared phone.
  Future<Either<Failure, Unit>> call({
    required Reward reward,
    UserId? forMemberId,
  }) async {
    try {
      await _rewards.claimReward(
        reward.familyId,
        reward.id,
        forMemberId: forMemberId,
      );
```

(rest unchanged; import `../../value_objects/user_id.dart`).

`SettleRedemptionUseCase.call` gains `bool onBehalf = false,` documented as "true when a parent settles for a managed child on the shared phone; [actor] is then the child", and the repository call becomes:

```dart
      await _rewards.settleRedemption(
        redemption.familyId,
        redemption.id,
        happened: happened,
        forMemberId: onBehalf ? actor : null,
      );
```

- [ ] **Step 6: Managed child repository, data class and mock**

`lib/domain/repositories/managed_child_repository.dart`:

```dart
import '../value_objects/family_id.dart';
import '../value_objects/user_id.dart';

/// A one-time code that moves a managed child onto their own phone.
class LinkCode {
  const LinkCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

/// Children with no phone of their own. Every operation runs server-side
/// (Cloud Functions in functions/managedChildren.js); the rules forbid
/// clients from writing `managed` or `profileLinks`.
abstract class ManagedChildRepository {
  /// Adds a child by name to [familyId]. Returns the new member's id.
  Future<UserId> addManagedChild(FamilyId familyId, String name);

  /// Removes a managed child for good: chores go back to the pool.
  Future<void> removeManagedChild(FamilyId familyId, UserId childId);

  /// A fresh code for [childId], replacing any earlier one.
  Future<LinkCode> createLinkCode(FamilyId familyId, UserId childId);

  /// Spends [code]. Returns a custom token that signs in as the child.
  Future<String> redeemLinkCode(String code);
}
```

`lib/data/services/managed_child_functions.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/repositories/managed_child_repository.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import 'callable.dart';

/// [ManagedChildRepository] over the managed-child Cloud Functions.
class ManagedChildFunctions implements ManagedChildRepository {
  ManagedChildFunctions([FirebaseFunctions? functions]) : _override = functions;

  final FirebaseFunctions? _override;

  // Resolved lazily, as in EconomyFunctions: constructing this must not need
  // a live Firebase app.
  FirebaseFunctions get _functions => _override ?? FirebaseFunctions.instance;

  @override
  Future<UserId> addManagedChild(FamilyId familyId, String name) async {
    final data = await callFunction(_functions, 'addManagedChild', {
      'familyId': familyId.value,
      'name': name,
    });
    return UserId(data!['childId'] as String);
  }

  @override
  Future<void> removeManagedChild(FamilyId familyId, UserId childId) =>
      callFunction(_functions, 'removeManagedChild', {
        'familyId': familyId.value,
        'childId': childId.value,
      });

  @override
  Future<LinkCode> createLinkCode(FamilyId familyId, UserId childId) async {
    final data = await callFunction(_functions, 'createLinkCode', {
      'familyId': familyId.value,
      'childId': childId.value,
    });
    return LinkCode(
      code: data!['code'] as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (data['expiresAt'] as num).toInt(),
      ),
    );
  }

  @override
  Future<String> redeemLinkCode(String code) async {
    final data = await callFunction(_functions, 'redeemLinkCode', {'code': code});
    return data!['token'] as String;
  }
}
```

`test/mocks/mock_managed_child_repository.dart`:

```dart
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/domain/repositories/managed_child_repository.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

/// In-memory [ManagedChildRepository]. [redeemLinkCode] returns the code as
/// the token, and MockAuthRepository.signInWithCustomToken signs in with the
/// token as the uid, so a test can pick the uid a link signs in as.
class MockManagedChildRepository implements ManagedChildRepository {
  final List<String> added = [];
  final List<UserId> removed = [];
  final List<UserId> linkCodesFor = [];

  /// Codes [redeemLinkCode] refuses, mapped to the server's message.
  final Map<String, String> refusedCodes = {};

  @override
  Future<UserId> addManagedChild(FamilyId familyId, String name) async {
    added.add(name);
    return UserId('managed_${added.length}');
  }

  @override
  Future<void> removeManagedChild(FamilyId familyId, UserId childId) async {
    removed.add(childId);
  }

  @override
  Future<LinkCode> createLinkCode(FamilyId familyId, UserId childId) async {
    linkCodesFor.add(childId);
    return LinkCode(
      code: 'ABCDEFGHJKMN',
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  @override
  Future<String> redeemLinkCode(String code) async {
    final refusal = refusedCodes[code];
    if (refusal != null) throw ValidationException(refusal, code: 'failed-precondition');
    return code;
  }
}
```

- [ ] **Step 7: Custom-token sign-in**

`lib/domain/repositories/auth_repository.dart`, after `signInAnonymously`:

```dart
  /// Signs in with a server-issued custom token (moving a managed child onto
  /// their own phone). Returns the Firebase user.
  Future<dynamic> signInWithCustomToken(String token);
```

`lib/data/repositories/firebase_auth_repository.dart`, after `signInAnonymously`:

```dart
  @override
  Future<dynamic> signInWithCustomToken(String token) async {
    try {
      final cred = await _auth.signInWithCustomToken(token);
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw mapOAuthError(e);
    }
  }
```

`test/mocks/mock_auth_repository.dart`, after `signInAnonymously`:

```dart
  /// The token is used as the uid, so a test chooses who a link signs in as.
  @override
  Future<dynamic> signInWithCustomToken(String token) async {
    _currentUser = FakeFirebaseUser(uid: token);
    providerIds = const [];
    _authStateController.add(_currentUser);
    return _currentUser;
  }
```

- [ ] **Step 8: Provider**

At the bottom of `lib/di/riverpod_container.dart` (import `../domain/repositories/managed_child_repository.dart` and `../data/services/managed_child_functions.dart`):

```dart
/// Children with no phone of their own. Hand-written (build_runner is broken
/// on this toolchain). See ``lib/data/services/managed_child_functions.dart``.
final managedChildRepositoryProvider = Provider<ManagedChildRepository>((ref) {
  return ManagedChildFunctions();
});
```

- [ ] **Step 9: Run tests and analyzer**

Run: `flutter analyze && flutter test`
Expected: no new analyzer issues; all tests pass, including the two new use-case tests.

- [ ] **Step 10: Commit**

```bash
git add lib/data/services/callable.dart lib/data/services/economy_functions.dart lib/domain/repositories/reward_repository.dart lib/data/repositories/firebase_reward_repository.dart test/mocks/mock_reward_repository.dart lib/domain/repositories/managed_child_repository.dart lib/data/services/managed_child_functions.dart test/mocks/mock_managed_child_repository.dart lib/domain/repositories/auth_repository.dart lib/data/repositories/firebase_auth_repository.dart test/mocks/mock_auth_repository.dart lib/domain/usecases/reward/claim_reward_usecase.dart lib/domain/usecases/reward/settle_redemption_usecase.dart lib/di/riverpod_container.dart test/domain/usecases/reward/
git commit -m "Add client calls for managed children and on-behalf treats" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Use cases: add a child, link a phone, refuse the last adult leaving

**Files:**
- Create: `lib/domain/usecases/family/add_managed_child_usecase.dart`, `lib/domain/usecases/family/link_child_device_usecase.dart`
- Modify: `lib/domain/usecases/family/leave_family_usecase.dart`
- Modify: `lib/di/riverpod_container.dart`
- Test: `test/domain/usecases/family/add_managed_child_usecase_test.dart`, `test/domain/usecases/family/link_child_device_usecase_test.dart`, `test/domain/usecases/family/leave_family_usecase_test.dart` (add cases)

**Interfaces:**
- Consumes: `ManagedChildRepository`, `AuthRepository.signInWithCustomToken`, `MockManagedChildRepository` (Task 6); `User.isManaged` (Task 5).
- Produces:
  - `AddManagedChildUseCase(ManagedChildRepository).call({required FamilyId familyId, required String name}) -> Future<Either<Failure, UserId>>`
  - `LinkChildDeviceUseCase(ManagedChildRepository, AuthRepository).call({required String code}) -> Future<Either<Failure, UserId>>`
  - Providers `addManagedChildUseCaseProvider`, `linkChildDeviceUseCaseProvider`.
  - `LeaveFamilyUseCase` returns `BusinessFailure('Remove or move Amira first.')` (names joined with " and ") when the leaver is the only parent/guardian and managed children remain.

- [ ] **Step 1: Write the failing tests**

`test/domain/usecases/family/add_managed_child_usecase_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/usecases/family/add_managed_child_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';

import '../../../mocks/mock_managed_child_repository.dart';

void main() {
  test('adds a child by trimmed name', () async {
    final repo = MockManagedChildRepository();
    final result = await AddManagedChildUseCase(repo)(
      familyId: FamilyId('fam_1'),
      name: '  Amira ',
    );
    expect(result.isRight(), isTrue);
    expect(repo.added, ['Amira']);
  });

  test('a blank name is refused before calling the server', () async {
    final repo = MockManagedChildRepository();
    final result = await AddManagedChildUseCase(repo)(
      familyId: FamilyId('fam_1'),
      name: '   ',
    );
    expect(result.isLeft(), isTrue);
    expect(repo.added, isEmpty);
  });

  test('a name over 50 characters is refused', () async {
    final repo = MockManagedChildRepository();
    final result = await AddManagedChildUseCase(repo)(
      familyId: FamilyId('fam_1'),
      name: 'A' * 51,
    );
    expect(result.isLeft(), isTrue);
  });
}
```

`test/domain/usecases/family/link_child_device_usecase_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/usecases/family/link_child_device_usecase.dart';

import '../../../mocks/mock_auth_repository.dart';
import '../../../mocks/mock_managed_child_repository.dart';

void main() {
  test('redeems the code and signs this phone in as the child', () async {
    final auth = MockAuthRepository();
    final result = await LinkChildDeviceUseCase(MockManagedChildRepository(), auth)(
      code: 'kid_uid',
    );
    expect(result.getOrElse(() => throw 'failed').value, 'kid_uid');
    expect(auth.currentUser.uid, 'kid_uid');
  });

  test("the server's refusal reaches the child word for word", () async {
    final repo = MockManagedChildRepository()
      ..refusedCodes['OLDCODE'] = 'This code has expired. Ask a parent for a new one.';
    final result = await LinkChildDeviceUseCase(repo, MockAuthRepository())(code: 'OLDCODE');
    result.fold(
      (f) => expect(f.message, 'This code has expired. Ask a parent for a new one.'),
      (_) => fail('should not link'),
    );
  });

  test('an empty code is refused before calling the server', () async {
    final result = await LinkChildDeviceUseCase(MockManagedChildRepository(), MockAuthRepository())(
      code: ' - ',
    );
    expect(result.isLeft(), isTrue);
  });

  test('a sign-in that fails after the code was spent says to get a new code', () async {
    final auth = _FailingSignInAuth();
    final result = await LinkChildDeviceUseCase(MockManagedChildRepository(), auth)(code: 'kid_uid');
    result.fold(
      (f) => expect(f.message, "That didn't finish. Ask a parent for a new code."),
      (_) => fail('should not link'),
    );
  });
}

class _FailingSignInAuth extends MockAuthRepository {
  @override
  Future<dynamic> signInWithCustomToken(String token) async =>
      throw Exception('network');
}
```

Append to `test/domain/usecases/family/leave_family_usecase_test.dart` inside `main()`:

```dart
  group('managed children', () {
    User adult(String id, UserRole role) =>
        _member(UserId(id)).copyWith(name: id, role: role);
    User managedKid(String id) =>
        _member(UserId(id)).copyWith(name: 'Amira', isManaged: true);

    test('the only adult cannot leave while managed children remain', () async {
      final users = MockUserRepository();
      final families = MockFamilyRepository();
      final mum = adult('mum', UserRole.parent);
      await families.createFamily(_family([mum.id, UserId('kid')]));
      families.addTestFamilyMembers(FamilyId('fam_1'), [mum, managedKid('kid')]);
      await users.createUserProfile(mum);

      final result = await LeaveFamilyUseCase(families, users)(userId: mum.id);

      result.fold(
        (f) => expect(f.message, 'Remove or move Amira first.'),
        (_) => fail('should refuse'),
      );
    });

    test('a second adult in the family lets the first leave', () async {
      final users = MockUserRepository();
      final families = MockFamilyRepository();
      final mum = adult('mum', UserRole.parent);
      final dad = adult('dad', UserRole.guardian);
      await families.createFamily(_family([mum.id, dad.id, UserId('kid')]));
      families.addTestFamilyMembers(FamilyId('fam_1'), [mum, dad, managedKid('kid')]);
      await users.createUserProfile(mum);

      final result = await LeaveFamilyUseCase(families, users)(userId: mum.id);

      expect(result.isRight(), isTrue);
    });
  });
```

(`MockFamilyRepository.addTestFamilyMembers(FamilyId, List<User>)` already exists and seeds what `getFamilyMembers` returns.)

- [ ] **Step 2: Run and watch them fail**

Run: `flutter test test/domain/usecases/family/`
Expected: compile errors for the two new use cases; the leave-family group fails (no refusal yet).

- [ ] **Step 3: Write `AddManagedChildUseCase`**

```dart
import 'package:dartz/dartz.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../repositories/managed_child_repository.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/user_id.dart';

/// Adds a child with no phone of their own to a family.
///
/// The server (``addManagedChild``) is the real guard: it checks the caller is
/// a parent or guardian and enforces the 10-child cap. The checks here only
/// spare a round trip for an obviously bad name; they mirror the server's.
class AddManagedChildUseCase {
  AddManagedChildUseCase(this._repository);

  final ManagedChildRepository _repository;

  static const maxNameLength = 50;

  /// :param familyId: the family to add the child to.
  /// :param name: the child's name, as the family calls them.
  /// :returns: the new member's id, or a ``Failure`` with a message to show.
  Future<Either<Failure, UserId>> call({
    required FamilyId familyId,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Left(ValidationFailure('Please enter a name.'));
    if (trimmed.length > maxNameLength) {
      return Left(ValidationFailure('That name is too long.'));
    }
    try {
      return Right(await _repository.addManagedChild(familyId, trimmed));
    } on DataException catch (e) {
      return Left(BusinessFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Could not add the child: $e'));
    }
  }
}
```

- [ ] **Step 4: Write `LinkChildDeviceUseCase`**

```dart
import 'package:dartz/dartz.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/managed_child_repository.dart';
import '../../value_objects/user_id.dart';
import 'join_family_usecase.dart' show normaliseInviteCode;

/// Moves a managed child onto this phone: spends the link code a parent made
/// and signs in as the child's existing account, stars and history included.
class LinkChildDeviceUseCase {
  LinkChildDeviceUseCase(this._repository, this._auth);

  final ManagedChildRepository _repository;
  final AuthRepository _auth;

  /// :param code: the link code, as typed (spaces, dashes and case ignored).
  /// :returns: the child's id once this phone is signed in as them.
  Future<Either<Failure, UserId>> call({required String code}) async {
    if (normaliseInviteCode(code).isEmpty) {
      return Left(ValidationFailure('Please enter the code.'));
    }

    final String token;
    try {
      token = await _repository.redeemLinkCode(code);
    } on DataException catch (e) {
      // The server's messages are written for the child; pass them through.
      return Left(BusinessFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Could not check the code: $e'));
    }

    try {
      final user = await _auth.signInWithCustomToken(token);
      return Right(UserId(user.uid as String));
    } catch (e) {
      // The code is spent, but the server only clears `managed` once a
      // sign-in really happens, so the parent can simply make a new code.
      return Left(AuthFailure("That didn't finish. Ask a parent for a new code."));
    }
  }
}
```

- [ ] **Step 5: Refuse the last adult leaving**

In `LeaveFamilyUseCase.call`, right after `final familyId = user.familyId;` insert:

```dart
      // Managed children (no phone of their own) need an adult on someone's
      // phone to hand it to them, approve their chores and link them. The
      // last parent or guardian must remove or move them first.
      if (user.role.isAdmin) {
        final members = await _familyRepository.getFamilyMembers(familyId);
        final otherAdult = members.any(
          (m) => m.id != userId && m.role.isAdmin && !m.isManaged,
        );
        final managed = members.where((m) => m.isManaged).toList();
        if (!otherAdult && managed.isNotEmpty) {
          final names = managed.map((m) => m.name).join(' and ');
          return Left(BusinessFailure('Remove or move $names first.'));
        }
      }
```

- [ ] **Step 6: Providers**

At the bottom of `lib/di/riverpod_container.dart`:

```dart
final addManagedChildUseCaseProvider = Provider<AddManagedChildUseCase>((ref) {
  return AddManagedChildUseCase(ref.watch(managedChildRepositoryProvider));
});

final linkChildDeviceUseCaseProvider = Provider<LinkChildDeviceUseCase>((ref) {
  return LinkChildDeviceUseCase(
    ref.watch(managedChildRepositoryProvider),
    ref.watch(authRepositoryProvider),
  );
});
```

Export both new use cases from `lib/domain/usecases/usecases.dart` alongside the other family use cases.

- [ ] **Step 7: Run tests and analyzer**

Run: `flutter analyze && flutter test`
Expected: all pass.

- [ ] **Step 8: Commit**

```bash
git add lib/domain/usecases/family/ lib/domain/usecases/usecases.dart lib/di/riverpod_container.dart test/domain/usecases/family/
git commit -m "Add use cases for adding and linking a child without a phone" -m "The last parent or guardian can no longer leave a family that still has managed children, since nobody would be left to look after them." -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: `actingAs` for chore details and treats

**Files:**
- Modify: `lib/presentation/screens/task_details_screen.dart` (constructor ~line 27; `build` ~line 653)
- Modify: `lib/presentation/screens/rewards_screen.dart`
- Modify: `lib/presentation/providers/riverpod/rewards_notifier.dart` (`outstandingClaims` refund)
- Test: `test/presentation/rewards_acting_as_test.dart`

**Interfaces:**
- Consumes: `ClaimRewardUseCase(forMemberId:)`, `SettleRedemptionUseCase(onBehalf:)` (Task 6).
- Produces: `TaskDetailsScreen({required Task task, User? actingAs})`; `RewardsScreen({User? actingAs})`. With `actingAs` set: no add/edit/delete of treats, claims and settles go on the child's behalf, the refund is not announced to the parent's `StarAwardWatcher`, and all balances shown are the child's.

- [ ] **Step 1: Write the failing widget test**

`test/presentation/rewards_acting_as_test.dart`:

```dart
// RewardsScreen(actingAs: child) is the Treats tab of the child view on a
// parent's phone. It must show the child's balance, claim for the child, and
// offer no way to add or edit treats.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/screens/rewards_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_reward_repository.dart';
import '../mocks/mock_user_repository.dart';

final _familyId = FamilyId('family_1');

final _kid = User(
  id: UserId('kid'),
  name: 'Amira',
  familyId: _familyId,
  role: UserRole.child,
  points: Points(30),
  joinedAt: DateTime(2026),
  updatedAt: DateTime(2026),
  isManaged: true,
);

void main() {
  testWidgets('shows the child balance, claims for the child, no add button',
      (tester) async {
    final rewards = MockRewardRepository(claimant: UserId('mum'))
      ..seedReward(Reward(
        id: 'park',
        familyId: _familyId,
        title: 'Park trip',
        cost: Points(20),
        timeframe: RewardTimeframe.openEnded,
        createdBy: UserId('mum'),
        createdAt: DateTime(2026),
      ));
    addTearDown(rewards.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
        userRepositoryProvider.overrideWith((_) => MockUserRepository()),
        rewardRepositoryProvider.overrideWith((_) => rewards),
      ],
      child: MaterialApp(theme: appLightTheme, home: RewardsScreen(actingAs: _kid)),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('Edit or delete treat'), findsNothing);

    await tester.tap(find.text('20 ⭐'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final claims = await rewards.streamRedemptions(_familyId).first;
    expect(claims.single.claimedBy, UserId('kid'));
  });
}
```

- [ ] **Step 2: Run and watch it fail**

Run: `flutter test test/presentation/rewards_acting_as_test.dart`
Expected: compile error (`actingAs` not a parameter).

- [ ] **Step 3: `TaskDetailsScreen.actingAs`**

```dart
class TaskDetailsScreen extends ConsumerStatefulWidget {
  final Task task;

  /// The managed child using a parent's phone (child view). Every action on
  /// this screen is then taken as the child; null means the signed-in user.
  final User? actingAs;

  const TaskDetailsScreen({super.key, required this.task, this.actingAs});
```

In `build`, replace `final currentUser = authState.user;` with:

```dart
    final currentUser = widget.actingAs ?? authState.user;
```

(Everything below already flows from `currentUser`: `taskActionsFor` gives a child only their own chore's actions, and the parent-only menus check `currentUser.role`.)

- [ ] **Step 4: `RewardsScreen.actingAs`**

Constructor and build:

```dart
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key, this.actingAs});

  /// The managed child using a parent's phone (child view): balance, claims
  /// and settles are theirs, and treats cannot be added or edited. Null means
  /// the signed-in user, as before.
  final User? actingAs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = actingAs ?? ref.watch(authNotifierProvider).user;
```

Wrap the `floatingActionButton:` value in `actingAs == null ? FloatingActionButton(...) : null`. Pass the child down:

- `_OwedCard(claims: claims, userId: user.id, onBehalf: actingAs != null)`
- `_RewardTile(reward: reward, balance: user.points.value, actingAs: actingAs)`

`_OwedCard`: add `required this.onBehalf` / `final bool onBehalf;`. In `_settle`, replace the watcher lines and the use-case call with:

```dart
    // The parent's own balance does not move when a child's refund lands, so
    // only announce a refund for the signed-in user's own claims.
    final watcher = ref.read(starAwardWatcherProvider.notifier);
    final announce = !happened && !onBehalf;
    if (announce) watcher.expectRefund(claim.cost);
    final result = await ref.read(settleRedemptionUseCaseProvider)(
      redemption: claim,
      actor: userId,
      happened: happened,
      onBehalf: onBehalf,
    );
    if (result.isLeft() && announce) watcher.cancelRefund(claim.cost);
```

`_RewardTile`: add `this.actingAs` / `final User? actingAs;`. In `_RewardTileState.build` replace the `isParent` line with:

```dart
    final isParent = widget.actingAs == null &&
        ref.watch(authNotifierProvider).user?.role == UserRole.parent;
```

In `_claim`, replace the first two lines and the use-case call with:

```dart
    final user = widget.actingAs ?? ref.read(authNotifierProvider).user;
    if (user == null) return;
```

```dart
      final result = await ref.read(claimRewardUseCaseProvider)(
        reward: reward,
        forMemberId: widget.actingAs?.id,
      );
```

(the analytics `userId: user.id.value` then records the child, which is who claimed).

- [ ] **Step 5: On-behalf lazy refunds**

In `lib/presentation/providers/riverpod/rewards_notifier.dart` `outstandingClaims`, replace the body of `refund` with:

```dart
  Future<void> refund(Redemption claim) async {
    if (!refunding.add(claim.id)) return;
    // Read for the signed-in user, or for a managed child in the child view
    // on a parent's phone. Only the signed-in user's own refund raises this
    // device's balance, so only that one is announced to the star watcher.
    final signedIn = ref.read(authNotifierProvider).user?.id;
    final onBehalf = signedIn != null && claim.claimedBy != signedIn;
    final watcher = ref.read(starAwardWatcherProvider.notifier);
    if (!onBehalf) watcher.expectRefund(claim.cost);
    final result = await ref.read(settleRedemptionUseCaseProvider)(
      redemption: claim,
      actor: claim.claimedBy,
      happened: false,
      onBehalf: onBehalf,
    );
    if (result.isLeft() && !onBehalf) watcher.cancelRefund(claim.cost);
```

(keep the existing `result.fold(...)` logging that follows). Import `auth_notifier.dart`. Update the provider's doc comment line "Only ever read for the signed-in user" accordingly.

- [ ] **Step 6: Run tests and analyzer**

Run: `flutter test test/presentation/rewards_acting_as_test.dart && flutter analyze && flutter test`
Expected: all pass; existing `rewards_*` tests unchanged and green.

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/screens/task_details_screen.dart lib/presentation/screens/rewards_screen.dart lib/presentation/providers/riverpod/rewards_notifier.dart test/presentation/rewards_acting_as_test.dart
git commit -m "Let chore details and treats act as a managed child" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 9: The child view (`ChildModeScreen`)

**Files:**
- Create: `lib/presentation/screens/child_mode_screen.dart`
- Modify: `lib/core/analytics/analytics.dart` (add the three events to `AnalyticsEventName`)
- Modify: `docs/superpowers/specs/2026-10-26-managed-child-profiles-design.md` ("Active member" paragraph)
- Test: `test/presentation/child_mode_screen_test.dart`

**Interfaces:**
- Consumes: `TaskDetailsScreen(actingAs:)`, `RewardsScreen(actingAs:)` (Task 8); `User.isManaged` (Task 5).
- Produces: `ChildModeScreen({required UserId childId, required String parentName})`, `memberProfileProvider` (`StreamProvider.autoDispose.family<User?, UserId>`); `AnalyticsEventName.managedChildAdded`, `.childModeEntered`, `.linkCodeRedeemed`.

- [ ] **Step 1: Write the failing widget test**

`test/presentation/child_mode_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/child_mode_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_user_repository.dart';
import '../utils/task_factory.dart';

final _familyId = FamilyId('family_1');

User _kid({bool managed = true}) => User(
      id: UserId('kid'),
      name: 'Amira',
      familyId: _familyId,
      role: UserRole.child,
      points: Points(12),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isManaged: managed,
    );

Future<void> _pump(
  WidgetTester tester, {
  required Stream<User?> kid,
  required List<Task> tasks,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      // ChildModeScreen reads the signed-in parent for analytics, which
      // builds AuthNotifier; keep it off real Firebase.
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => MockUserRepository()),
      memberProfileProvider(UserId('kid')).overrideWith((_) => kid),
      taskListStreamProvider(_familyId).overrideWith((_) => Stream.value(tasks)),
    ],
    child: MaterialApp(
      theme: appLightTheme,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChildModeScreen(childId: UserId('kid'), parentName: 'Mum'),
            )),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows only the child\'s chores and the up-for-grabs ones', (tester) async {
    await _pump(tester, kid: Stream.value(_kid()), tasks: [
      testTask(id: 'a', title: 'Tidy room', status: TaskStatus.assigned, assignedTo: 'kid'),
      testTask(id: 'b', title: 'Mum chore', status: TaskStatus.assigned, assignedTo: 'mum'),
      testTask(id: 'c', title: 'Feed cat', status: TaskStatus.available),
    ]);

    expect(find.text('Amira'), findsOneWidget);
    expect(find.text('Tidy room'), findsOneWidget);
    expect(find.text('Feed cat'), findsOneWidget);
    expect(find.text('Mum chore'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Take'), findsOneWidget);
  });

  testWidgets('Back returns to the parent', (tester) async {
    await _pump(tester, kid: Stream.value(_kid()), tasks: const []);
    await tester.tap(find.text('Back to Mum'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('closes itself once the child is linked to their own phone', (tester) async {
    await _pump(
      tester,
      kid: Stream.fromIterable([_kid(), _kid(managed: false)]),
      tasks: const [],
    );
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}
```

Create `test/utils/task_factory.dart` and import it in the test (`import '../utils/task_factory.dart';`):

```dart
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

/// A minimal [Task] in `family_1`, created by `mum`, for widget tests.
Task testTask({
  required String id,
  required String title,
  required TaskStatus status,
  String? assignedTo,
  bool requiresPhotoProof = false,
}) =>
    Task(
      id: TaskId(id),
      title: title,
      description: '',
      status: status,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 7, 20),
      assignedToId: assignedTo == null ? null : UserId(assignedTo),
      createdById: UserId('mum'),
      createdAt: DateTime(2026, 7, 16),
      points: Points(5),
      tags: const [],
      familyId: FamilyId('family_1'),
      requiresPhotoProof: requiresPhotoProof,
    );
```

- [ ] **Step 2: Run and watch it fail**

Run: `flutter test test/presentation/child_mode_screen_test.dart`
Expected: compile error (`child_mode_screen.dart` does not exist).

- [ ] **Step 3: Analytics events**

In `lib/core/analytics/analytics.dart` `AnalyticsEventName`, after `memberJoined,`:

```dart
  // Children without a phone: does adding one (instead of inviting) get a
  // solo family using the app, and do they later move to their own phone?
  managedChildAdded,
  childModeEntered,
  linkCodeRedeemed,
```

- [ ] **Step 4: Write `ChildModeScreen`**

`lib/presentation/screens/child_mode_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics.dart';
import '../../di/riverpod_container.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/user.dart';
import '../../domain/services/task_actions.dart';
import '../../domain/value_objects/user_id.dart';
import '../motion/animated_star_count.dart';
import '../providers/riverpod/auth_notifier.dart';
import '../providers/riverpod/task_list_notifier.dart';
import '../theme/app_tokens.dart';
import '../utils/task_status_label.dart';
import '../widgets/user_avatar.dart';
import 'rewards_screen.dart';
import 'task_details_screen.dart';

/// One member's live profile. Hand-written (build_runner is broken).
final memberProfileProvider =
    StreamProvider.autoDispose.family<User?, UserId>((ref, id) {
  return ref.watch(userRepositoryProvider).streamUserProfile(id);
});

/// The child view: a managed child (no phone of their own) using a parent's
/// phone. Firebase stays signed in as the parent; this route passes the
/// child's id into the same use cases the rest of the app uses.
///
/// Being a pushed route is the whole "who is using the phone" state: nothing
/// is persisted, so a cold start always opens the parent's view, and popping
/// returns to it. The route closes itself if the child is removed or moves to
/// a phone of their own.
class ChildModeScreen extends ConsumerStatefulWidget {
  const ChildModeScreen({
    super.key,
    required this.childId,
    required this.parentName,
  });

  final UserId childId;
  final String parentName;

  @override
  ConsumerState<ChildModeScreen> createState() => _ChildModeScreenState();
}

class _ChildModeScreenState extends ConsumerState<ChildModeScreen> {
  int _tab = 0;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    final parent = ref.read(authNotifierProvider).user;
    if (parent != null) {
      ref.read(analyticsProvider).log(
            AnalyticsEventName.childModeEntered,
            userId: parent.id.value,
            familyId: parent.familyId.value,
          );
    }
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(memberProfileProvider(widget.childId), (_, next) {
      final child = next.valueOrNull;
      if (next.hasValue && (child == null || !child.isManaged)) _close();
    });

    final child = ref.watch(memberProfileProvider(widget.childId)).valueOrNull;
    if (child == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            UserAvatar(user: child, radius: 18),
            const SizedBox(width: 12),
            Flexible(child: Text(child.name, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 12),
            AnimatedStarCount(child.points.toInt()),
          ],
        ),
        actions: [
          TextButton.icon(
            key: const Key('child_mode_back'),
            icon: const Icon(Icons.swap_horiz),
            label: Text('Back to ${widget.parentName}'),
            onPressed: _close,
          ),
        ],
      ),
      body: _tab == 0 ? _ChildChores(child: child) : RewardsScreen(actingAs: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'My chores'),
          NavigationDestination(icon: Icon(Icons.card_giftcard), label: 'Treats'),
        ],
      ),
    );
  }
}

/// The child's own chores, then the ones up for grabs. Done and Take act as
/// the child; a photo-proof chore opens its details, where the camera flow
/// lives.
class _ChildChores extends ConsumerWidget {
  const _ChildChores({required this.child});

  final User child;

  static const _active = {
    TaskStatus.assigned,
    TaskStatus.inProgress,
    TaskStatus.needsRevision,
    TaskStatus.pendingApproval,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListStreamProvider(child.familyId));
    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load chores: $e')),
      data: (tasks) {
        final mine = tasks
            .where((t) => t.assignedToId == child.id && _active.contains(t.status))
            .toList();
        final open = tasks.where((t) => t.status == TaskStatus.available).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Your chores', style: Theme.of(context).textTheme.titleMedium),
            if (mine.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Nothing to do right now.'),
              ),
            for (final t in mine) _ChoreTile(task: t, child: child),
            const SizedBox(height: 16),
            Text('Up for grabs', style: Theme.of(context).textTheme.titleMedium),
            for (final t in open) _ChoreTile(task: t, child: child),
          ],
        );
      },
    );
  }
}

class _ChoreTile extends ConsumerWidget {
  const _ChoreTile({required this.task, required this.child});

  final Task task;
  final User child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions =
        taskActionsFor(task: task, viewerId: child.id, viewerRole: child.role);
    final notifier = ref.read(taskListNotifierProvider(child.familyId).notifier);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: context.tokens.brickDeep,
        ));
      }
    }

    Widget? trailing;
    if (actions.contains(TaskAction.complete) && !task.requiresPhotoProof) {
      trailing = FilledButton(
        onPressed: () => run(() => notifier.completeTask(
              task.id.value,
              child.id,
              child.familyId,
            )),
        child: const Text('Done'),
      );
    } else if (actions.contains(TaskAction.claim)) {
      trailing = OutlinedButton(
        onPressed: () => run(() => notifier.claimTask(
              task.id.value,
              child.id,
              child.familyId,
            )),
        child: const Text('Take'),
      );
    }

    return Card(
      child: ListTile(
        title: Text(task.title),
        subtitle: Text('${taskStatusLabel(task.status)} · ${task.points.value} ⭐'),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TaskDetailsScreen(task: task, actingAs: child),
        )),
      ),
    );
  }
}
```

Check the real names before compiling: `TaskAction.claim` / `TaskAction.complete` (in `lib/domain/services/task_actions.dart`), `taskStatusLabel` (in `lib/presentation/utils/task_status_label.dart`), `UserAvatar(user:, radius:)`. Adjust imports to the real paths if they differ.

- [ ] **Step 5: Run the test**

Run: `flutter test test/presentation/child_mode_screen_test.dart`
Expected: 3 pass.

- [ ] **Step 6: Align the spec**

In the spec's section 2, replace the "Active member" paragraph with:

```markdown
### Active member

"Who is using the phone" is the `ChildModeScreen` route itself: it holds the
child's id, and popping it returns to the signed-in parent. Nothing is
persisted, so a cold start always opens the parent's view. The route closes
itself when the child's profile is removed or stops being `managed`.
```

- [ ] **Step 7: Analyzer, full suite, commit**

Run: `flutter analyze && flutter test`
Expected: all pass.

```bash
git add lib/presentation/screens/child_mode_screen.dart lib/core/analytics/analytics.dart test/presentation/child_mode_screen_test.dart test/utils/task_factory.dart docs/superpowers/specs/2026-10-26-managed-child-profiles-design.md
git commit -m "Add the child view for a child using a parent's phone" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 10: Adding, handing over, moving and removing a managed child

**Files:**
- Create: `lib/presentation/widgets/add_managed_child_sheet.dart`
- Modify: `lib/presentation/screens/invite_your_family_screen.dart`
- Modify: `lib/presentation/widgets/home/invite_family_card.dart`, `lib/presentation/screens/home_screen.dart` (~line 290)
- Modify: `lib/presentation/screens/family_screen.dart` (members card)
- Modify: `lib/presentation/screens/member_detail_screen.dart`
- Test: `test/presentation/add_managed_child_sheet_test.dart`, `test/presentation/member_detail_managed_test.dart`

**Interfaces:**
- Consumes: `addManagedChildUseCaseProvider` (Task 7), `managedChildRepositoryProvider` (Task 6), `canActForMember` (Task 5), `ChildModeScreen` (Task 9), `formatInviteCode`.
- Produces: `Future<UserId?> showAddManagedChildSheet(BuildContext context, WidgetRef ref, {required FamilyId familyId, required String source})`; `InviteFamilyCard({required inviteCode, required onDismiss, required onAddChild})`.

- [ ] **Step 1: Write the failing widget tests**

`test/presentation/add_managed_child_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/add_managed_child_sheet.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_managed_child_repository.dart';

void main() {
  testWidgets('adding a name calls the server and closes the sheet', (tester) async {
    final repo = MockManagedChildRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        managedChildRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      ],
      child: MaterialApp(
        theme: appLightTheme,
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: TextButton(
              onPressed: () => showAddManagedChildSheet(context, ref,
                  familyId: FamilyId('family_1'), source: 'family_tab'),
              child: const Text('add'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('managed_child_name_field')), 'Amira');
    await tester.tap(find.byKey(const Key('managed_child_add_button')));
    await tester.pumpAndSettle();

    expect(repo.added, ['Amira']);
    expect(find.byKey(const Key('managed_child_name_field')), findsNothing);
  });

  testWidgets('a blank name shows the error and keeps the sheet open', (tester) async {
    final repo = MockManagedChildRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        managedChildRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      ],
      child: MaterialApp(
        theme: appLightTheme,
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: TextButton(
              onPressed: () => showAddManagedChildSheet(context, ref,
                  familyId: FamilyId('family_1'), source: 'family_tab'),
              child: const Text('add'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('managed_child_add_button')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a name.'), findsOneWidget);
    expect(repo.added, isEmpty);
  });
}
```

`test/presentation/member_detail_managed_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/member_detail_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_managed_child_repository.dart';
import '../mocks/mock_user_repository.dart';

const _parentUid = 'mock_google_uid';
final _familyId = FamilyId('family_1');

User _child({required bool managed}) => User(
      id: UserId('kid'),
      name: 'Amira',
      familyId: _familyId,
      role: UserRole.child,
      points: Points(5),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isManaged: managed,
    );

/// Signs a parent into family_1 (the rewards_settle_reclaim_test pattern)
/// and opens [member]'s page.
Future<void> _pump(
  WidgetTester tester,
  User member,
  MockManagedChildRepository repo,
) async {
  final auth = MockAuthRepository();
  final users = MockUserRepository();
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWith((_) => auth),
    userRepositoryProvider.overrideWith((_) => users),
    managedChildRepositoryProvider.overrideWithValue(repo),
    taskListStreamProvider(_familyId).overrideWith((_) => Stream.value(const [])),
  ]);
  addTearDown(container.dispose);

  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(UserId(_parentUid));
    await users.updateUserProfile(
      profile!.copyWith(familyId: _familyId, role: UserRole.parent),
    );
  });

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: appLightTheme, home: MemberDetailScreen(member: member)),
  ));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('a parent sees the managed-child actions and can make a link code',
      (tester) async {
    final repo = MockManagedChildRepository();
    await _pump(tester, _child(managed: true), repo);

    expect(find.text('Hand the phone to Amira'), findsOneWidget);
    expect(find.text('Move Amira to their own phone'), findsOneWidget);
    expect(find.text('Remove Amira'), findsOneWidget);

    await tester.tap(find.text('Move Amira to their own phone'));
    await tester.pumpAndSettle();

    expect(find.text('ABCD EFGH JKMN'), findsOneWidget);
    expect(repo.linkCodesFor.single, UserId('kid'));
  });

  testWidgets('no managed-child actions for a member with their own sign-in',
      (tester) async {
    await _pump(tester, _child(managed: false), MockManagedChildRepository());

    expect(find.text('Hand the phone to Amira'), findsNothing);
    expect(find.text('Move Amira to their own phone'), findsNothing);
    expect(find.text('Remove Amira'), findsNothing);
  });
}
```

- [ ] **Step 2: Run and watch them fail**

Run: `flutter test test/presentation/add_managed_child_sheet_test.dart test/presentation/member_detail_managed_test.dart`
Expected: compile errors.

- [ ] **Step 3: The add sheet**

`lib/presentation/widgets/add_managed_child_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics.dart';
import '../../di/riverpod_container.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../providers/riverpod/auth_notifier.dart';
import '../providers/riverpod/family_notifier.dart';
import '../theme/app_tokens.dart';

/// Asks for a name and adds a child with no phone of their own to
/// [familyId]. [source] says where it was opened from, for analytics
/// ('onboarding', 'home_card' or 'family_tab').
///
/// :returns: the new member's id, or null if the sheet was dismissed.
Future<UserId?> showAddManagedChildSheet(
  BuildContext context,
  WidgetRef ref, {
  required FamilyId familyId,
  required String source,
}) async {
  final childId = await showModalBottomSheet<UserId>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddManagedChildSheet(familyId: familyId, source: source),
  );
  if (childId != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Added. Hand them your phone from the Family tab.'),
    ));
  }
  return childId;
}

class _AddManagedChildSheet extends ConsumerStatefulWidget {
  const _AddManagedChildSheet({required this.familyId, required this.source});

  final FamilyId familyId;
  final String source;

  @override
  ConsumerState<_AddManagedChildSheet> createState() => _AddManagedChildSheetState();
}

class _AddManagedChildSheetState extends ConsumerState<_AddManagedChildSheet> {
  final _name = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(addManagedChildUseCaseProvider)(
      familyId: widget.familyId,
      name: _name.text,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = failure.message;
      }),
      (childId) {
        final userId = ref.read(authNotifierProvider).user?.id.value;
        if (userId != null) {
          ref.read(analyticsProvider).log(
                AnalyticsEventName.managedChildAdded,
                userId: userId,
                familyId: widget.familyId.value,
                params: {'source': widget.source},
              );
        }
        ref.invalidate(familyMembersNotifierProvider(widget.familyId));
        Navigator.of(context).pop(childId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add a child without a phone',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            "They'll use Chores Star on your phone. Open them from the Family "
            'tab and tap "Hand the phone to…". You can move them to their own '
            'phone later, stars and all.',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('managed_child_name_field'),
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Their name',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onSubmitted: (_) => _add(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('managed_child_add_button'),
            onPressed: _saving ? null : _add,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add'),
          ),
        ],
      ),
    );
  }
}
```

(The error shows once, through the field's `errorText`; drop the unused `app_tokens.dart` import if the analyzer flags it.)

- [ ] **Step 4: Entry points**

`InviteYourFamilyScreen`: add `bool _addedChild = false;`. In `_continue`, change `if (!_hasShared)` to `if (!_hasShared && !_addedChild)`. After the Copy button add:

```dart
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('invite_step_add_child_button'),
                icon: const Icon(Icons.child_care),
                label: const Text('Add a child without a phone'),
                onPressed: () async {
                  final id = await showAddManagedChildSheet(context, ref,
                      familyId: widget.family.id, source: 'onboarding');
                  if (id != null && mounted) setState(() => _addedChild = true);
                },
              ),
```

and change the continue label to `Text(_hasShared || _addedChild ? 'Done' : 'Maybe later')`.

`InviteFamilyCard`: add `required this.onAddChild` / `final VoidCallback onAddChild;`, and after the `ShareInviteButton` line:

```dart
                  TextButton(
                    key: const Key('invite_family_card_add_child'),
                    onPressed: onAddChild,
                    child: const Text('Add a child without a phone'),
                  ),
```

`HomeScreen._buildInviteCard`: pass

```dart
      onAddChild: () => showAddManagedChildSheet(context, ref,
          familyId: currentUser.familyId, source: 'home_card'),
```

`FamilyScreen._FamilyDetailsView`: in the members `Card`, change each `ListTile`'s subtitle to

```dart
                          subtitle: Text(members[i].isManaged
                              ? '${members[i].role.displayName} · No phone'
                              : members[i].role.displayName),
```

and after the members `membersAsync.when(...)` add:

```dart
              if (currentUser.role.isAdmin)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('family_add_child_button'),
                    icon: const Icon(Icons.child_care),
                    label: const Text('Add a child without a phone'),
                    onPressed: () => showAddManagedChildSheet(context, ref,
                        familyId: currentUser.familyId, source: 'family_tab'),
                  ),
                ),
```

- [ ] **Step 5: Member page actions**

In `MemberDetailScreen`, inside the `SliverToBoxAdapter`'s `Column` children, between `_HeaderCard(...)` and the segmented control, add:

```dart
                    _ManagedChildActions(member: widget.member),
```

and add the widget at the bottom of the file:

```dart
/// Hand the phone over, move to their own phone, or remove: only for a
/// parent or guardian looking at a managed child (see canActForMember).
class _ManagedChildActions extends ConsumerWidget {
  const _ManagedChildActions({required this.member});

  final User member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewer = ref.watch(authNotifierProvider).user;
    if (viewer == null || !canActForMember(viewer: viewer, member: member)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            icon: const Icon(Icons.phone_iphone),
            label: Text('Hand the phone to ${member.name}'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  ChildModeScreen(childId: member.id, parentName: viewer.name),
            )),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.qr_code),
            label: Text('Move ${member.name} to their own phone'),
            onPressed: () => _showLinkCode(context, ref),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.tokens.brick),
            onPressed: () => _remove(context, ref),
            child: Text('Remove ${member.name}'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLinkCode(BuildContext context, WidgetRef ref) async {
    final LinkCode link;
    try {
      link = await ref
          .read(managedChildRepositoryProvider)
          .createLinkCode(member.familyId, member.id);
    } on DataException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Move ${member.name} to their own phone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('On ${member.name}\'s phone: install Chores Star, tap '
                '"I\'m a kid", then "Use a link code", and enter:'),
            const SizedBox(height: 16),
            SelectableText(
              formatInviteCode(link.code),
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text('It works once, for 24 hours.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${member.name}?'),
        content: Text('${member.name}\'s chores go back to the family, and '
            'their stars are gone for good.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(managedChildRepositoryProvider)
          .removeManagedChild(member.familyId, member.id);
    } on DataException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    ref.invalidate(familyMembersNotifierProvider(member.familyId));
    if (context.mounted) Navigator.of(context).pop();
  }
}
```

Add the imports this needs (`core/error/exceptions.dart`, `di/riverpod_container.dart`, `domain/repositories/managed_child_repository.dart`, `domain/services/managed_child_policy.dart`, `domain/usecases/family/join_family_usecase.dart` show `formatInviteCode`, `providers/riverpod/auth_notifier.dart`, `providers/riverpod/family_notifier.dart`, `screens/child_mode_screen.dart`). In `_HeaderCard`, change the role line to show `'${member.role.displayName} · No phone'` when `member.isManaged`.

- [ ] **Step 6: Run tests and analyzer**

Run: `flutter test test/presentation/add_managed_child_sheet_test.dart test/presentation/member_detail_managed_test.dart && flutter analyze && flutter test`
Expected: all pass. Existing invite tests still pass (update any that construct `InviteFamilyCard` to pass `onAddChild: () {}`).

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/widgets/add_managed_child_sheet.dart lib/presentation/screens/invite_your_family_screen.dart lib/presentation/widgets/home/invite_family_card.dart lib/presentation/screens/home_screen.dart lib/presentation/screens/family_screen.dart lib/presentation/screens/member_detail_screen.dart test/presentation/
git commit -m "Add, hand over, move and remove a child without a phone" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 11: Linking on the child's own phone

**Files:**
- Create: `lib/presentation/screens/link_child_device_screen.dart`
- Modify: `lib/presentation/screens/child_join_screen.dart`
- Modify: `lib/presentation/providers/riverpod/auth_notifier.dart` (new method next to `joinFamilyAsChild`, ~line 447)
- Test: `test/presentation/link_child_device_screen_test.dart`

**Interfaces:**
- Consumes: `linkChildDeviceUseCaseProvider` (Task 7), `AnalyticsEventName.linkCodeRedeemed` (Task 9).
- Produces: `AuthNotifier.linkChildDevice({required String code}) -> Future<void>`; `LinkChildDeviceScreen`.

- [ ] **Step 1: Write the failing widget test**

`test/presentation/link_child_device_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/main.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_managed_child_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';

/// Opens the link-code screen from the signed-out login stack. The mock
/// repository returns the code as the token and the mock auth signs in with
/// the token as the uid, so entering 'kid_uid' signs in as users/kid_uid.
Future<void> _openLinkScreen(
  WidgetTester tester,
  MockManagedChildRepository repo,
) async {
  final users = MockUserRepository();
  await users.createUserProfile(User(
    id: UserId('kid_uid'),
    name: 'Amira',
    familyId: FamilyId('family_1'),
    role: UserRole.child,
    points: Points(5),
    joinedAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ));
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => users),
      familyRepositoryProvider.overrideWith((_) => MockFamilyRepository()),
      taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
      notificationRepositoryProvider.overrideWith((_) => MockNotificationRepository()),
      managedChildRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(theme: appLightTheme, home: const FamilyGate()),
  ));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.textContaining("I'm a kid"));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('child_link_code_button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a good code signs this phone in as the child', (tester) async {
    await _openLinkScreen(tester, MockManagedChildRepository());

    await tester.enterText(find.byKey(const Key('link_code_field')), 'kid_uid');
    await tester.tap(find.byKey(const Key('link_code_submit')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('link_code_field')), findsNothing,
        reason: 'signed in as the child, routing has left the login stack');
  });

  testWidgets("a refused code shows the server's message", (tester) async {
    final repo = MockManagedChildRepository()
      ..refusedCodes['OLD'] = 'This code has expired. Ask a parent for a new one.';
    await _openLinkScreen(tester, repo);

    await tester.enterText(find.byKey(const Key('link_code_field')), 'OLD');
    await tester.tap(find.byKey(const Key('link_code_submit')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('This code has expired. Ask a parent for a new one.'),
        findsOneWidget);
  });
}
```

If `FamilyGate` is not exported from `main.dart`, import it from where `rewards_settle_reclaim_test.dart` gets it (that test imports `package:hoque_family_chores/main.dart`).

- [ ] **Step 2: Run and watch it fail**

Run: `flutter test test/presentation/link_child_device_screen_test.dart`
Expected: fails to find `child_link_code_button`.

- [ ] **Step 3: `AuthNotifier.linkChildDevice`**

After `joinFamilyAsChild`:

```dart
  /// Moves a managed child onto this phone with a parent's link code: signs in
  /// as the child's existing account, stars and history included.
  Future<void> linkChildDevice({required String code}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      status: AuthStatus.authenticating,
    );

    final result = await ref.read(linkChildDeviceUseCaseProvider)(code: code);

    result.fold(
      (failure) {
        _logger.e('AuthNotifier: Link failed: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
          status: AuthStatus.unauthenticated,
        );
      },
      (userId) {
        final analytics = ref.read(analyticsProvider);
        analytics.log(
          AnalyticsEventName.signedIn,
          userId: userId.value,
          params: const {'method': 'link_code'},
        );
        analytics.log(AnalyticsEventName.linkCodeRedeemed, userId: userId.value);
        _startUserProfileStream(userId);
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.authenticated,
        );
      },
    );
  }
```

- [ ] **Step 4: `LinkChildDeviceScreen`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/value_objects/shared_enums.dart';
import '../providers/riverpod/auth_notifier.dart';
import '../theme/app_tokens.dart';

/// For a child who has been using a parent's phone: enter the link code the
/// parent made ("Move … to their own phone") and carry on as the same member.
class LinkChildDeviceScreen extends ConsumerStatefulWidget {
  const LinkChildDeviceScreen({super.key});

  @override
  ConsumerState<LinkChildDeviceScreen> createState() => _LinkChildDeviceScreenState();
}

class _LinkChildDeviceScreenState extends ConsumerState<LinkChildDeviceScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    await ref.read(authNotifierProvider.notifier).linkChildDevice(code: _code.text);
    if (!mounted) return;
    if (ref.read(authNotifierProvider).status == AuthStatus.authenticated) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Use a link code')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ask a parent to open you in the Family tab and tap '
              '"Move … to their own phone". Type the code they see.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('link_code_field'),
              controller: _code,
              decoration: const InputDecoration(
                labelText: 'Link code',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
            ),
            if (authState.errorMessage?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  authState.errorMessage!,
                  style: TextStyle(color: context.tokens.brick),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            authState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    key: const Key('link_code_submit'),
                    onPressed: _link,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: const Text('Link this phone'),
                  ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: The link on "I'm a kid"**

In `ChildJoinScreen.build`, after the Join button:

```dart
            const SizedBox(height: 16),
            TextButton(
              key: const Key('child_link_code_button'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const LinkChildDeviceScreen(),
              )),
              child: const Text(
                "Already in your family on a parent's phone? Use a link code.",
                textAlign: TextAlign.center,
              ),
            ),
```

- [ ] **Step 6: Run tests and analyzer**

Run: `flutter test test/presentation/link_child_device_screen_test.dart && flutter analyze && flutter test`
Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/screens/link_child_device_screen.dart lib/presentation/screens/child_join_screen.dart lib/presentation/providers/riverpod/auth_notifier.dart test/presentation/link_child_device_screen_test.dart
git commit -m "Let a child move onto their own phone with a link code" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 12: Measure it in `usage_report.py`

**Files:**
- Modify: `scripts/usage_report.py`

**Interfaces:**
- Consumes: event names from Task 9; `managed` field on `users`.

- [ ] **Step 1: Count managed profiles and events**

Add the three names to `GROWTH_EVENT_NAMES`:

```python
    GROWTH_EVENT_NAMES = (
        "inviteStepShown",
        "inviteStepSkipped",
        "inviteShared",
        "memberJoined",
        "managedChildAdded",
        "childModeEntered",
        "linkCodeRedeemed",
    )
```

After the `Chores ever created` print:

```python
    managed = [u for u in users if field(u, "managed") is True]
    print(f"  Children without a phone:  {len(managed)}  (in {len({field(u, 'familyId') for u in managed})} families)")
```

Inside the funnel loop, after the `Members joined by code` line:

```python
        print(f"     Children added (no phone): {counts['managedChildAdded']}")
        print(f"     Phone handed to a child:   {counts['childModeEntered']}")
        print(f"     Moved to their own phone:  {counts['linkCodeRedeemed']}")
```

Update the module docstring's first paragraph to mention children without a phone.

- [ ] **Step 2: Run it (read-only)**

Run: `python3 scripts/usage_report.py`
Expected: the report prints with `Children without a phone:  0  (in 0 families)` and the three new funnel rows at 0 (feature not released yet). No errors.

- [ ] **Step 3: Commit**

```bash
git add scripts/usage_report.py
git commit -m "Report children without a phone in the usage report" -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 13: Deploy and verify end to end (owner approval required at each outward step)

**Files:** none (operational). Every step that changes production is confirmed with the owner first.

- [ ] **Step 1: Full local verification**

Run: `flutter analyze && flutter test && (cd test/rules && npm test && npm run test:functions && npm run test:managedFunctions)`
Expected: all green. Record the output.

- [ ] **Step 2: Check the custom-token permission (read-only)**

Run: `gcloud projects get-iam-policy hoque-family-chores-app --flatten="bindings[].members" --filter="bindings.role:roles/iam.serviceAccountTokenCreator" --format="table(bindings.members)"`
Expected: shows whether the functions' runtime service account (`<project-number>-compute@developer.gserviceaccount.com` for gen-2 functions) holds Token Creator. If not, **ask the owner**, then grant on that account itself:
`gcloud iam service-accounts add-iam-policy-binding <sa> --member=serviceAccount:<sa> --role=roles/iam.serviceAccountTokenCreator`

- [ ] **Step 3: Deploy rules, then functions (with owner sign-off)**

Run: `firebase deploy --only firestore:rules --project hoque-family-chores-app`, then `firebase deploy --only functions --project hoque-family-chores-app`
Expected: both succeed; `firebase functions:list` shows `addManagedChild`, `removeManagedChild`, `createLinkCode`, `redeemLinkCode`, `onAuthUserCreated`.

- [ ] **Step 4: Manual check on the iOS simulator (throwaway family, never the live board)**

Follow the `driving-the-ios-simulator` notes (one booted device; cliclick). With a fresh test adult account and a new family:
1. "Add a child without a phone" on the invite step → name "Test Kid". Family tab shows "Test Kid · Child · No phone".
2. Create a 5-star chore assigned to Test Kid. Member page → "Hand the phone to Test Kid" → chore shows with Done → tap Done → "Back to …".
3. Approve the chore in the parent's view → Test Kid shows 5 stars.
4. Add a 5-star treat → hand over → Treats → claim → Test Kid at 0 → "Not yet" → back to 5; the parent's own balance never moves and no "stars earned" celebration fires on the parent.
5. "Move Test Kid to their own phone" → note the code. On a second simulator (or the Android emulator): "I'm a kid" → "Use a link code" → enter it → lands on Home as Test Kid with 5 stars and the chore history. Back on the first device the "No phone" label is gone and the actions are hidden.
6. Re-entering a used code shows "That code didn't work. Check it, or ask a parent for a new one."
Record what passed and anything that did not.

- [ ] **Step 5: Report**

Summarise results to the owner with the test output from Step 1 and the manual checklist from Step 4. Building and shipping a release (TestFlight / Play alpha) is a separate decision for the owner.
