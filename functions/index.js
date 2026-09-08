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
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { spawnDueOccurrences } = require('./recurringEngine');

const geminiApiKey = defineSecret('GEMINI_API_KEY');

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
    imageUrl: data?.imageUrl || '',
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
  const approverPhoto = approverSnap.data()?.photoUrl || '';
  await notify(
    doerId,
    'Chore approved! 🎉',
    `'${taskTitle}' was checked off — you earned ${points}⭐`,
    { type: 'taskApproved', deepLink: 'choresapp://profile', actorId: uid, entityId: taskId, imageUrl: approverPhoto },
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
  const claimerSnap = await claimerRef.get();
  const claimerPhoto = claimerSnap.data()?.photoUrl || '';
  await notifyFamily(
    familyId,
    uid,
    `${claimerName} claimed a treat! 🎁`,
    `${claimerName} wants '${rewardTitle}' (${cost}⭐)`,
    { type: 'rewardClaimed', deepLink: 'choresapp://rewards', actorId: uid, entityId: redemptionRef.id, imageUrl: claimerPhoto },
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
  const settlerSnap = await db.doc(`users/${uid}`).get();
  const settlerPhoto = settlerSnap.data()?.photoUrl || '';
  await notify(
    uid,
    `Treat ${settledStatus} ${happened ? '✅' : '💫'}`,
    `'${rewardTitle}' was ${settledStatus}`,
    { type: 'rewardSettled', deepLink: 'choresapp://rewards', actorId: uid, entityId: redemptionId, imageUrl: settlerPhoto },
    `Treat ${settledStatus}`,
    `'${rewardTitle}' was ${settledStatus}`
  );

  return { ok: true };
});

// ---------------------------------------------------------------------------
// AI Mission Guide & Tips (Gemini 2.5 Flash)
// ---------------------------------------------------------------------------

async function callGeminiForGuide({ title, description, difficulty, parentTip, apiKey }) {
  const uri = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;

  const promptText = `
You are an encouraging family chore coach for kids aged 6 to 14.
Create a helpful, inspiring Mission Guide for this household chore:
- Title: "${title}"
${description ? `- Details: "${description}"` : ''}
- Effort Level: ${difficulty || 'Easy'}
${parentTip ? `- Home Context & Instructions from Parent: "${parentTip}"\n  (IMPORTANT: Weave these home-specific details/locations/rules into the steps so they fit this exact home!)` : ''}

Requirements:
1. "motivation": A fun, high-energy pep talk or playful challenge (e.g. "Put on your favorite 3-minute hype song and race the beat!", "Channel your inner ninja").
2. "steps": 3 or 4 clear, sequential, practical steps a child can follow to get the job done right.
3. "forYou": 1-2 sentences on why completing this task is good for the child (independence, peace of mind, feeling proud in their space).
4. "forFamily": 1-2 sentences on how this helps the whole family (teamwork, lifting the load, showing care).
5. "forHome": 1-2 sentences on why this makes the home a better place (cozy, clean, welcoming environment).
6. "takeaway": The real-life skill or superpower nurtured (e.g. "Organization & Focus: Big goals are won with small, steady habits").

Tone: Warm, playful, empowering, never patronizing, and kid-appropriate.
`;

  const requestBody = {
    contents: [
      {
        role: 'user',
        parts: [{ text: promptText }],
      },
    ],
    generationConfig: {
      responseMimeType: 'application/json',
      responseSchema: {
        type: 'OBJECT',
        properties: {
          motivation: { type: 'STRING', description: 'Playful, high-energy pep talk or challenge' },
          steps: { type: 'ARRAY', items: { type: 'STRING' }, description: '3 to 4 sequential actionable steps' },
          forYou: { type: 'STRING', description: 'Why doing this is good for the child' },
          forFamily: { type: 'STRING', description: 'How this helps the family' },
          forHome: { type: 'STRING', description: 'How this benefits the home' },
          takeaway: { type: 'STRING', description: 'Life skill or superpower takeaway' },
        },
        required: ['motivation', 'steps', 'forYou', 'forFamily', 'forHome', 'takeaway'],
      },
    },
  };

  const res = await fetch(uri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(requestBody),
  });

  if (!res.ok) {
    const errText = await res.text();
    console.error(`[Gemini] API error (${res.status}):`, errText);
    throw new HttpsError('internal', `Gemini API error: ${res.status}`);
  }

  const json = await res.json();
  const text = json.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) {
    throw new HttpsError('internal', 'Empty response from Gemini');
  }

  const parsed = JSON.parse(text);
  return {
    motivation: parsed.motivation || '',
    steps: Array.isArray(parsed.steps) ? parsed.steps : [],
    forYou: parsed.forYou || '',
    forFamily: parsed.forFamily || '',
    forHome: parsed.forHome || '',
    takeaway: parsed.takeaway || '',
    parentTip: parentTip || '',
  };
}

