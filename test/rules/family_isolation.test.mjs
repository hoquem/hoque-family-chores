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
import { doc, deleteDoc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

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
  await setDoc(doc(db, 'users/alice'), { familyId: 'famA', role: 'parent', points: 0 });
  await setDoc(doc(db, 'users/bob'), { familyId: 'famB', role: 'parent', points: 0 });
  await setDoc(doc(db, 'families/famA'), { memberIds: ['alice'], creatorId: 'alice', name: 'A', inviteCode: 'CODEA' });
  await setDoc(doc(db, 'families/famB'), { memberIds: ['bob'], creatorId: 'bob', name: 'B', inviteCode: 'CODEB' });
  await setDoc(doc(db, 'familyInvites/CODEB'), { familyId: 'famB' });
  await setDoc(doc(db, 'families/famA/tasks/t1'), { title: 'A task' });
  await setDoc(doc(db, 'families/famB/tasks/t1'), { title: 'B task' });
  await setDoc(doc(db, 'families/famB/rewards/r1'), { title: 'B reward' });
  await setDoc(doc(db, 'families/famB/redemptions/rd1'), { rewardTitle: 'B claim' });
});

const alice = testEnv.authenticatedContext('alice').firestore();
const bob = testEnv.authenticatedContext('bob').firestore(); // a member of family B
// Nobody: no profile, no family. Used to show that a join request is what
// grants a stranger read access to a family, and that giving it up takes that
// access away again.
const carol = testEnv.authenticatedContext('carol').firestore();

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

console.log('\n-- Profile familyId + invite minting are tied to real membership --');
// The PII-leak chain: point your own profile at a victim family, then read its
// members. The familyId change must be refused for a family you are not in.
await check('alice CANNOT set her own familyId to family B', updateDoc(doc(alice, 'users/alice'), { familyId: 'famB' }), false);
await check('alice CANNOT forge an invite for family B (not a member)', setDoc(doc(alice, 'familyInvites/EVIL'), { familyId: 'famB' }), false);
// A real member can still mint an invite for their own family, and clear their
// own familyId (leaving).
await check('bob (a member) CAN mint an invite for family B', setDoc(doc(bob, 'familyInvites/BOBCODE'), { familyId: 'famB' }), true);
await check('a member CAN clear their own familyId (leaving)', updateDoc(doc(bob, 'users/bob'), { familyId: '' }), true);

console.log('\n-- Legitimate invite-code join still works end to end --');
await check('alice CAN create a join request with the correct code', setDoc(doc(alice, 'families/famB/joinRequests/alice'), { code: 'CODEB' }), true);
await check('after the join request, alice CAN read the family B doc', getDoc(doc(alice, 'families/famB')), true);
await check('after the join request, alice CAN add herself as a member', updateDoc(doc(alice, 'families/famB'), { memberIds: ['bob', 'alice'], updatedAt: new Date() }), true);
await check('now a member, alice CAN read family B tasks', getDoc(doc(alice, 'families/famB/tasks/t1')), true);
await check('now a member, alice CAN set her familyId to B (completing the join)', updateDoc(doc(alice, 'users/alice'), { familyId: 'famB' }), true);

// TASK-499. A join request used to be create-only, so the document the first
// join left behind could never be cleared or rewritten — and `set()` on an
// existing doc is an update. Leaving a family and coming back was therefore a
// permanent lockout, and leaving never gave up the read access the request
// granted. Both are fixed here, and the invite-code proof still has to hold.
console.log('\n-- Leaving a family, and coming back --');
// Written first because it is the check a sloppy fix fails: relaxing this to
// "the owner may write their own request" would let anyone who once joined ANY
// family rewrite the doc to point at a family they have no code for.
await check('alice CANNOT overwrite her own join request with a code for another family',
  setDoc(doc(alice, 'families/famB/joinRequests/alice'), { code: 'CODEA' }), false);
await check('alice CANNOT overwrite her own join request with a code that does not exist',
  setDoc(doc(alice, 'families/famB/joinRequests/alice'), { code: 'NOPE99' }), false);
// The self-heal path: this is what lets someone already locked out get back in
// without an app update, since their stale doc predates the fix.
await check('alice CAN overwrite her own join request with the correct code',
  setDoc(doc(alice, 'families/famB/joinRequests/alice'), { code: 'CODEB' }), true);
await check('bob CANNOT delete alice\'s join request',
  deleteDoc(doc(bob, 'families/famB/joinRequests/alice')), false);
await check('alice CAN delete her own join request (this is what leaving does)',
  deleteDoc(doc(alice, 'families/famB/joinRequests/alice')), true);

console.log('\n-- Giving up the join request gives up the access it bought --');
await check('carol (no family, no request) CANNOT read family B',
  getDoc(doc(carol, 'families/famB')), false);
await check('carol CAN create a join request with the correct code',
  setDoc(doc(carol, 'families/famB/joinRequests/carol'), { code: 'CODEB' }), true);
await check('with the request, carol CAN read family B',
  getDoc(doc(carol, 'families/famB')), true);
await check('carol CAN delete her own request',
  deleteDoc(doc(carol, 'families/famB/joinRequests/carol')), true);
await check('having given it up, carol CANNOT read family B again',
  getDoc(doc(carol, 'families/famB')), false);

console.log(`\n${pass} passed, ${fail} failed`);
await testEnv.cleanup();
process.exit(fail > 0 ? 1 : 0);
