# Recurring Chores — Design Spec

> **Status:** Approved design 2026-08-14. Ready for an implementation plan.
> **App:** Chores Star (`com.hoque.familychores` / `com.hoque.hoqueFamilyChores`)
> **Tickets:** Implements TASK-468 (Pillar 1, Layer 1 — recurring schedules); closes
> TASK-498 ("recurring chores: the field exists, the feature does not").
> **Parent design:** `docs/superpowers/specs/2026-07-22-self-maintaining-app-design.md`
> (the rule engine sketch this slice builds on).

## Vision

A parent sets *"clean the bathroom every Saturday"* once. From then on the chore
appears on schedule and the list keeps itself going — no one re-creates it each
week. The recurring series is a **rule**; each due occurrence is a normal **task**
doc the family claims, completes, and is approved on exactly as today.

Decisions locked in brainstorming (2026-08-14):

1. **Rule creation UX:** a "Repeat" selector on the existing add-task screen
   (Never / Daily / Weekly / Monthly). The first occurrence is created
   immediately so the family sees the chore right away.
2. **Assignment:** unassigned ("up for grabs") or a fixed child. Rotation
   (round-robin fairness) is deferred.
3. **Overlap:** the engine **waits for the previous occurrence to resolve**
   before spawning the next — an ignored chore never snowballs into a wall of
   identical overdue tasks.

## Data model

### New collection: `families/{familyId}/taskRules/{ruleId}`

```
trigger:    { type: "schedule", rrule: "FREQ=WEEKLY;BYDAY=SA" }   // iCal RRULE string
template:   { title, description, difficulty, points, tags, requiresPhotoProof }  // same shape as Task
assignment: null | { userId }                  // null = unassigned ("up for grabs"); else fixed child
enabled:    true
nextDueAt:  <timestamp>                        // when the next occurrence is due
lastTaskId: <taskId | null>                    // gating: wait for this occurrence to resolve
lastFiredAt: <timestamp>
createdBy:  <uid>                              // the parent who made the rule
createdAt:  <timestamp>
```

### Task doc addition

Spawned tasks carry one new field, `ruleId`. They are otherwise ordinary tasks:
existing client parsing and the existing `onTaskCreated` notification trigger
work unchanged. The client's `Task` entity gains a nullable `ruleId` read from
Firestore and nothing else.

The dead `recurringPattern` / `lastCompletedAt` fields on `Task` stay dead. The
rule engine supersedes the original single-task re-arm idea; do not wire them up.

### RRULE division of labour — no Dart dependency

The client's Repeat selector maps presets to RRULE strings with a small pure
helper:

| Preset  | RRULE                          |
|---------|--------------------------------|
| Daily   | `FREQ=DAILY`                   |
| Weekly  | `FREQ=WEEKLY;BYDAY=<weekday of the picked due date>` (SA, SU, …) |
| Monthly | `FREQ=MONTHLY;BYMONTHDAY=<day-of-month of the picked due date>` |

The client creates the rule with **`nextDueAt` = the first task's due date** and
lets the engine advance it from there. No RRULE computation happens in Dart; the
`rrule` npm package (the standard JS iCal library) is server-only.

## The engine

One new scheduled Cloud Function, `spawnRecurringTasks`, on a `*/15 * * * *`
Cloud Scheduler tick (the first scheduled function in `functions/index.js`).

Per tick, per due rule, inside a **transaction on the rule doc**:

1. **Scan:** `collectionGroup('taskRules').where('enabled', '==', true)`
   (single-field query — no composite index), then filter `nextDueAt <= now`
   in-process. Rules are sparse (dozens per family app), so this is fine.
2. **Re-read + gate** (the idempotency mechanism): re-read the rule inside the
   transaction. If `nextDueAt > now`, skip — a concurrent tick already advanced
   it; Firestore transactions serialize on the rule doc, so two ticks cannot
   both pass. Then apply the overlap gate:
   - `lastTaskId` is set **and** that task exists **and** its status is not
     `completed` → **skip** (slot occupied). All of `available`, `assigned`,
     `inProgress`, `pendingApproval`, `needsRevision` hold the slot — including
     `needsRevision`, deliberately: the kid should fix the sent-back chore, not
     get a fresh one stacked on top.
   - a missing task doc counts as resolved (task was deleted).
3. **Spawn** (same transaction): create the task doc from `template` +
   `assignment`. `createdById` = rule `createdBy`. Due date =
   `max(nextDueAt, today)` so a late catch-up never spawns a back-dated chore,
   where `today` is the start of the current day at midnight, matching the
   app's date-only due-date convention.
4. **Advance** (same transaction): rule `nextDueAt = rrule.after(nextDueAt)`,
   `lastTaskId` = new task id, `lastFiredAt` = now.
5. **Notify:** none new. The existing `onTaskCreated` Firestore trigger already
   announces every new task. Consequence: the push reads "«rule creator» added
   a new chore" — the rule creator is the `createdById`, so the copy is
   attributable to them. Accepted for MVP.

**Catch-up behaviour** falls out naturally: a chore completed two weeks late
spawns the next one "due today", and once the family is current the cadence
settles to the RRULE.

### Known simplification: one timezone

