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

const LINK_CODE_TTL_MS = 24 * 60 * 60 * 1000;
// Same alphabet and length as family invite codes (create_family_usecase.dart):
// no 0/O, 1/I/L, so a code read aloud survives the trip.
const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const CODE_LENGTH = 12;

function newLinkCode() {
  let code = '';
  for (let i = 0; i < CODE_LENGTH; i++) code += CODE_ALPHABET[randomInt(CODE_ALPHABET.length)];
  return code;
}

// Mirrors normaliseInviteCode in join_family_usecase.dart: spaces, dashes and
// case are how people write a long code down, not a different code.
const normaliseCode = (raw) => String(raw || '').toUpperCase().replace(/[^A-Z0-9]/g, '');

/**
 * Mint a one-time code that moves a managed child onto their own phone,
 * replacing any earlier code for that child.
 *
 * :returns: ``{ code, expiresAt }`` with ``expiresAt`` in epoch milliseconds.
 */
async function createLinkCode(db, uid, { familyId, childId }) {
  const code = newLinkCode();
  const expiresAt = Timestamp.fromMillis(Date.now() + LINK_CODE_TTL_MS);
  await db.runTransaction(async (tx) => {
    await requireAdultIn(tx, db, uid, familyId);
    await requireManagedChildIn(tx, db, childId, familyId);
    const old = await tx.get(db.collection('profileLinks').where('childId', '==', childId));
    for (const d of old.docs) tx.delete(d.ref);
    tx.set(db.doc(`profileLinks/${code}`), { childId, familyId, createdBy: uid, expiresAt });
  });
  return { code, expiresAt: expiresAt.toMillis() };
}

/**
 * Spend a link code and return a custom token for the child's existing uid.
 *
 * Does NOT clear ``managed``: the code is used up here, but the phone has not
 * signed in yet. ``markLinked`` (onAuthUserCreated) clears it once it has, so
 * a sign-in that fails leaves the child managed and a parent can make a new
 * code.
 *
 * :returns: ``{ token }``.
 */
async function redeemLinkCode(db, auth, { code }) {
  const id = normaliseCode(code);
  if (!id) throw new HttpsError('invalid-argument', 'Please enter the code.');
  const ref = db.doc(`profileLinks/${id}`);
  let childId;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new HttpsError('not-found', "That code didn't work. Check it, or ask a parent for a new one.");
    }
    const link = snap.data();
    const child = await tx.get(db.doc(`users/${link.childId}`));
    if (link.expiresAt.toMillis() < Date.now()) {
      throw new HttpsError('failed-precondition', 'This code has expired. Ask a parent for a new one.');
    }
    if (!child.exists || child.data().managed !== true) {
      throw new HttpsError('failed-precondition', 'This code is no longer valid. Ask a parent for a new one.');
    }
    tx.delete(ref);
    childId = link.childId;
  });
  return { token: await auth.createCustomToken(childId) };
}

/**
 * Clear ``managed`` once a managed child's uid really has signed in.
 */
async function markLinked(db, uid) {
  const ref = db.doc(`users/${uid}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists && snap.data().managed === true) {
      tx.update(ref, { managed: false, updatedAt: Timestamp.now() });
    }
  });
}

/**
 * Remove the managed children of any family in ``familyIds`` that has no
 * signed-in parent or guardian left. Nobody would be left who can hand them
 * the phone, approve their chores, or link them.
 *
 * :returns: how many managed children were removed.
 */
async function removeOrphanedManagedChildren(db, familyIds) {
  let removed = 0;
  for (const familyId of familyIds) {
    const members = await db.collection('users').where('familyId', '==', familyId).get();
    const hasAdult = members.docs.some((d) => isAdultRole(d.data().role) && d.data().managed !== true);
    if (hasAdult) continue;
    for (const d of members.docs.filter((m) => m.data().managed === true)) {
      await releaseManagedChild(db, d.id);
      removed++;
    }
  }
  return removed;
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
  newLinkCode,
  createLinkCode,
  redeemLinkCode,
  markLinked,
  removeOrphanedManagedChildren,
};
