// Star-economy Cloud Functions.
//
// Every change to a user's `points` happens here, on the trusted server, so a
// client can never forge stars (the Firestore rules deny all client writes to
// `points`). The three operations mirror the atomicity guards the app used to
// run client-side: a status re-read inside the transaction is the authoritative
// guard so nothing pays twice or leaves someone unpaid.
//
// Notification triggers: task creation and status changes generate in-app
// notifications and FCM push messages so the family stays in sync.
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

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

// ---------------------------------------------------------------------------
// Notification helpers
// ---------------------------------------------------------------------------

/// Write an in-app notification doc to users/{uid}/notifications.
async function createInAppNotification(userId, payload) {
  const ref = db.collection(`users/${userId}/notifications`).doc();
  await ref.set({
    ...payload,
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  });
  return ref.id;
}

/// Send an FCM push to every token stored for a user.
async function sendPushToUser(userId, title, body, data) {
  const tokensSnap = await db.collection(`users/${userId}/fcmTokens`).get();
  const tokens = tokensSnap.docs.map((d) => d.id).filter((t) => t && t.length > 0);
  if (tokens.length === 0) return;

  const messaging = getMessaging();
  const sendPromises = tokens.map((token) =>
    messaging
      .send({
        token,
        notification: { title, body },
        data: data || {},
        apns: {
          payload: {
            aps: { badge: 1, sound: 'default' },
          },
        },
        android: {
          notification: { channelId: 'chores_channel', priority: 'high' },
        },
      })
      .catch((err) => {
        // Token may be stale; remove it silently.
        if (err.code === 'messaging/invalid-registration-token' ||
            err.code === 'messaging/registration-token-not-registered') {
          return db.collection(`users/${userId}/fcmTokens`).doc(token).delete();
        }
        console.error(`[FCM] Failed to send to ${token}:`, err.message);
      })
  );
  await Promise.all(sendPromises);
}

/// Create an in-app notification AND optionally send a push.
async function notify(userId, title, message, data, pushTitle, pushBody) {
  await createInAppNotification(userId, {
    title,
    message,
    type: data?.type || 'generic',
    deepLink: data?.deepLink || '',
    actorId: data?.actorId || '',
    entityId: data?.entityId || '',
  });
  if (pushTitle && pushBody) {
    await sendPushToUser(userId, pushTitle, pushBody, data);
  }
}

/// Notify every member of a family except one person.
async function notifyFamily(familyId, excludeUserId, title, message, data, pushTitle, pushBody) {
  const membersSnap = await db.collection('users').where('familyId', '==', familyId).get();
  const promises = [];
  membersSnap.docs.forEach((doc) => {
    const memberId = doc.id;
    if (memberId === excludeUserId) return;
    promises.push(notify(memberId, title, message, data, pushTitle, pushBody));
  });
  await Promise.all(promises);
}

// ---------------------------------------------------------------------------
// Callable functions (star economy)
// ---------------------------------------------------------------------------

