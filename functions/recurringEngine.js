// The recurring-chore spawner. Separated from index.js so the emulator
// integration test can drive it directly (onSchedule cannot be invoked via
// httpsCallable). Pure module: takes db, never calls initializeApp.
const { RRule } = require('rrule');
const { Timestamp } = require('firebase-admin/firestore');

/// Statuses that keep a slot occupied. A last-spawned occurrence still in any
/// of these holds the rule; only `completed` (or a deleted task) frees it.
/// `needsRevision` holds deliberately: the kid should fix the sent-back chore,
/// not get a fresh one stacked on top.
const OCCUPIED = new Set([
  'available', 'assigned', 'inProgress', 'pendingApproval', 'needsRevision',
]);

function toDate(v) {
  if (v && typeof v.toDate === 'function') return v.toDate();
  return v instanceof Date ? v : new Date(v);
}

/// rrule 2.8.x does all date arithmetic in UTC (getUTCDay, Date.UTC), while the
/// app's data model is local wall-clock dates — the client writes a local
/// midnight as a Timestamp and reads it back in the family's local time. To be
/// timezone-independent (the functions run in UTC but a family may be in any
/// offset), express a local date as a UTC wall-clock date for the engine, then
/// read the result back as a local midnight.
const asUTCWallClock = (d) =>
  new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
const asLocalMidnight = (d) =>
  new Date(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());

/// Spawn one due occurrence for [ruleRef], inside a transaction on the rule.
/// Returns { spawned, reason?, taskId? }.
///
/// [TimestampCtor] is the caller's firebase-admin Timestamp class. Defaulting
/// to our own is right in the functions runtime, but a test that drives this
/// module in-process must pass its own — otherwise the Timestamps we write are
/// rejected as a foreign object type by the test's Firestore instance (two
/// installed copies of firebase-admin are two different classes).
async function processRule(db, ruleRef, now, TimestampCtor) {
  const TS = TimestampCtor || Timestamp;
  const nowTs = TS.fromDate(now);
  return db.runTransaction(async (tx) => {
    const ruleSnap = await tx.get(ruleRef);
    if (!ruleSnap.exists) return { spawned: false, reason: 'rule-missing' };
    const rule = ruleSnap.data();
    if (!rule.enabled) return { spawned: false, reason: 'disabled' };

    // Idempotency gate: a concurrent tick that already advanced nextDueAt
    // commits first; the transaction serializes on the rule doc, so the
    // re-read here is the arbiter.
    const nextDueAt = toDate(rule.nextDueAt);
    if (!(nextDueAt instanceof Date) || isNaN(nextDueAt) || nextDueAt > now) {
      return { spawned: false, reason: 'not-due' };
    }

    const familyId = ruleRef.parent.parent.id;

    // Overlap gate: the last occurrence still holds the slot?
    if (rule.lastTaskId) {
      const lastSnap = await tx.get(
        db.doc(`families/${familyId}/tasks/${rule.lastTaskId}`),
      );
      if (lastSnap.exists && OCCUPIED.has(lastSnap.data().status)) {
        return { spawned: false, reason: 'slot-occupied' };
      }
      // A missing doc counts as resolved (the task was deleted).
    }

    // Parse the RRULE BEFORE creating anything: a structurally-broken rule
    // must not spawn (every tick would otherwise duplicate it). Disable it
    // and log once so the series stops erroring forever.
    const rruleString = rule.trigger && rule.trigger.rrule;
    if (!rruleString || !rruleString.trim()) {
      // An empty string would otherwise parse as a silent annual recurrence —
      // disable rather than spawn once a year by accident.
      console.error(`[recurring] Bad RRULE on ${ruleRef.id}:`, rruleString);
      await tx.update(ruleRef, { enabled: false, lastFiredAt: nowTs });
      return { spawned: false, reason: 'disabled-bad-rrule' };
    }
    let rrule;
    let next;
    try {
      const dtstart = asUTCWallClock(nextDueAt);
      rrule = new RRule({ ...RRule.parseString(rruleString), dtstart });
      next = rrule.after(dtstart);
    } catch (e) {
      console.error(
        `[recurring] Bad RRULE on ${ruleRef.id}: ${
          rule.trigger && rule.trigger.rrule
        }`, e.message,
      );
      await tx.update(ruleRef, { enabled: false, lastFiredAt: nowTs });
      return { spawned: false, reason: 'disabled-bad-rrule' };
    }

    const template = rule.template || {};
    if (!template.title || !Number(template.points)) {
      // tx.set() rejects undefined values (firebase-admin's serializer), so a
      // missing title or points would abort the transaction and leave the rule
      // enabled to error every tick. Disable it instead.
      console.error(
        `[recurring] Bad template on ${ruleRef.id}: missing title or points`,
      );
      await tx.update(ruleRef, { enabled: false, lastFiredAt: nowTs });
      return { spawned: false, reason: 'disabled-bad-template' };
    }
    const assigned = rule.assignment && rule.assignment.userId
      ? rule.assignment.userId
      : null;

    const taskRef = db.collection(`families/${familyId}/tasks`).doc();
    tx.set(taskRef, {
      title: template.title,
      description: template.description || '',
      status: assigned ? 'assigned' : 'available',
      difficulty: template.difficulty || 'easy',
      // Never back-date a spawned chore: a late catch-up lands "due today"
      // (start of the current day), not on the missed date.
      dueDate: TS.fromDate(dueOnOrAfter(nextDueAt, now)),
      assignedToId: assigned,
      createdById: rule.createdBy || '',
      createdAt: nowTs,
      points: Number(template.points) || 0,
      tags: template.tags || [],
      requiresPhotoProof: !!template.requiresPhotoProof,
      ruleId: ruleRef.id,
      version: 0,
    });

    if (!next) {
      // No further occurrences — end the series cleanly.
      tx.update(ruleRef, {
        enabled: false, nextDueAt: null,
        lastTaskId: taskRef.id, lastFiredAt: nowTs,
      });
      return { spawned: true, taskId: taskRef.id, reason: 'series-ended' };
    }

    tx.update(ruleRef, {
      nextDueAt: TS.fromDate(asLocalMidnight(next)),
      lastTaskId: taskRef.id,
      lastFiredAt: nowTs,
    });
    return { spawned: true, taskId: taskRef.id };
  });
}

