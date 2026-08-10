// `role` decides who may sign off a chore: `approveTask` lets a parent approve
// their own work, so a member who can promote themselves can mint stars. These
// prove the rules pin `role` once you are in a family, WITHOUT breaking the
// join, where picking parent or child is the whole point.
//
// Run:  firebase emulators:exec --only firestore --project demo-hoque \
//         "node test/rules/role_lock.test.mjs"
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
  // Dana has been accepted into famA's memberIds but her profile still carries
  // no family — the state a joiner is in when they write their own doc.
  await setDoc(doc(db, 'users/dana'), { familyId: '', role: 'child', points: 0, name: 'Dana' });
  // A second parent, so the parent-branch checks below don't depend on whether
  // an earlier assertion left Alice's own role intact.
  await setDoc(doc(db, 'users/erin'), { familyId: 'famA', role: 'parent', points: 0, name: 'Erin' });
  await setDoc(doc(db, 'families/famA'), { memberIds: ['alice', 'bob', 'dana', 'erin'], creatorId: 'alice' });
});

const alice = testEnv.authenticatedContext('alice').firestore(); // parent
const bob = testEnv.authenticatedContext('bob').firestore(); // child
const dana = testEnv.authenticatedContext('dana').firestore(); // joining
const erin = testEnv.authenticatedContext('erin').firestore(); // parent, untouched

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

console.log('\n-- a member in a family cannot re-grade themselves --');
await check('a child CANNOT promote themselves to parent',
  updateDoc(doc(bob, 'users/bob'), { role: 'parent' }), false);
await check('a child CANNOT promote themselves to guardian',
  updateDoc(doc(bob, 'users/bob'), { role: 'guardian' }), false);
await check('a child CANNOT smuggle a promotion alongside a name change',
  updateDoc(doc(bob, 'users/bob'), { name: 'Bobby', role: 'parent' }), false);
await check('a child CANNOT re-grade another member either',
  updateDoc(doc(bob, 'users/dana'), { role: 'child' }), false);
// The obvious dodge: the exemption keys off the OLD familyId, so clearing the
// family and promoting in one write must not buy anything.
await check('a child CANNOT clear their family and re-grade in one write',
  updateDoc(doc(bob, 'users/bob'), { familyId: '', role: 'parent' }), false);

console.log('\n-- the flows that legitimately set a role still work --');
await check('a joiner CAN pick their role as they join a family',
  updateDoc(doc(dana, 'users/dana'), { familyId: 'famA', role: 'parent' }), true);
await check('a parent CAN still set another member\'s role',
  updateDoc(doc(erin, 'users/bob'), { role: 'guardian' }), true);
// A parent editing their own role goes through the parent branch, which already
// requires being a parent — it grants nothing they did not have.
await check('a parent CAN step down from their own parent role',
  updateDoc(doc(alice, 'users/alice'), { role: 'child' }), true);
await check('a child CAN still edit their own name',
  updateDoc(doc(bob, 'users/bob'), { name: 'Bobby' }), true);
await check('a self-update that leaves role untouched is fine',
  updateDoc(doc(bob, 'users/bob'), { photoUrl: 'https://example.com/b.png' }), true);

console.log(`\n${pass} passed, ${fail} failed`);
await testEnv.cleanup();
process.exit(fail > 0 ? 1 : 0);
