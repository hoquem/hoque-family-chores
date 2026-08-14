// Engine integration test: drives functions/recurringEngine.js against the
// Firestore emulator. onSchedule cannot be invoked via httpsCallable, so the
// engine is a standalone module that takes db — this test imports it directly.
import { describe, it, beforeEach, after } from 'node:test';
import adminPkg from 'firebase-admin';
import assert from 'node:assert/strict';

const PROJECT = 'demo-hoque';
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';

const admin = adminPkg.initializeApp({ projectId: PROJECT }, 'engine-test');
const db = adminPkg.firestore(admin);
const Timestamp = adminPkg.firestore.Timestamp;

const { spawnDueOccurrences } = await import('../../functions/recurringEngine.js');

const midnight = (y, m, d) => new Date(y, m - 1, d);

function seedTask(db, familyId, taskId, status) {
  return db.doc(`families/${familyId}/tasks/${taskId}`).set({
    title: 'Existing occurrence', status,
    dueDate: Timestamp.fromDate(midnight(2026, 8, 14)),
  });
}

async function seedRule(db, familyId, ruleId, { rrule, nextDueAt, lastTaskId, enabled = true, points = 25 }) {
  const data = {
    trigger: { type: 'schedule', rrule },
    template: { title: 'Clean the bathroom', description: '', difficulty: 'medium', points, tags: [], requiresPhotoProof: false },
    enabled,
    nextDueAt: Timestamp.fromDate(nextDueAt),
    lastTaskId: lastTaskId ?? null,
    createdBy: 'parent-1',
    createdAt: Timestamp.fromDate(midnight(2026, 8, 1)),
  };
  if (lastTaskId) data.lastTaskId = lastTaskId;
  return db.doc(`families/${familyId}/taskRules/${ruleId}`).set(data);
}

