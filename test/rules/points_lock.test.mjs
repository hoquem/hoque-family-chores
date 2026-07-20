// The star economy is only honest if no client can write `points`. These prove
// the Firestore rules deny every client points change (self OR parent) while
// still allowing normal profile edits. All real point changes happen in the
// Cloud Functions (admin, which bypasses rules).
//
// Run:  firebase emulators:exec --only firestore --project demo-hoque \
//         "node test/rules/points_lock.test.mjs"
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { doc, setDoc, updateDoc } from 'firebase/firestore';

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
  await setDoc(doc(db, 'users/alice'), { familyId: 'famA', role: 'parent', points: 100, name: 'Alice' });
  await setDoc(doc(db, 'users/bob'), { familyId: 'famA', role: 'child', points: 50, name: 'Bob' });
  await setDoc(doc(db, 'families/famA'), { memberIds: ['alice', 'bob'], creatorId: 'alice' });
});

const alice = testEnv.authenticatedContext('alice').firestore(); // parent
const bob = testEnv.authenticatedContext('bob').firestore(); // child
const charlie = testEnv.authenticatedContext('charlie').firestore(); // new signup

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

console.log('\n-- points are off-limits to every client --');
await check('a child CANNOT change their own points', updateDoc(doc(bob, 'users/bob'), { points: 9999 }), false);
await check('a parent CANNOT change their own points', updateDoc(doc(alice, 'users/alice'), { points: 9999 }), false);
await check('a parent CANNOT change a child\'s points', updateDoc(doc(alice, 'users/bob'), { points: 9999 }), false);

console.log('\n-- normal profile edits still work --');
await check('a child CAN edit their own name', updateDoc(doc(bob, 'users/bob'), { name: 'Bobby' }), true);
await check('a parent CAN edit a family member (non-points)', updateDoc(doc(alice, 'users/bob'), { role: 'guardian' }), true);
await check('signing up with points > 0 is rejected', setDoc(doc(charlie, 'users/charlie'), { familyId: '', role: 'child', points: 500 }), false);
await check('signing up with points 0 is allowed', setDoc(doc(charlie, 'users/charlie'), { familyId: '', role: 'child', points: 0 }), true);

console.log(`\n${pass} passed, ${fail} failed`);
await testEnv.cleanup();
process.exit(fail > 0 ? 1 : 0);
