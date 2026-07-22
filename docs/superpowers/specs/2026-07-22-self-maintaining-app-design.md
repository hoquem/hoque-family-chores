# Self-Maintaining App — Design Sketch

> **Status:** Backlog / future work. This is a *design sketch and conception
> record*, not an approved implementation plan. When we're ready to build, each
> pillar becomes its own spec → plan → implementation cycle.
>
> **Conceived:** 2026-07-22 · **Inventor:** Mahmudul Hoque · **App:** Chores Star
> (`com.hoque.familychores` / `com.hoque.hoqueFamilyChores`)

## Vision

Today every task is created and every list is curated by a human family member.
The app should instead **maintain itself as much as possible** — chores appear
when they're due, and stale items retire on their own — so families spend their
attention on doing chores, not administering an app.

Two pillars, both running on one piece of infrastructure (server-side scheduled
Cloud Functions over Firestore):

1. **Auto-generation** — create tasks from events (schedules, in-app events,
   external feeds, home-automation signals).
2. **Auto-expiry / lifecycle** — retire tasks, treats, and notifications that
   have outlived their usefulness, without corrupting history.

There is already a precedent for this mindset: the 90-day photo auto-delete GCS
lifecycle rule. These pillars extend "self-maintaining" from storage to the
whole data model.

---

## Pillar 1 — Auto-Generated Tasks

### Core idea: one rule engine, pluggable triggers

The insight that makes this feasible: **schedules, in-app events, external feeds,
and home-automation sensors are all the same machine with different inputs.** A
rule says "*when [trigger fires], create [task from template]*." Each input is
just a different **trigger adapter** plugged into one engine.

This is deliberately feasible-first. The engine is built once; the easy triggers
(schedules, in-app events) ship first and benefit 100% of families with no
hardware dependency. Home automation then becomes "just another adapter" for the
subset of families who have it — not a separate feature.

### Data model

```
families/{familyId}/taskRules/{ruleId}
  trigger:    { type: "schedule" | "inAppEvent" | "externalFeed" | "webhook",
                config: {…} }      # RRULE string · event name · feed query · webhook event id
  template:   { title, description, difficulty, points,
                requiresPhotoProof, tags }        # same shape as a Task
  assignment: "unassigned" | { userId } | "rotation"
  enabled:    true
  lastFiredAt, nextDueAt
```

### Trigger adapters (feasibility layering)

