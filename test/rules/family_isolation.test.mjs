// Cross-family data-isolation tests for firestore.rules, run against the
// Firestore emulator (a mock can't evaluate real security rules).
//
// Family A (alice) and family B (bob, invite code CODEB). Proves alice cannot
// reach B's data, that a bare family id no longer lets her read or join B, and
// that a legitimate invite-code join still works end to end.
//
// Run:  npm install   (once, in this dir)
//       firebase emulators:exec --only firestore --project demo-hoque \
//         "node test/rules/family_isolation.test.mjs"
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
  firestore: {
    rules: readFileSync(RULES, 'utf8'),
    host: '127.0.0.1',
    port: 8080,
  },
});

await testEnv.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, 'users/alice'), { familyId: 'famA', role: 'parent' });
  await setDoc(doc(db, 'users/bob'), { familyId: 'famB', role: 'parent' });
  await setDoc(doc(db, 'families/famA'), { memberIds: ['alice'], creatorId: 'alice', name: 'A', inviteCode: 'CODEA' });
  await setDoc(doc(db, 'families/famB'), { memberIds: ['bob'], creatorId: 'bob', name: 'B', inviteCode: 'CODEB' });
  await setDoc(doc(db, 'familyInvites/CODEB'), { familyId: 'famB' });
  await setDoc(doc(db, 'families/famA/tasks/t1'), { title: 'A task' });
  await setDoc(doc(db, 'families/famB/tasks/t1'), { title: 'B task' });
  await setDoc(doc(db, 'families/famB/rewards/r1'), { title: 'B reward' });
  await setDoc(doc(db, 'families/famB/redemptions/rd1'), { rewardTitle: 'B claim' });
});

const alice = testEnv.authenticatedContext('alice').firestore();

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

console.log('\n-- Core isolation (alice belongs only to family A) --');
await check('alice CAN read her own family task', getDoc(doc(alice, 'families/famA/tasks/t1')), true);
await check('alice CANNOT read family B task', getDoc(doc(alice, 'families/famB/tasks/t1')), false);
await check('alice CANNOT read family B reward', getDoc(doc(alice, 'families/famB/rewards/r1')), false);
await check('alice CANNOT read family B redemption', getDoc(doc(alice, 'families/famB/redemptions/rd1')), false);
await check('alice CANNOT write family B task', setDoc(doc(alice, 'families/famB/tasks/t1'), { title: 'hacked' }), false);
await check('alice CANNOT read family B user profile (bob)', getDoc(doc(alice, 'users/bob')), false);

console.log('\n-- A bare family id no longer grants read or join --');
await check('alice CANNOT get family B doc (no membership, no join request)', getDoc(doc(alice, 'families/famB')), false);
await check('alice CANNOT self-add to family B without a join request', updateDoc(doc(alice, 'families/famB'), { memberIds: ['bob', 'alice'], updatedAt: new Date() }), false);
await check('alice CANNOT create a join request with the WRONG code', setDoc(doc(alice, 'families/famB/joinRequests/alice'), { code: 'NOPE99' }), false);

console.log('\n-- Legitimate invite-code join still works end to end --');
await check('alice CAN create a join request with the correct code', setDoc(doc(alice, 'families/famB/joinRequests/alice'), { code: 'CODEB' }), true);
await check('after the join request, alice CAN read the family B doc', getDoc(doc(alice, 'families/famB')), true);
await check('after the join request, alice CAN add herself as a member', updateDoc(doc(alice, 'families/famB'), { memberIds: ['bob', 'alice'], updatedAt: new Date() }), true);
await check('now a member, alice CAN read family B tasks', getDoc(doc(alice, 'families/famB/tasks/t1')), true);

console.log(`\n${pass} passed, ${fail} failed`);
await testEnv.cleanup();
process.exit(fail > 0 ? 1 : 0);
