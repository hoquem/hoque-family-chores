// Managed child profiles: a child with no phone of their own. The profile is
// an ordinary users/{childId} doc with `managed: true` and no auth user, so
// chores, stars, the leaderboard and approveTask treat it like any member.
// Everything that creates, removes, links or acts for one lives here, on the
// trusted server; the Firestore rules forbid clients from touching `managed`
// or `profileLinks`. Pure module: takes db/auth, never calls initializeApp.
const { HttpsError } = require('firebase-functions/v2/https');
const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const { randomInt } = require('crypto');
const { releaseDeletedMember } = require('./memberCleanup');

const MAX_MANAGED_CHILDREN = 10;
const MAX_NAME_LENGTH = 50;

const isAdultRole = (role) => role === 'parent' || role === 'guardian';

/**
 * Read the caller's profile and require a parent or guardian in ``familyId``.
 *
 * :param tx: the running transaction (all reads go through it).
 * :param db: Firestore admin instance.
 * :param uid: the caller's uid.
 * :param familyId: the family the call acts on.
 * :returns: the caller's profile data.
 */
async function requireAdultIn(tx, db, uid, familyId) {
  const snap = await tx.get(db.doc(`users/${uid}`));
  if (!snap.exists) throw new HttpsError('permission-denied', 'No profile found.');
  const me = snap.data();
  if (me.familyId !== familyId || !isAdultRole(me.role)) {
    throw new HttpsError('permission-denied', 'Only a parent or guardian in this family can do that.');
  }
  return me;
}

/**
 * Read ``childId`` and require a managed child of ``familyId``.
 *
 * :returns: the child's profile data.
 */
async function requireManagedChildIn(tx, db, childId, familyId) {
  const snap = await tx.get(db.doc(`users/${childId}`));
  const child = snap.exists ? snap.data() : null;
  if (!child || child.managed !== true || child.familyId !== familyId) {
    throw new HttpsError('not-found', "That child isn't in this family without a phone any more.");
  }
  return child;
}

/**
 * Create a managed child profile and add it to the family roster, atomically.
 *
 * :param db: Firestore admin instance.
 * :param uid: the calling parent or guardian.
 * :param args: ``{ familyId, name }``.
 * :returns: ``{ childId }``.
 */
async function addManagedChild(db, uid, { familyId, name }) {
  const trimmed = String(name || '').trim();
  if (!trimmed) throw new HttpsError('invalid-argument', 'Please enter a name.');
  if (trimmed.length > MAX_NAME_LENGTH) {
    throw new HttpsError('invalid-argument', 'That name is too long.');
  }
  const familyRef = db.doc(`families/${familyId}`);
  const childRef = db.collection('users').doc();
  await db.runTransaction(async (tx) => {
    await requireAdultIn(tx, db, uid, familyId);
    const family = await tx.get(familyRef);
    if (!family.exists) throw new HttpsError('not-found', 'Family not found.');
    const existing = await tx.get(
      db.collection('users').where('familyId', '==', familyId).where('managed', '==', true),
    );
    if (existing.size >= MAX_MANAGED_CHILDREN) {
      throw new HttpsError(
        'failed-precondition',
        `A family can have up to ${MAX_MANAGED_CHILDREN} children without a phone.`,
      );
    }
    const now = Timestamp.now();
    tx.set(childRef, {
      name: trimmed,
      role: 'child',
      familyId,
      points: 0,
      managed: true,
      createdBy: uid,
      joinedAt: now,
      updatedAt: now,
    });
    tx.update(familyRef, { memberIds: FieldValue.arrayUnion(childRef.id) });
  });
  return { childId: childRef.id };
}

/**
 * Release a managed child's chores and roster place, delete any link code
 * for them, then delete the profile. No permission checks: callers check.
 *
 * Order matters for a retry: the profile goes last, so a run that dies part
 * way leaves a profile the caller's checks still accept, and every step
 * before it is idempotent.
 */
async function releaseManagedChild(db, childId) {
  await releaseDeletedMember(db, childId);
  const codes = await db.collection('profileLinks').where('childId', '==', childId).get();
  await Promise.all(codes.docs.map((d) => d.ref.delete()));
  await db.doc(`users/${childId}`).delete();
}

/**
 * Remove a managed child from their family for good.
 *
 * :param args: ``{ familyId, childId }``.
 */
async function removeManagedChild(db, uid, { familyId, childId }) {
  await db.runTransaction(async (tx) => {
    await requireAdultIn(tx, db, uid, familyId);
    await requireManagedChildIn(tx, db, childId, familyId);
  });
  await releaseManagedChild(db, childId);
}

/**
 * Require that ``uid`` may act for ``memberId`` on the shared phone: a parent
 * or guardian in ``familyId`` acting for a managed child of that family.
 */
async function requireMayActFor(tx, db, uid, memberId, familyId) {
  await requireAdultIn(tx, db, uid, familyId);
  await requireManagedChildIn(tx, db, memberId, familyId);
}

module.exports = {
  MAX_MANAGED_CHILDREN,
  isAdultRole,
  requireAdultIn,
  requireManagedChildIn,
  requireMayActFor,
  addManagedChild,
  removeManagedChild,
  releaseManagedChild,
};
