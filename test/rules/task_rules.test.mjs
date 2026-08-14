// taskRules collection (recurring chores): parents/guardians may create and
// delete, any family member may read, NOBODY may update. A rule's createdBy
// must be the writer's own uid — forging it fails. The spawner engine writes
// via the admin SDK, which bypasses rules entirely, so the update:false is for
// clients only.
//
// Run:  firebase emulators:exec --only firestore --project demo-hoque \
//         "node test/rules/task_rules.test.mjs"
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { doc, setDoc, updateDoc, deleteDoc, getDoc } from 'firebase/firestore';

const RULES = fileURLToPath(new URL('../../firestore.rules', import.meta.url));

const testEnv = await initializeTestEnvironment({
  projectId: 'demo-hoque',
  firestore: {
    rules: readFileSync(RULES, 'utf8'),
    host: '127.0.0.1',
    port: 8080,
  },
});

const parentUid = 'parent-1';
const childUid = 'kid-1';
const outsiderUid = 'outsider-1';

// Mirrors the doc shape the client's _mapRuleToFirestore writes and the
// recurringEngine reads: trigger, template, enabled, nextDueAt, lastTaskId,
// createdBy, createdAt.
function ruleDoc() {
  return {
    trigger: { type: 'schedule', rrule: 'FREQ=WEEKLY;BYDAY=SA' },
    template: {
      title: 'Clean the bathroom',
      description: '',
      difficulty: 'medium',
      points: 25,
      tags: [],
      requiresPhotoProof: false,
    },
    enabled: true,
    nextDueAt: new Date('2026-08-15T00:00:00Z'),
    lastTaskId: 'task-1',
    createdBy: parentUid,
    createdAt: new Date(),
  };
}

await testEnv.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, `users/${parentUid}`), { displayName: 'Parent', role: 'parent', familyId: 'fam-1' });
  await setDoc(doc(db, `users/${childUid}`), { displayName: 'Kid', role: 'child', familyId: 'fam-1' });
  // An outsider who is ALSO a parent — but of a different family. Read access
  // to fam-1 must still be denied: the role check alone is not enough.
  await setDoc(doc(db, `users/${outsiderUid}`), { displayName: 'Outsider', role: 'parent', familyId: 'fam-2' });
  await setDoc(doc(db, 'families/fam-1'), { name: 'Hoque', memberIds: [parentUid, childUid], creatorId: parentUid });
  await setDoc(doc(db, 'families/fam-2'), { name: 'Other', memberIds: [outsiderUid], creatorId: outsiderUid });
  // Two existing rules, so the read/update/delete assertions run against real
  // documents rather than exercising the emulator's no-op-on-missing paths.
  await setDoc(doc(db, 'families/fam-1/taskRules/rule-1'), ruleDoc());
  await setDoc(doc(db, 'families/fam-1/taskRules/rule-3'), ruleDoc());
});

const parent = testEnv.authenticatedContext(parentUid).firestore();
const child = testEnv.authenticatedContext(childUid).firestore();
const outsider = testEnv.authenticatedContext(outsiderUid).firestore();

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

console.log('\n-- creation: parents/guardians only, createdBy must be the writer --');
await check('a parent CAN create a taskRule carrying their own uid',
  setDoc(doc(parent, 'families/fam-1/taskRules/rule-new'), ruleDoc()), true);
await check('a parent CANNOT create a taskRule with a forged createdBy',
  setDoc(doc(parent, 'families/fam-1/taskRules/rule-forged'), { ...ruleDoc(), createdBy: 'someone-else' }), false);
await check('a child CANNOT create a taskRule',
  setDoc(doc(child, 'families/fam-1/taskRules/rule-2'), ruleDoc()), false);

console.log('\n-- reads: any family member, nobody outside the family --');
await check('a parent CAN read a taskRule',
  getDoc(doc(parent, 'families/fam-1/taskRules/rule-1')), true);
await check('a child CAN read a taskRule',
  getDoc(doc(child, 'families/fam-1/taskRules/rule-1')), true);
await check('an outsider (a parent of another family) CANNOT read a taskRule',
  getDoc(doc(outsider, 'families/fam-1/taskRules/rule-1')), false);

console.log('\n-- updates: forbidden for everyone (the engine writes via admin) --');
await check('a parent CANNOT update a taskRule (e.g. disable it)',
  updateDoc(doc(parent, 'families/fam-1/taskRules/rule-1'), { enabled: false }), false);
await check('a child CANNOT update a taskRule either',
  updateDoc(doc(child, 'families/fam-1/taskRules/rule-1'), { enabled: false }), false);

console.log('\n-- deletes: parents/guardians only --');
await check('a parent CAN delete a taskRule',
  deleteDoc(doc(parent, 'families/fam-1/taskRules/rule-3')), true);
await check('a child CANNOT delete a taskRule',
  deleteDoc(doc(child, 'families/fam-1/taskRules/rule-1')), false);

console.log(`\n${pass} passed, ${fail} failed`);
await testEnv.cleanup();
process.exit(fail > 0 ? 1 : 0);