- **Layer 1 — Schedules** (every family, no hardware, proven demand): a Cloud
  Function on a ~15-minute Cloud Scheduler tick scans rules whose `nextDueAt` has
  passed, creates the task, and advances `nextDueAt` using the rule's **RRULE**
  (the iCal recurrence standard — gives "every Saturday", "every 3 days", "1st of
  the month" for free). Example: "clean the bathroom every Saturday."
- **Layer 2 — In-app events** (no hardware): the existing economy Cloud Functions
  already fire on task-complete / reward-redeem; they emit an internal event that
  matches `inAppEvent` rules and spawns follow-on chores (task-completion chains,
  a redeemed reward creating a setup chore).
- **Layer 2 — External feeds** (no hardware): the scheduled function also polls
  weather / calendar and matches `externalFeed` rules ("rain tomorrow → bring in
  the cushions", "guests Friday → tidy the lounge").
- **Layer 3 — Home automation** (opt-in, the exciting-but-hardware-gated one):
  one HTTPS Cloud Function is a per-family inbound webhook. Home Assistant /
  SmartThings / IFTTT / Alexa Routines POST `{ event: "dishwasher_done" }`, it
  matches a `webhook` rule, and the chore appears. Examples: dishwasher finishes
  its cycle → "unload the dishwasher"; mailbox sensor → "get the post"; bin-day
  automation → "take the bins out".

### Key decisions

1. **Assignment supports "rotation."** Beyond unassigned / fixed-child, a fair
   round-robin across the kids ("whose turn is it") is a genuinely differentiating
   family feature when combined with the reward economy. New rules default to
   *unassigned* ("up for grabs"); rotation is opt-in.
2. **Idempotency is mandatory.** Every auto-create carries a key
   (`ruleId + occurrence-window` for schedules, the event id for webhooks) so a
   double scheduler tick or a chatty sensor cannot spawn duplicate chores. This
   mirrors the atomicity care already in the economy code.
3. **Webhook security: token in a header, never the URL.** A per-family secret,
   stored hashed; the family pastes it into their home-automation tool. No
   secrets in query strings (consistent with the app's privacy stance).
4. **Notify on create (reuse FCM)** so a new auto-chore is visible, not a
   surprise.

---

## Pillar 2 — Auto-Expiry / Lifecycle

Keep the app tidy on its own. The same scheduled Cloud Function that generates
tasks also runs retention passes.

### Hard constraint: never corrupt history

Streaks and the weekly leaderboard key off `approvedAt` of **completed** tasks.
So completed tasks must **not** be silently deleted. The rule:

- **Soft-archive** anything history needs (completed/approved tasks): set an
  `archived` flag so it drops out of the active list but the record survives for
  stats. Optionally roll stats into a per-family summary before any eventual
  hard-delete, so deletion can never change a streak.
- **Hard-delete** only genuinely disposable records.

This is explicitly *not* a fallback that hides a problem — it is retention that
preserves the data the app actually depends on.

### Candidate retention rules (all windows configurable, sensible defaults)

| Item | Trigger | Action |
|------|---------|--------|
| **Unclaimed task** ("up for grabs") | past due date + grace, or N days old with no claim | expire → `expired` status, then hard-delete after a short tail (ties into the existing overdue handling) |
| **Completed / approved task** | approved + N days | **soft-archive** (drop from active list, keep for streak/stats) |
| **Rejected task** | rejected + N days, not resubmitted | hard-delete |
| **Treats / rewards** | time-limited treat past its window; or reward disabled | expire / hide |
| **Reward redemptions** | settled + N days | hard-delete (economy already settled) |
| **Notifications** | read + N days | hard-delete (already a notifications screen) |
| **Chore photos** | 90 days | already handled by the GCS lifecycle rule |

### Key decisions

1. **Configurable windows, safe defaults.** Per-family override later; ship with
   global defaults first.
2. **Idempotent + observable.** Retention passes are safe to re-run, and each
   emits an analytics event (reuse the append-only analytics log) so cleanup is
   auditable, never silent.
3. **Soft-archive before hard-delete** for anything stats or history touch.

---

## Shared infrastructure

Both pillars need the same foundation, which is why they belong together:

- A **scheduled Cloud Function** (Cloud Scheduler tick) as the heartbeat.
- An **HTTPS Cloud Function** for inbound webhooks (Pillar 1, Layer 3).
- **Idempotency keys** on every create and destructive action.
- **Firestore security rules** so only the server (Functions) writes auto-created
  and archival changes — clients never forge rule fires or bypass retention.
- Requires the **Blaze plan** (already enabled for the economy functions).

---

## Patent angle (informed framing, not legal advice)

The defensible claim candidate is **not** any single trigger and **not**
"connect a dishwasher." It is the **unified pipeline that normalizes
heterogeneous real-world and digital events into assignable, reward-bearing
chores distributed — with fairness/rotation — across a family economy, and that
self-maintains that economy's lifecycle.** Home automation is one adapter.

Claim candidates to explore with a patent attorney:
1. Unified pluggable trigger→family-chore-economy pipeline (schedule / in-app /
   feed / device event all normalized to one rule model).
2. Fairness/rotation assignment of *auto-generated* chores across family members
   coupled to a reward economy.
3. Mapping home-automation device events to reward-bearing, assignable chores.

**Prior-art caveats (be honest):** recurring-task apps (Todoist, Google Tasks),
IFTTT/Zapier-style event automation, and home automation all exist. Any novelty
must live in the *specific combination* — a multi-user family chore-and-reward
economy that is both auto-fed and self-maintaining. A real assessment needs a
patent attorney and a prior-art search. Meanwhile, this dated document is the
**conception record**; keep it under version control and note material additions
with dates.

---

## Suggested build order (when we pick this up)

1. **Scheduled-function heartbeat + idempotency** (shared foundation).
2. **Pillar 1, Layer 1 — recurring schedules** (highest value, no hardware).
3. **Pillar 2 — auto-expiry** (soft-archive completed, expire unclaimed, prune
   notifications/redemptions).
4. **Pillar 1, Layer 2 — in-app events + external feeds.**
5. **Pillar 1, Layer 3 — home-automation webhook adapter.**

## Open questions for later

- Retention windows: exact defaults per item type.
- Rotation fairness: strict round-robin vs. weighted by past load?
- External feeds: which first — weather or calendar? (auth/APIs differ)
- Rule config UI: parent-authored only, or app-*suggested* rules a parent
  approves?
- Do archived completed tasks eventually hard-delete after stats roll-up, or
  persist indefinitely?
