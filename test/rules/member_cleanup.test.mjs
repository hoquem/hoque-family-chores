// Drives functions/memberCleanup.js against the Firestore emulator: what is
// released when a member's account is deleted, what is deliberately left, and
// that running the cleanup twice changes nothing (the auth trigger may retry).
import { describe, it, beforeEach, after } from 'node:test';
import adminPkg from 'firebase-admin';
import assert from 'node:assert/strict';

const PROJECT = 'demo-hoque';
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';

const admin = adminPkg.initializeApp({ projectId: PROJECT }, 'cleanup-test');
const db = adminPkg.firestore(admin);

const { releaseDeletedMember } = await import('../../functions/memberCleanup.js');

const task = (id) => db.doc(`families/famA/tasks/${id}`);
const data = async (ref) => (await ref.get()).data();

async function clean() {
  for (const c of ['families', 'users']) {
    const docs = await db.collection(c).listDocuments();
    await Promise.all(docs.map((d) => db.recursiveDelete(d)));
  }
}

async function seed() {
  await db.doc('families/famA').set({ memberIds: ['alice', 'gone'], creatorId: 'alice' });
  await db.doc('families/famB').set({ memberIds: ['zed'], creatorId: 'zed' });
  const t = (status, assignedToId) => ({ title: status, status, assignedToId, points: 10 });
  await task('assigned').set(t('assigned', 'gone'));
  await task('inProgress').set(t('inProgress', 'gone'));
  await task('needsRevision').set(t('needsRevision', 'gone'));
  await task('pending').set(t('pendingApproval', 'gone'));
  await task('completed').set(t('completed', 'gone'));
  await task('alices').set(t('assigned', 'alice'));
  await db.doc('families/famB/tasks/other').set(t('assigned', 'zed'));
  await db.doc('families/famA/taskRules/goneRule').set({
    enabled: true, template: { title: 'Bins', points: 5 }, assignment: { userId: 'gone' },
  });
  await db.doc('families/famA/taskRules/aliceRule').set({
    enabled: true, template: { title: 'Dishes', points: 5 }, assignment: { userId: 'alice' },
  });
}

async function snapshotAll() {
  const out = {};
  for (const path of ['families/famA', 'families/famB']) {
    out[path] = await data(db.doc(path));
    for (const sub of ['tasks', 'taskRules']) {
      const s = await db.collection(`${path}/${sub}`).get();
      s.docs.forEach((d) => { out[d.ref.path] = d.data(); });
    }
  }
  return out;
}

describe('releaseDeletedMember', () => {
  beforeEach(async () => { await clean(); await seed(); });
  after(async () => { await clean(); });

  it('returns unfinished chores (assigned, inProgress, needsRevision) to the pool', async () => {
    await releaseDeletedMember(db, 'gone');
    for (const id of ['assigned', 'inProgress', 'needsRevision']) {
      const t = await data(task(id));
      assert.equal(t.status, 'available', id);
      assert.equal(t.assignedToId, null, id);
    }
  });

  it('leaves pendingApproval and completed chores with the leaver (work was done)', async () => {
    await releaseDeletedMember(db, 'gone');
    assert.deepEqual(
      [(await data(task('pending'))).status, (await data(task('pending'))).assignedToId],
      ['pendingApproval', 'gone'],
    );
    assert.equal((await data(task('completed'))).status, 'completed');
    assert.equal((await data(task('completed'))).assignedToId, 'gone');
  });

  it('removes the uid from memberIds and touches no one else', async () => {
    await releaseDeletedMember(db, 'gone');
    assert.deepEqual((await data(db.doc('families/famA'))).memberIds, ['alice']);
    assert.deepEqual((await data(db.doc('families/famB'))).memberIds, ['zed']);
    assert.equal((await data(task('alices'))).assignedToId, 'alice');
    assert.equal((await data(db.doc('families/famB/tasks/other'))).assignedToId, 'zed');
  });

  it("unassigns the leaver's recurring rules so the engine stops spawning chores for them", async () => {
    await releaseDeletedMember(db, 'gone');
    const goneRule = await data(db.doc('families/famA/taskRules/goneRule'));
    assert.equal(goneRule.assignment, null);
    assert.equal(goneRule.enabled, true);
    const aliceRule = await data(db.doc('families/famA/taskRules/aliceRule'));
    assert.deepEqual(aliceRule.assignment, { userId: 'alice' });
  });

  it('reports what it did', async () => {
    const r = await releaseDeletedMember(db, 'gone');
    assert.deepEqual(r, { families: ['famA'], tasksReleased: 3, rulesUnassigned: 1 });
  });

  it('is idempotent: a second run is a no-op', async () => {
    await releaseDeletedMember(db, 'gone');
    const first = await snapshotAll();
    const r = await releaseDeletedMember(db, 'gone');
    assert.deepEqual(await snapshotAll(), first);
    assert.deepEqual(r, { families: [], tasksReleased: 0, rulesUnassigned: 0 });
  });

  it('is a no-op for a uid in no family', async () => {
    const before = await snapshotAll();
    const r = await releaseDeletedMember(db, 'nobody');
    assert.deepEqual(await snapshotAll(), before);
    assert.deepEqual(r, { families: [], tasksReleased: 0, rulesUnassigned: 0 });
  });
});
