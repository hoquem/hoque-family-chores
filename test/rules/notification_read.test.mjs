// Why marking a notification read has to know its owner.
//
// Notifications live at users/{userId}/notifications/{id}. A repository method
// that took only a notification id could not address the document, so it
// scanned collection('users') to find the owner. firestore.rules permits
// reading a user document only if it is yours or a family member's — a
// per-document condition — so an unconstrained list over /users cannot be
// proven safe and Firestore rejects the whole query. The app's own family
// isolation was blocking its own writes, silently:
//
//   [FirebaseFirestore] Listen for query at users failed:
//   Missing or insufficient permissions.
//
// A fake Firestore cannot catch this, because it does not evaluate rules. This
// is the half only the emulator can prove. The other half — that the write
// lands on the right document and not a stranger's — is pinned in
// test/data/repositories/firebase_notification_repository_test.dart.
//
// Run:  npm install   (once, in this dir)
//       firebase emulators:exec --only firestore --project demo-hoque \
//         "node test/rules/notification_read.test.mjs"
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { collection, doc, getDocs, setDoc, updateDoc } from 'firebase/firestore';

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
  await setDoc(doc(db, 'users/kid1'), { familyId: 'famA', role: 'child', points: 0 });
  await setDoc(doc(db, 'users/kid2'), { familyId: 'famA', role: 'child', points: 0 });
  await setDoc(doc(db, 'users/stranger'), { familyId: 'famB', role: 'child', points: 0 });
  await setDoc(doc(db, 'users/kid1/notifications/n1'), {
    userId: 'kid1', title: 'Mum is on it!', message: '...', isRead: false,
  });
  await setDoc(doc(db, 'users/kid2/notifications/n1'), {
    userId: 'kid2', title: 'Someone else\'s', message: '...', isRead: false,
  });
});

const kid1 = testEnv.authenticatedContext('kid1').firestore();

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

console.log('notification read/write rules');

// THE ROOT CAUSE. This is the query the old implementation issued on every
// tap. If this ever starts succeeding, the isolation rules have been loosened
// and that is a much bigger problem than a stuck badge.
await check(
  'listing all users is denied — this is what the id-only scan attempted',
  assertFails(getDocs(collection(kid1, 'users'))),
);

// THE FIX. Addressing the document directly needs no list at all.
await check(
  'a user can mark their own notification read',
  assertSucceeds(updateDoc(doc(kid1, 'users/kid1/notifications/n1'), { isRead: true })),
);

await check(
  "a user cannot mark a sibling's notification read",
  assertFails(updateDoc(doc(kid1, 'users/kid2/notifications/n1'), { isRead: true })),
);

await testEnv.cleanup();

if (failures > 0) {
  console.error(`\n${failures} check(s) failed`);
  process.exit(1);
}
console.log('\nall checks passed');