exports.generateChoreGuide = onCall({ secrets: [geminiApiKey] }, async (request) => {
  requireAuth(request);
  const data = request.data || {};
  const title = (data.title || '').trim();
  const description = (data.description || '').trim();
  const difficulty = (data.difficulty || 'easy').trim();
  const parentTip = (data.parentTip || '').trim();

  if (!title) {
    throw new HttpsError('invalid-argument', 'Chore title is required.');
  }

  let apiKey;
  try {
    apiKey = geminiApiKey.value();
  } catch (_) {
    apiKey = process.env.GEMINI_API_KEY;
  }

  if (!apiKey) {
    console.warn('[Gemini] GEMINI_API_KEY secret is not configured.');
    throw new HttpsError('unavailable', 'AI service is temporarily unconfigured.');
  }

  return await callGeminiForGuide({ title, description, difficulty, parentTip, apiKey });
});

// ---------------------------------------------------------------------------
// Firestore triggers — task lifecycle notifications
// ---------------------------------------------------------------------------

exports.onTaskCreated = onDocumentCreated({ document: 'families/{familyId}/tasks/{taskId}', secrets: [geminiApiKey] }, async (event) => {
  const { familyId, taskId } = event.params;
  const task = event.data.after.data();
  if (!task) return;

  const creatorSnap = await db.doc(`users/${task.createdById}`).get();
  const creatorName = creatorSnap.data()?.name || 'Someone';
  const creatorPhoto = creatorSnap.data()?.photoUrl || '';
  const title = task.title || 'a new chore';
  const points = Number(task.points) || 0;

  await notifyFamily(
    familyId,
    task.createdById,
    `New chore: ${title}`,
    `${creatorName} added a new chore worth ${points}⭐`,
    { type: 'taskCreated', deepLink: 'choresapp://tasks', actorId: task.createdById, entityId: taskId, imageUrl: creatorPhoto },
    `New chore! 📋`,
    `${creatorName} added "${title}" (${points}⭐)`
  );

  // Background AI guide enrichment if task has no guide or empty guide
  const hasValidGuide = task.guide && task.guide.motivation && Array.isArray(task.guide.steps) && task.guide.steps.length > 0;
  if (!hasValidGuide) {
    let apiKey;
    try {
      apiKey = geminiApiKey.value();
    } catch (_) {
      apiKey = process.env.GEMINI_API_KEY;
    }
    if (apiKey) {
      callGeminiForGuide({
        title,
        description: task.description || '',
        difficulty: task.difficulty || 'easy',
        parentTip: task.guide?.parentTip || '',
        apiKey,
      })
        .then(async (guide) => {
          const taskRef = db.doc(`families/${familyId}/tasks/${taskId}`);
          await taskRef.update({ guide });
          console.log(`[Gemini] Enriched task ${taskId} with AI mission guide.`);
        })
        .catch((err) => {
          console.warn(`[Gemini] Background task enrichment failed for ${taskId}:`, err.message);
        });
    }
  }
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
  const actorPhoto = actorSnap.data()?.photoUrl || '';

  // Claimed (available → assigned)
  if (oldStatus === 'available' && newStatus === 'assigned' && doerId) {
    await notifyFamily(
      familyId,
      doerId,
      `${actorName} is on it!`,
      `${actorName} claimed '${title}'`,
      { type: 'taskClaimed', deepLink: 'choresapp://tasks', actorId: doerId, entityId: taskId, imageUrl: actorPhoto }
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
      { type: 'taskCompleted', deepLink: 'choresapp://tasks', actorId: doerId, entityId: taskId, imageUrl: actorPhoto },
      'Done and sent for check ✅',
      `${actorName} finished '${title}'`
    );
    return;
  }

  // Sent back (pendingApproval → needsRevision)
  if (oldStatus === 'pendingApproval' && newStatus === 'needsRevision' && doerId) {
    const approverSnap = await db.doc(`users/${after.updatedById}`).get();
    const approverPhoto = approverSnap.data()?.photoUrl || '';
    await notify(
      doerId,
      'Have another go 🔄',
      `'${title}' was sent back`,
      { type: 'taskSentBack', deepLink: 'choresapp://tasks', actorId: after.updatedById || '', entityId: taskId, imageUrl: approverPhoto },
      'Have another go 🔄',
      `'${title}' was sent back`
    );
    return;
  }
});

// First scheduled function. Every 15 min at :07/:22/:37/:52 — off the
// :00/:15 crowd so the tick never lands on the same instant as other jobs.
exports.spawnRecurringTasks = onSchedule('7,22,37,52 * * * *', async (event) => {
  const result = await spawnDueOccurrences(db, { now: new Date() });
  console.log(
    `[recurring] tick: ${result.spawned} spawned, ${result.processed} processed, ${result.skipped} skipped`,
  );
});