The household is single-timezone (UK). `rrule` computes in UTC; a due date
stored at local midnight is 23:00 UTC the day before, and the 15-minute tick
absorbs the drift. Full per-family timezone handling is out of scope for the
MVP and noted here so a future planner does not rediscover it.

## Client changes

1. **Repeat selector on add-task** (`lib/presentation/screens/add_task_screen.dart`):
   a "Repeat" row — Never / Daily / Weekly / Monthly — shown to **parents only**.
   The pattern derives from the picked due date (Weekly recurs on that weekday,
   Monthly on that day-of-month). Selecting a repeat makes the submit a
   **batch write** (one atomic commit): the first task doc **and** the rule doc
   (`nextDueAt` = the task's due date, `lastTaskId` = the new task id). Task
   validation reuses the existing `CreateTaskUseCase` rules.
2. **Recurring badge + "Stop repeating" on task details**
   (`lib/presentation/screens/task_details_screen.dart`): tasks with `ruleId`
   show a "Recurring" badge; parents get a "Stop repeating" action that deletes
   the rule doc. Existing occurrences stay — they are ordinary tasks now. This
   is the MVP's only way to turn a series off, so it is in scope, not polish.
   If the `ruleId` points at a deleted rule, the affordance is hidden (no
   error) — `get` on the rule returns empty.
3. **Preset → RRULE helper** (`lib/domain/.../recurrence.dart` or similar): a
   pure function, unit-tested.
4. A parent may also simply delete the task itself, which also frees the slot
   (missing doc counts as resolved).

## Firestore rules

New `match /taskRules/{ruleId}` block in `firestore.rules`:

- **read:** any family member (`isFamilyMember(familyId)`).
- **create:** a family member whose role is `parent`/`guardian`, and the
  request's `familyId` matches the path (mirrors the `me().role in ['parent',
  'guardian']` pattern already used for user updates). This also stops a child
  forging `createdBy` — the rule doc must carry the writer's own uid.
- **update:** `false` in the MVP — nothing edits a rule in place yet.
- **delete:** parents only.

The engine writes spawned tasks via the admin SDK, so no client path can forge
a spawn, and no rules change is needed on `families/{familyId}/tasks`.

## Error handling

- **Per-rule try/catch in the engine:** one malformed or unreadable rule logs
  and is skipped; the tick continues for the rest (fail loudly per rule,
  resilient as a batch). Firestore's transaction retry handles concurrent
  ticks.
- **Client-side validation** at rule creation reuses `CreateTaskUseCase` rules
  (title length, points 1–1000, due date not past), so the engine never sees a
  garbage template. The engine still guards defensively: a rule missing
  `template.title` or `template.points` is skipped and logged.

## Deployment ordering

1. **Rules** (`firebase deploy --only firestore:rules`): adding the `taskRules`
   collection is a **widening** change, so per the standing rule it ships
   ahead of the client build (it can also ride with it; it must not come after
   the client tries to write a rule).
2. **Functions** (`firebase deploy --only functions`): the `onSchedule`
   function plus the `rrule` npm dependency. Safe anytime before the first rule
   exists; nothing runs until a rule is created.
3. **Client build** → TestFlight / Play.

## Testing

- **Engine (Node, `firebase-functions-test` with a mocked Firestore):**
  - spawns when due and the gate is open;
  - holds when the slot is occupied — one test per occupying status, and one
    for `needsRevision` specifically;
  - spawns when the previous task doc is missing;
  - advances `nextDueAt` with the real `rrule` lib (assert the exact next
    Saturday / month-day);
  - idempotent: a second tick after the first committed changes nothing;
  - a per-rule error does not abort sibling rules;
  - catch-up: a late completion spawns "due today", then settles to the RRULE.
- **Client (Dart):**
  - unit tests for the preset → RRULE helper (including month-end for Monthly);
  - the batch-write shape on submit when a repeat is chosen;
  - widget test: parent sees the Repeat row, child does not;
  - task-details: "Stop repeating" deletes the rule; hidden when the rule is
    gone.
- **Rules (`test/rules/` emulator suite):**
  - parent can create and delete a taskRule; child cannot;
  - all family members can read rules.

## Out of scope (deliberately deferred)

- **Rotation** assignment (round-robin fairness) — design doc marks it opt-in.
- **Rule management screen / editing a series** — "Stop repeating" from the
  task is the whole MVP surface. Editing a rule (change points, day, pause)
  is future work.
- **Pillar 2 — auto-expiry** (soft-archive, expire unclaimed, prune): its own
  spec; note the `expired` TaskStatus would be a narrowing client/rules
  change.
- **Custom RRULE strings** in the UI; in-app-event chains; external feeds;
  home-automation webhook adapter (design-doc Layers 2 and 3).
- **`recurringPattern` / `lastCompletedAt` wiring** — superseded by the rule
  engine.

## Open questions (for the implementation plan, not the MVP)

- Exact tick offset (avoid the :00/:15 crowd on Cloud Scheduler) and whether a
  missed occurrence should skip forward instead of clamping to today.
- Whether the notification copy should distinguish an auto-spawned chore from
  a hand-added one (e.g. "Clean the bathroom is up — every Saturday 🧹") via a
  `suppressNotification`-style flag on the task, once the MVP proves the
  engine.
