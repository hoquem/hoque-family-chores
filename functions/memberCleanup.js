// Releases what a deleted account was holding in its family. Separated from
// index.js so the emulator test can drive it directly. Pure module: takes db,
// never calls initializeApp, and uses no FieldValue sentinels (the test passes
// a db from a different firebase-admin copy, which rejects foreign sentinels).

/// Unfinished statuses a leaver can never finish. Their chores go back to the
/// pool. `pendingApproval` is deliberately absent: the work was done, and
/// approveTask completes it without awarding stars to a missing profile.
const RELEASABLE = new Set(['assigned', 'inProgress', 'needsRevision']);

/**
 * Release a deleted member's hold on every family that lists them.
 *
 * Per family, in one transaction: unfinished chores assigned to ``uid`` go back
 * to ``available`` with ``assignedToId`` cleared (the client's unclaim shape),
 * recurring rules assigned to them become unassigned so the engine stops
 * spawning chores nobody can do, and ``uid`` leaves ``memberIds``.
 *
 * Families are found by ``memberIds``, not the profile's ``familyId``: this runs
 * after the auth user is deleted, when the profile doc is already gone.
 * Idempotent: once ``uid`` is off the roster the family no longer matches, and
 * every write is a plain value set, so a retried run changes nothing.
 *
 * :param db: Firestore admin instance.
 * :param uid: the deleted user's id.
 * :returns: ``{ families, tasksReleased, rulesUnassigned }``
 */
async function releaseDeletedMember(db, uid) {
  const familiesSnap = await db.collection('families')
    .where('memberIds', 'array-contains', uid)
    .get();

  const result = { families: [], tasksReleased: 0, rulesUnassigned: 0 };
  for (const familyDoc of familiesSnap.docs) {
    const familyRef = familyDoc.ref;
    const counts = await db.runTransaction(async (tx) => {
      const family = await tx.get(familyRef);
      const members = (family.exists && family.data().memberIds) || [];
      if (!members.includes(uid)) return null; // already released by a racing run

      const tasks = await tx.get(familyRef.collection('tasks').where('assignedToId', '==', uid));
      const rules = await tx.get(familyRef.collection('taskRules').where('assignment.userId', '==', uid));

      const releasable = tasks.docs.filter((d) => RELEASABLE.has(d.data().status));
      for (const t of releasable) {
        tx.update(t.ref, { status: 'available', assignedToId: null });
      }
      // The engine reads `assignment && assignment.userId`, so null is unassigned.
      for (const r of rules.docs) {
        tx.update(r.ref, { assignment: null });
      }
      tx.update(familyRef, { memberIds: members.filter((m) => m !== uid) });
      return { tasks: releasable.length, rules: rules.size };
    });
    if (counts) {
      result.families.push(familyRef.id);
      result.tasksReleased += counts.tasks;
      result.rulesUnassigned += counts.rules;
    }
  }
  return result;
}

module.exports = { releaseDeletedMember };
