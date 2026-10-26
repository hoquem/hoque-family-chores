// Task photos for a managed child (no phone of their own). On the shared
// phone Firebase is signed in as the PARENT while the chore is assigned to the
// child, so "only the assignee uploads" would refuse every photo-proof chore
// in the child view. A parent of the family may upload for a MANAGED child's
// chore; a signed-in child's chore stays the child's alone.
// Runs against the storage + firestore emulators (cross-service rules).
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { doc, setDoc } from 'firebase/firestore';

const STORAGE_RULES = fileURLToPath(new URL('../../storage.rules', import.meta.url));

const testEnv = await initializeTestEnvironment({
  projectId: 'demo-hoque',
  // The firestore rules are irrelevant here (seeding bypasses them and the
  // storage rules read Firestore as the service), but the emulator needs some.
  firestore: { host: '127.0.0.1', port: 8080, rules: 'rules_version = "2"; service cloud.firestore { match /databases/{db}/documents { match /{d=**} { allow read, write: if false; } } }' },
  storage: { rules: readFileSync(STORAGE_RULES, 'utf8'), host: '127.0.0.1', port: 9199 },
});

await testEnv.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, 'users/mum'), { familyId: 'famA', role: 'parent', name: 'Mum' });
  await setDoc(doc(db, 'users/dad'), { familyId: 'famA', role: 'guardian', name: 'Dad' });
  await setDoc(doc(db, 'users/kid'), { familyId: 'famA', role: 'child', name: 'Kid', managed: true });
  await setDoc(doc(db, 'users/teen'), { familyId: 'famA', role: 'child', name: 'Teen' });
  await setDoc(doc(db, 'users/otherMum'), { familyId: 'famB', role: 'parent', name: 'Other' });
  await setDoc(doc(db, 'users/otherKid'), { familyId: 'famB', role: 'child', name: 'OtherKid', managed: true });
  await setDoc(doc(db, 'families/famA'), { memberIds: ['mum', 'dad', 'kid', 'teen'] });
  await setDoc(doc(db, 'families/famB'), { memberIds: ['otherMum', 'otherKid'] });
  await setDoc(doc(db, 'families/famA/tasks/kidChore'), { assignedToId: 'kid' });
  await setDoc(doc(db, 'families/famA/tasks/teenChore'), { assignedToId: 'teen' });
  // A famA task pointing at another family's managed child: that child's
  // profile must not unlock famA's photos.
  await setDoc(doc(db, 'families/famA/tasks/strayChore'), { assignedToId: 'otherKid' });
});

const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]);
const upload = (uid, taskId, contentType = 'image/jpeg') =>
  testEnv.authenticatedContext(uid).storage()
    .ref(`families/famA/tasks/${taskId}/before-123.jpg`)
    .put(JPEG, { contentType });

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

console.log('\n-- a managed child\'s chore photos --');
await check('a parent CAN upload for a managed child\'s chore', upload('mum', 'kidChore'), true);
await check('a guardian CAN upload for a managed child\'s chore', upload('dad', 'kidChore'), true);
await check('a parent CANNOT upload a non-JPEG for a managed child', upload('mum', 'kidChore', 'image/png'), false);
await check('a sibling CANNOT upload for a managed child\'s chore', upload('teen', 'kidChore'), false);
await check("another family's parent CANNOT upload for a managed child's chore", upload('otherMum', 'kidChore'), false);
await check("a parent CANNOT upload for another family's managed child on their own task", upload('mum', 'strayChore'), false);

console.log('\n-- a signed-in child\'s chore photos stay theirs --');
await check('a parent CANNOT upload for a signed-in child\'s chore', upload('mum', 'teenChore'), false);
await check('the assignee CAN upload for their own chore', upload('teen', 'teenChore'), true);
await check('the assignee CANNOT upload a non-JPEG', upload('teen', 'teenChore', 'image/png'), false);

console.log(`\n${pass} passed, ${fail} failed`);
await testEnv.cleanup();
process.exit(fail > 0 ? 1 : 0);
