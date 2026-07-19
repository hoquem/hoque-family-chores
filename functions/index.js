// Star-economy Cloud Functions.
//
// Every change to a user's `points` happens here, on the trusted server, so a
// client can never forge stars (the Firestore rules deny all client writes to
// `points`). The three operations mirror the atomicity guards the app used to
// run client-side: a status re-read inside the transaction is the authoritative
// guard so nothing pays twice or leaves someone unpaid.
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();

const isParentRole = (role) => role === 'parent' || role === 'guardian';

function requireAuth(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Please sign in.');
  return uid;
}

function requireArgs(data, keys) {
  const out = {};
  for (const k of keys) {
    const v = data && data[k];
    if (v === undefined || v === null || v === '') {
      throw new HttpsError('invalid-argument', `Missing "${k}".`);
    }
    out[k] = v;
  }
  return out;
}

// Mirrors RewardTimeframe.dueFrom in the Dart app.
function dueFrom(timeframe, now) {
  if (timeframe === 'thisWeek') {
    // End of Sunday. Dart weekday is Mon=1..Sun=7; JS getDay is Sun=0..Sat=6.
    const weekday = now.getDay() === 0 ? 7 : now.getDay();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate() + (8 - weekday));
  }
  if (timeframe === 'thisMonth') {
    return new Date(now.getFullYear(), now.getMonth() + 1, 1);
  }
  return null; // openEnded
}

// Approve a completed task and award its stars to the doer. Anyone in the
// family may approve EXCEPT the doer — unless they are a parent/guardian, who
// may override (the app only offers that from the edit screen).
exports.approveTask = onCall(async (request) => {
  const uid = requireAuth(request);
  const { familyId, taskId } = requireArgs(request.data, ['familyId', 'taskId']);

  const approverRef = db.doc(`users/${uid}`);
  const taskRef = db.doc(`families/${familyId}/tasks/${taskId}`);

  await db.runTransaction(async (tx) => {
    const approverSnap = await tx.get(approverRef);
    const taskSnap = await tx.get(taskRef);
    if (!approverSnap.exists) throw new HttpsError('permission-denied', 'No profile found.');
    if (!taskSnap.exists) throw new HttpsError('not-found', 'Task not found.');

    const approver = approverSnap.data();
    const task = taskSnap.data();
    if (approver.familyId !== familyId) {
      throw new HttpsError('permission-denied', 'You are not in this family.');
    }
    if (task.status !== 'pendingApproval') {
      throw new HttpsError('failed-precondition', 'This task is not pending approval.');
    }
    const doerId = task.assignedToId;
    if (!doerId) throw new HttpsError('failed-precondition', 'This task has no assignee.');
    if (!isParentRole(approver.role) && doerId === uid) {
      throw new HttpsError('permission-denied', 'You need someone else to check this one off.');
    }

    const points = Number(task.points) || 0;
    tx.update(taskRef, {
      status: 'completed',
      approvedBy: uid,
      approvedAt: FieldValue.serverTimestamp(),
    });
    tx.update(db.doc(`users/${doerId}`), { points: FieldValue.increment(points) });
  });

  return { ok: true };
});

// Spend stars on a reward: deduct the cost and record the redemption in one
// transaction, refusing to go below zero.
exports.claimReward = onCall(async (request) => {
  const uid = requireAuth(request);
  const { familyId, rewardId } = requireArgs(request.data, ['familyId', 'rewardId']);

  const claimerRef = db.doc(`users/${uid}`);
  const rewardRef = db.doc(`families/${familyId}/rewards/${rewardId}`);
  const redemptionRef = db.collection(`families/${familyId}/redemptions`).doc();
  const now = new Date();

  await db.runTransaction(async (tx) => {
    const claimerSnap = await tx.get(claimerRef);
    const rewardSnap = await tx.get(rewardRef);
    if (!claimerSnap.exists) throw new HttpsError('permission-denied', 'No profile found.');
    if (!rewardSnap.exists) throw new HttpsError('not-found', 'Reward not found.');

    const claimer = claimerSnap.data();
    const reward = rewardSnap.data();
    if (claimer.familyId !== familyId) {
      throw new HttpsError('permission-denied', 'You are not in this family.');
    }
    const cost = Number(reward.cost) || 0;
    const current = Number(claimer.points) || 0;
    if (current < cost) {
      throw new HttpsError('failed-precondition', 'Not enough stars for that yet — keep going!');
    }

    const due = dueFrom(reward.timeframe, now);
    tx.update(claimerRef, { points: current - cost });
    tx.set(redemptionRef, {
      rewardId,
      rewardTitle: reward.title,
      cost,
      claimedBy: uid,
      claimedAt: Timestamp.fromDate(now),
      status: 'claimed',
      dueBy: due ? Timestamp.fromDate(due) : null,
      settledAt: null,
    });
  });

  return { ok: true, redemptionId: redemptionRef.id };
});

// Settle a claim. Only the claimant may judge their own claim; a refund returns
// the stars. The in-transaction status re-read prevents a double refund.
exports.settleRedemption = onCall(async (request) => {
  const uid = requireAuth(request);
  const { familyId, redemptionId } = requireArgs(request.data, ['familyId', 'redemptionId']);
  const happened = request.data && request.data.happened;
  if (typeof happened !== 'boolean') {
    throw new HttpsError('invalid-argument', 'Missing "happened".');
  }

  const redemptionRef = db.doc(`families/${familyId}/redemptions/${redemptionId}`);
  const now = new Date();

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(redemptionRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Claim not found.');
    const r = snap.data();
    if (r.claimedBy !== uid) {
      throw new HttpsError('permission-denied', 'Only the person who claimed this can settle it.');
    }
    if (r.status !== 'claimed') {
      throw new HttpsError('failed-precondition', 'That one is already settled.');
    }

    tx.update(redemptionRef, {
      status: happened ? 'fulfilled' : 'refunded',
      settledAt: Timestamp.fromDate(now),
    });
    if (!happened) {
      const cost = Number(r.cost) || 0;
      tx.update(db.doc(`users/${uid}`), { points: FieldValue.increment(cost) });
    }
  });

  return { ok: true };
});