/// max(due, start-of-today): the catch-up clamp. `now` is the tick time; the
/// semantic due date is the later of the rule's own nextDueAt and today's
/// midnight, so a delayed spawn is never back-dated.
function dueOnOrAfter(nextDueAt, now) {
  const todayMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  return nextDueAt > todayMidnight ? nextDueAt : todayMidnight;
}

/// Scan all enabled rules and spawn every due occurrence.
/// Returns { processed, spawned, skipped } for observability.
///
/// This collection-group query needs a MANUAL single-field index on
/// taskRules.enabled with COLLECTION_GROUP scope, declared in
/// firestore.indexes.json. Firestore only auto-creates collection-scope
/// indexes, and the emulator serves every query shape, so a missing index
/// surfaces only in production.
async function spawnDueOccurrences(db, { now = new Date(), Timestamp: TimestampCtor } = {}) {
  const rulesSnap = await db
    .collectionGroup('taskRules')
    .where('enabled', '==', true)
    .get();
  let processed = 0;
  let spawned = 0;
  for (const doc of rulesSnap.docs) {
    // Pre-filter in-process: rules are sparse (dozens per family app), so a
    // single-field query plus this date filter avoids a composite index.
    const nextDueAt = toDate(doc.data().nextDueAt);
    if (!(nextDueAt instanceof Date) || isNaN(nextDueAt) || nextDueAt > now) {
      continue;
    }
    try {
      const result = await processRule(db, doc.ref, now, TimestampCtor);
      // `processed` counts rules the engine actually fired for (a task was
      // spawned or an error thrown); deliberate skips (slot occupied, bad
      // rrule disabled, rule missing) count as `skipped`.
      if (result.spawned) {
        processed += 1;
        spawned += 1;
      }
    } catch (e) {
      // Fail loudly per rule, resilient as a batch: one bad rule must not
      // starve the rest. Firestore's transaction retry handles concurrent
      // ticks.
      console.error(`[recurring] Rule ${doc.id} failed:`, e.message);
      processed += 1;
    }
  }
  return { processed, spawned, skipped: rulesSnap.docs.length - processed };
}

module.exports = { processRule, spawnDueOccurrences };
