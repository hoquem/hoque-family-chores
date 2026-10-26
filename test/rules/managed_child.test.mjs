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