async function tasks(db, familyId) {
  const snap = await db.collection(`families/${familyId}/tasks`).get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

async function rule(db, familyId, ruleId) {
  return (await db.doc(`families/${familyId}/taskRules/${ruleId}`).get()).data();
}

async function clean() {
  const f = await db.collection('families').listDocuments();
  await Promise.all(f.map((d) => db.recursiveDelete(d)));
}

describe('recurringEngine', () => {
  beforeEach(async () => {
    await clean();
    await db.doc('families/fam-1').set({ name: 'Hoque' });
    await db.doc('users/parent-1').set({ displayName: 'Parent', role: 'parent' });
  });
  after(async () => { await clean(); });

  it('spawns when due and the gate is open', async () => {
    await seedRule(db, 'fam-1', 'rule-1', { rrule: 'FREQ=WEEKLY;BYDAY=SA', nextDueAt: midnight(2026, 8, 14) });

    const res = await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 12, 0, 0), Timestamp });

    assert.equal(res.spawned, 1);
    const spawned = await tasks(db, 'fam-1');
    assert.equal(spawned.length, 1);
    assert.equal(spawned[0].title, 'Clean the bathroom');
    assert.equal(spawned[0].points, 25);
    assert.equal(spawned[0].status, 'available');
    assert.equal(spawned[0].createdById, 'parent-1');
    assert.equal(spawned[0].ruleId, 'rule-1');
    // Due date clamps to "today" (start of day) — never back-dated.
    assert.equal(spawned[0].dueDate.toDate().getTime(), new Date(2026, 7, 14).getTime());

    const r = await rule(db, 'fam-1', 'rule-1');
    assert.equal(r.lastTaskId, spawned[0].id);
    assert.equal(r.lastFiredAt.toDate().getTime(), new Date(2026, 7, 14, 12, 0, 0).getTime());
    // nextDueAt advanced to the next Saturday after 2026-08-14: 2026-08-15.
    assert.equal(r.nextDueAt.toDate().getTime(), new Date(2026, 7, 15).getTime());
  });

  it('holds when the slot is occupied (needsRevision included)', async () => {
    await seedRule(db, 'fam-1', 'rule-1', {
      rrule: 'FREQ=WEEKLY;BYDAY=SA', nextDueAt: midnight(2026, 8, 14), lastTaskId: 'task-1',
    });
    await seedTask(db, 'fam-1', 'task-1', 'needsRevision');

    const res = await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 12, 0, 0), Timestamp });

    assert.deepEqual(res, { processed: 0, spawned: 0, skipped: 1 });
    assert.equal((await tasks(db, 'fam-1')).length, 1);
    const r = await rule(db, 'fam-1', 'rule-1');
    assert.equal(r.nextDueAt.toDate().getTime(), new Date(2026, 7, 14).getTime()); // unchanged
  });

  it('spawns when the previous task doc is missing', async () => {
    await seedRule(db, 'fam-1', 'rule-1', {
      rrule: 'FREQ=WEEKLY;BYDAY=SA', nextDueAt: midnight(2026, 8, 14), lastTaskId: 'task-9',
    });

    const res = await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 12, 0, 0), Timestamp });

    assert.equal(res.spawned, 1);
    assert.equal((await tasks(db, 'fam-1')).length, 1);
  });

  it('is idempotent across concurrent ticks', async () => {
    await seedRule(db, 'fam-1', 'rule-1', { rrule: 'FREQ=WEEKLY;BYDAY=SA', nextDueAt: midnight(2026, 8, 14) });

    await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 12, 0, 0), Timestamp });
    const second = await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 12, 5, 0), Timestamp });

    assert.equal(second.spawned, 0);
    assert.equal((await tasks(db, 'fam-1')).length, 1);
  });

  it('skips a due-but-disabled rule', async () => {
    await seedRule(db, 'fam-1', 'rule-1', { rrule: 'FREQ=WEEKLY;BYDAY=SA', nextDueAt: midnight(2026, 8, 14), enabled: false });

    const res = await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 12, 0, 0), Timestamp });

    assert.equal(res.spawned, 0);
    assert.equal((await tasks(db, 'fam-1')).length, 0);
  });

  it('a per-rule error does not abort sibling rules', async () => {
    await seedRule(db, 'fam-1', 'rule-bad', {
      rrule: 'NOT-A-RRULE;;', nextDueAt: midnight(2026, 8, 14),
    });
    await seedRule(db, 'fam-1', 'rule-ok', { rrule: 'FREQ=DAILY', nextDueAt: midnight(2026, 8, 14) });

    const res = await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 12, 0, 0), Timestamp });

    // The bad rule must not be spawned again; the good one still fires.
    const rBad = await rule(db, 'fam-1', 'rule-bad');
    assert.equal(rBad.enabled, false); // engine disables a malformed rule and logs
    assert.equal((await tasks(db, 'fam-1')).length, 1);
    assert.equal((await tasks(db, 'fam-1'))[0].ruleId, 'rule-ok');
  });

  it('catch-up: a late completion spawns "due today", then settles to the RRULE', async () => {
    // Chore due Sat 2026-08-08 was completed late, on 2026-08-13. Tick on
    // 2026-08-14. The overdue occurrence is spawned "due today" and the rule
    // advances to its true cadence — the next Saturday 2026-08-15.
    await seedRule(db, 'fam-1', 'rule-1', {
      rrule: 'FREQ=WEEKLY;BYDAY=SA', nextDueAt: midnight(2026, 8, 8), lastTaskId: 'task-1',
    });
    await seedTask(db, 'fam-1', 'task-1', 'completed');

    await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 9, 0, 0), Timestamp });
    const first = (await tasks(db, 'fam-1')).find((t) => t.id !== 'task-1');
    assert.equal(first.dueDate.toDate().getTime(), new Date(2026, 7, 14).getTime()); // due today

    // Once the catch-up task is done the rule is aligned again: the next tick
    // on the restored Saturday fires normally and the cadence holds.
    await db.doc(`families/fam-1/tasks/${first.id}`).update({ status: 'completed' });
    const settle = await spawnDueOccurrences(db, { now: new Date(2026, 7, 15, 9, 0, 0), Timestamp });
    assert.equal(settle.spawned, 1);
    const r = await rule(db, 'fam-1', 'rule-1');
    assert.equal(r.nextDueAt.toDate().getTime(), new Date(2026, 7, 22).getTime()); // cadence restored
  });
});
