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
const zaynId = (await adb.collection('users').where('name', '==', 'Zayn').get()).docs[0].id;
await adb.doc('families/famA/tasks/zaynChore').set({ title: 'tidy', status: 'assigned', assignedToId: zaynId, points: 5 });
await adb.doc('profileLinks/ZAYNCODE2345').set({ childId: zaynId, familyId: 'famA' });
await expectFail('a child cannot remove one', 'permission-denied',
  callAs('teen', 'removeManagedChild', { familyId: 'famA', childId: zaynId }));
await expectFail('a signed-in member who is not managed cannot be removed this way', 'not-found',
  callAs('mum', 'removeManagedChild', { familyId: 'famA', childId: 'teen' }));
await expectOk('a parent removes a managed child',
  callAs('mum', 'removeManagedChild', { familyId: 'famA', childId: zaynId }));
await expectEq('the profile is gone', exists(`users/${zaynId}`), false);
await expectEq('the child is off the roster', (async () => (await memberIds('famA')).includes(zaynId))(), false);
await expectEq("the child's chore goes back to available",
  (async () => (await adb.doc('families/famA/tasks/zaynChore').get()).data().status)(), 'available');
await expectEq("the child's chore is unassigned",
  (async () => (await adb.doc('families/famA/tasks/zaynChore').get()).data().assignedToId)(), null);
await expectEq("the child's link code is deleted", exists('profileLinks/ZAYNCODE2345'), false);
await expectEq('the teen is untouched', exists('users/teen'), true);

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

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail > 0 ? 1 : 0);
