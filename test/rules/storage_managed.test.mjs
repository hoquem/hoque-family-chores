// Task photos: the assignee, or any parent or guardian of the family, may
// attach, replace and remove a chore's photos (trust-based). That covers the
// child view, where Firebase is signed in as the PARENT while the chore is
// assigned to a managed child. Each allow must stay within the production
// limit of two Firestore documents per evaluation, which this emulator does
// not enforce (see the comment in storage.rules).
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
});

const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]);
const photo = (taskId) => `families/famA/tasks/${taskId}/before-123.jpg`;
const upload = (uid, taskId, contentType = 'image/jpeg') =>
  testEnv.authenticatedContext(uid).storage().ref(photo(taskId)).put(JPEG, { contentType });
const remove = (uid, taskId) =>
  testEnv.authenticatedContext(uid).storage().ref(photo(taskId)).delete();
// Puts a photo in place with rules off, so a delete check has something to hit.
const seedPhoto = (taskId) => testEnv.withSecurityRulesDisabled((ctx) =>
  ctx.storage().ref(photo(taskId)).put(JPEG, { contentType: 'image/jpeg' }));

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

console.log('\n-- a parent or guardian, for any of the family\'s chores --');
await check('a parent CAN upload for a managed child\'s chore', upload('mum', 'kidChore'), true);
await check('a guardian CAN upload for a managed child\'s chore', upload('dad', 'kidChore'), true);
await check('a parent CAN upload for a signed-in child\'s chore', upload('mum', 'teenChore'), true);
await check('a parent CANNOT upload a non-JPEG', upload('mum', 'kidChore', 'image/png'), false);
await seedPhoto('kidChore');
await check('a parent CAN delete a managed child\'s chore photo', remove('mum', 'kidChore'), true);
await seedPhoto('teenChore');
await check('a parent CAN delete a signed-in child\'s chore photo', remove('mum', 'teenChore'), true);

console.log('\n-- outsiders and other children --');
await check("another family's parent CANNOT upload", upload('otherMum', 'kidChore'), false);
await seedPhoto('kidChore');
await check("another family's parent CANNOT delete", remove('otherMum', 'kidChore'), false);
await check('a child who is not the assignee CANNOT upload', upload('teen', 'kidChore'), false);
await check('a child who is not the assignee CANNOT delete', remove('teen', 'kidChore'), false);

console.log('\n-- the assignee --');
await check('the assignee CAN upload for their own chore', upload('teen', 'teenChore'), true);
await check('the assignee CANNOT upload a non-JPEG', upload('teen', 'teenChore', 'image/png'), false);
await check('the assignee CAN delete their own chore photo', remove('teen', 'teenChore'), true);

console.log(`\n${pass} passed, ${fail} failed`);
await testEnv.cleanup();
process.exit(fail > 0 ? 1 : 0);
