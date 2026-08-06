// Creating a family writes two documents, and the order is load-bearing.
//
// CreateFamilyUseCase mints an invite code, and FirebaseFamilyRepository writes
// families/{id} first and familyInvites/{code} second. That order is not a
// style choice: the invite rule requires isFamilyMember(familyId), which reads
// families/{familyId}.memberIds. Write the invite first and it is denied — the
// family would be created with a code nobody can ever join through, and the
// error surfaces after the family already exists.
//
// Nothing in the Dart tests can catch that: FakeFirebaseFirestore does not
// evaluate rules, so both orders pass there. This is the emulator's job.
//
// Also pinned here: an invite code cannot be overwritten. Codes are minted at
// random with no uniqueness check, so on a collision the second family's write
// must fail rather than silently repoint an existing code at a new family.
//
// Run:  npm install --prefix test/rules   (once)
//       firebase emulators:exec --only firestore --project demo-hoque \
//         "node test/rules/family_create.test.mjs"
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { doc, setDoc, deleteDoc, getDocs, collection } from 'firebase/firestore';

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
  await setDoc(doc(db, 'users/alice'), { familyId: '', role: 'child', points: 0 });
  await setDoc(doc(db, 'users/mallory'), { familyId: '', role: 'child', points: 0 });
  // An existing family with an existing invite code, to collide against.
  await setDoc(doc(db, 'families/famExisting'), {
    creatorId: 'someone', memberIds: ['someone'], name: 'Existing', inviteCode: 'TAKEN1',
  });
  await setDoc(doc(db, 'familyInvites/TAKEN1'), { familyId: 'famExisting' });
});

const alice = testEnv.authenticatedContext('alice').firestore();
const mallory = testEnv.authenticatedContext('mallory').firestore();

let failures = 0;
const check = async (name, promise) => {
  try {
    await promise;
    console.log(`  ok   ${name}`);
  } catch (e) {
    failures += 1;
    console.error(`  FAIL ${name}\n       ${e.message}`);
  }
};

console.log('family creation rules');

// THE ORDERING DEPENDENCY. Minting the invite before the family exists is
// denied, because isFamilyMember() has no memberIds to read yet.
await check(
  'the invite cannot be minted before the family document exists',
  assertFails(setDoc(doc(alice, 'familyInvites/NEWCOD'), { familyId: 'famAlice' })),
);

await check(
  'the family document can be created with its creator as a member',
  assertSucceeds(setDoc(doc(alice, 'families/famAlice'), {
    creatorId: 'alice', memberIds: ['alice'], name: 'Alice family', inviteCode: 'NEWCOD',
  })),
);

// Same write as the first check, now permitted purely because the family
// document exists. This pair is the ordering requirement.
await check(
  'the invite can be minted once the family document exists',
  assertSucceeds(setDoc(doc(alice, 'familyInvites/NEWCOD'), { familyId: 'famAlice' })),
);

// A family you are not a member of is not yours to mint codes for — otherwise
// anyone who learned a family id could forge a way in.
await check(
  "a stranger cannot mint an invite for someone else's family",
  assertFails(setDoc(doc(mallory, 'familyInvites/EVILCD'), { familyId: 'famAlice' })),
);

// Codes are random with no uniqueness check, so a collision must fail loudly
// rather than repoint an existing code at a different family.
await check(
  'an existing invite code cannot be repointed at another family',
  assertFails(setDoc(doc(alice, 'familyInvites/TAKEN1'), { familyId: 'famAlice' })),
);

await check(
  'an invite cannot be deleted',
  assertFails(deleteDoc(doc(alice, 'familyInvites/NEWCOD'))),
);

// Codes are guessed one at a time or not at all.
await check(
  'invites cannot be listed',
  assertFails(getDocs(collection(alice, 'familyInvites'))),
);

// A family cannot be created naming someone else as its creator.
await check(
  'a family cannot be created on behalf of someone else',
  assertFails(setDoc(doc(mallory, 'families/famForged'), {
    creatorId: 'alice', memberIds: ['alice'], name: 'Forged', inviteCode: 'FORGED',
  })),
);

await testEnv.cleanup();

if (failures > 0) {
  console.error(`\n${failures} check(s) failed`);
  process.exit(1);
}
console.log('\nall checks passed');
