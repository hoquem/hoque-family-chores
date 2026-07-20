// Integration test for the star-economy Cloud Functions against the emulators.
// Verifies award (approve), the self-approve guard + parent override, spend
// (claim), the insufficient-stars guard, and refund + double-settle guard.
import adminPkg from 'firebase-admin';
import { initializeApp } from 'firebase/app';
import { getAuth, connectAuthEmulator, signInWithCustomToken } from 'firebase/auth';
import { getFunctions, connectFunctionsEmulator, httpsCallable } from 'firebase/functions';

const PROJECT = 'demo-hoque';
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';

const admin = adminPkg.initializeApp({ projectId: PROJECT });
const adb = adminPkg.firestore();
const aauth = adminPkg.auth();

// --- seed auth users + firestore ---
for (const uid of ['alice', 'bob', 'carol']) {
  await aauth.createUser({ uid }).catch(() => {});
}
await adb.doc('users/alice').set({ familyId: 'famA', role: 'parent', points: 0 });
await adb.doc('users/bob').set({ familyId: 'famA', role: 'child', points: 100 });
await adb.doc('users/carol').set({ familyId: 'famA', role: 'child', points: 0 });
await adb.doc('families/famA').set({ memberIds: ['alice', 'bob', 'carol'], creatorId: 'alice' });
await adb.doc('families/famA/tasks/task1').set({ title: 'chore', status: 'pendingApproval', assignedToId: 'bob', points: 100 });
await adb.doc('families/famA/tasks/task2').set({ title: 'parent chore', status: 'pendingApproval', assignedToId: 'alice', points: 30 });
await adb.doc('families/famA/rewards/rw1').set({ title: 'movie', cost: 60, timeframe: 'openEnded', createdBy: 'alice' });

// --- client wiring ---
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
const points = async (uid) => (await adb.doc(`users/${uid}`).get()).data().points;
const status = async (path) => (await adb.doc(path).get()).data().status;

let pass = 0, fail = 0;
async function expectOk(name, promise) {
  try { await promise; console.log(`  ok   ${name}`); pass++; }
  catch (e) { console.log(`  FAIL ${name} :: ${e.code || e.message}`); fail++; }
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

console.log('\n-- approve: award + self-approve guard + parent override --');
await expectFail('bob cannot approve his own task', 'permission-denied', callAs('bob', 'approveTask', { familyId: 'famA', taskId: 'task1' }));
await expectEq("bob's points unchanged after the denied self-approve", points('bob'), 100);
await expectOk('carol (peer) approves bob\'s task', callAs('carol', 'approveTask', { familyId: 'famA', taskId: 'task1' }));
await expectEq('bob awarded 100 stars', points('bob'), 200);
await expectEq('task1 is now completed', status('families/famA/tasks/task1'), 'completed');
await expectFail('re-approving a completed task fails', 'failed-precondition', callAs('carol', 'approveTask', { familyId: 'famA', taskId: 'task1' }));
await expectEq('no double award', points('bob'), 200);
await expectOk('a parent approves their OWN task (override)', callAs('alice', 'approveTask', { familyId: 'famA', taskId: 'task2' }));
await expectEq('alice awarded 30 stars', points('alice'), 30);

console.log('\n-- claim: spend + insufficient guard --');
await expectOk('bob claims the 60-star reward', callAs('bob', 'claimReward', { familyId: 'famA', rewardId: 'rw1' }));
await expectEq('bob spent 60 (200 -> 140)', points('bob'), 140);
await expectFail('carol cannot claim (0 < 60)', 'failed-precondition', callAs('carol', 'claimReward', { familyId: 'famA', rewardId: 'rw1' }));

// find bob's redemption id
const reds = await adb.collection('families/famA/redemptions').get();
const redId = reds.docs.find((d) => d.data().claimedBy === 'bob').id;

console.log('\n-- settle: only-claimant + refund + double-settle guard --');
await expectFail('carol cannot settle bob\'s claim', 'permission-denied', callAs('carol', 'settleRedemption', { familyId: 'famA', redemptionId: redId, happened: false }));
await expectOk('bob refunds his claim', callAs('bob', 'settleRedemption', { familyId: 'famA', redemptionId: redId, happened: false }));
await expectEq('bob refunded 60 (140 -> 200)', points('bob'), 200);
await expectFail('settling twice fails', 'failed-precondition', callAs('bob', 'settleRedemption', { familyId: 'famA', redemptionId: redId, happened: false }));
await expectEq('no double refund', points('bob'), 200);

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail > 0 ? 1 : 0);