// Approve a completed task and award its stars to the doer. Anyone in the
// family may approve EXCEPT the doer — unless they are a parent/guardian, who
// may override (the app only offers that from the edit screen).
exports.approveTask = onCall(async (request) => {
  const uid = requireAuth(request);
  const { familyId, taskId } = requireArgs(request.data, ['familyId', 'taskId']);

  const approverRef = db.doc(`users/${uid}`);
  const taskRef = db.doc(`families/${familyId}/tasks/${taskId}`);

  let doerId;
  let taskTitle;
  let points;

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
    doerId = task.assignedToId;
    if (!doerId) throw new HttpsError('failed-precondition', 'This task has no assignee.');
    if (!isParentRole(approver.role) && doerId === uid) {
      throw new HttpsError('permission-denied', 'You need someone else to check this one off.');
    }

    taskTitle = task.title || 'a chore';
    points = Number(task.points) || 0;

    tx.update(taskRef, {
      status: 'completed',
      approvedBy: uid,
      approvedAt: FieldValue.serverTimestamp(),
    });
    tx.update(db.doc(`users/${doerId}`), { points: FieldValue.increment(points) });
  });

  // Notify doer: their task was approved.
  const approverSnap = await approverRef.get();
  const approverName = approverSnap.data()?.name || 'Someone';
  await notify(
    doerId,
    'Chore approved! 🎉',
    `'${taskTitle}' was checked off — you earned ${points}⭐`,
    { type: 'taskApproved', deepLink: 'choresapp://profile', actorId: uid, entityId: taskId },
    'Chore approved! 🎉',
    `'${taskTitle}' was checked off — you earned ${points}⭐`
  );

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

  let claimerName;
  let rewardTitle;
  let cost;

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
    cost = Number(reward.cost) || 0;
    const current = Number(claimer.points) || 0;
    if (current < cost) {
      throw new HttpsError('failed-precondition', 'Not enough stars for that yet — keep going!');
    }

    claimerName = claimer.name || 'Someone';
    rewardTitle = reward.title || 'a treat';

    const due = dueFrom(reward.timeframe, now);
    tx.update(claimerRef, { points: current - cost });
    tx.set(redemptionRef, {
      rewardId,
      rewardTitle,
      cost,
      claimedBy: uid,
      claimedAt: Timestamp.fromDate(now),
      status: 'claimed',
      dueBy: due ? Timestamp.fromDate(due) : null,
      settledAt: null,
    });
  });

  // Notify family: someone claimed a treat.
  await notifyFamily(
    familyId,
    uid,
    `${claimerName} claimed a treat! 🎁`,
    `${claimerName} wants '${rewardTitle}' (${cost}⭐)`,
    { type: 'rewardClaimed', deepLink: 'choresapp://rewards', actorId: uid, entityId: redemptionRef.id },
    `${claimerName} claimed a treat! 🎁`,
    `${claimerName} wants '${rewardTitle}' (${cost}⭐)`
  );

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

  let rewardTitle;
  let settledStatus;

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

    rewardTitle = r.rewardTitle || 'a treat';
    settledStatus = happened ? 'fulfilled' : 'refunded';

    tx.update(redemptionRef, {
      status: settledStatus,
      settledAt: Timestamp.fromDate(now),
    });
    if (!happened) {
      const cost = Number(r.cost) || 0;
      tx.update(db.doc(`users/${uid}`), { points: FieldValue.increment(cost) });
    }
  });

  // Notify claimant: their treat was settled.
  await notify(
    uid,
    `Treat ${settledStatus} ${happened ? '✅' : '💫'}`,
    `'${rewardTitle}' was ${settledStatus}`,
    { type: 'rewardSettled', deepLink: 'choresapp://rewards', actorId: uid, entityId: redemptionId },
    `Treat ${settledStatus}`,
    `'${rewardTitle}' was ${settledStatus}`
  );

  return { ok: true };
});

// ---------------------------------------------------------------------------
// Firestore triggers — task lifecycle notifications
// ---------------------------------------------------------------------------

exports.onTaskCreated = onDocumentCreated('families/{familyId}/tasks/{taskId}', async (event) => {
  const { familyId, taskId } = event.params;
  const task = event.data.after.data();
  if (!task) return;

  const creatorSnap = await db.doc(`users/${task.createdById}`).get();
  const creatorName = creatorSnap.data()?.name || 'Someone';
  const title = task.title || 'a new chore';
  const points = Number(task.points) || 0;

  await notifyFamily(
    familyId,
    task.createdById,
    `New chore: ${title}`,
    `${creatorName} added a new chore worth ${points}⭐`,
    { type: 'taskCreated', deepLink: 'choresapp://tasks', actorId: task.createdById, entityId: taskId },
    `New chore! 📋`,
    `${creatorName} added "${title}" (${points}⭐)`
  );
});

exports.onTaskUpdated = onDocumentUpdated('families/{familyId}/tasks/{taskId}', async (event) => {
  const { familyId, taskId } = event.params;
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;

  const oldStatus = before.status;
  const newStatus = after.status;
  if (oldStatus === newStatus) return;

  const title = after.title || 'a chore';
  const doerId = after.assignedToId;
  const actorSnap = await db.doc(`users/${after.updatedById || doerId}`).get();
  const actorName = actorSnap.data()?.name || 'Someone';

  // Claimed (available → assigned)
  if (oldStatus === 'available' && newStatus === 'assigned' && doerId) {
    await notifyFamily(
      familyId,
      doerId,
      `${actorName} is on it!`,
      `${actorName} claimed '${title}'`,
      { type: 'taskClaimed', deepLink: 'choresapp://tasks', actorId: doerId, entityId: taskId }
    );
    return;
  }

  // Completed / sent for approval
  if ((oldStatus === 'assigned' || oldStatus === 'inProgress') && newStatus === 'pendingApproval' && doerId) {
    await notifyFamily(
      familyId,
      doerId,
      'Done and sent for check ✅',
      `${actorName} finished '${title}'`,
      { type: 'taskCompleted', deepLink: 'choresapp://tasks', actorId: doerId, entityId: taskId },
      'Done and sent for check ✅',
      `${actorName} finished '${title}'`
    );
    return;
  }

  // Sent back (pendingApproval → needsRevision)
  if (oldStatus === 'pendingApproval' && newStatus === 'needsRevision' && doerId) {
    await notify(
      doerId,
      'Have another go 🔄',
      `'${title}' was sent back`,
      { type: 'taskSentBack', deepLink: 'choresapp://tasks', actorId: after.updatedById || '', entityId: taskId },
      'Have another go 🔄',
      `'${title}' was sent back`
    );
    return;
  }
});
