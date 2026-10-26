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
