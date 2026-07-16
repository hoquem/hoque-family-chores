# Before & After Photos — Design

Date: 2026-07-16
Issue: [#130](https://github.com/hoquem/hoque-family-chores/issues/130)
Status: approved, not yet planned

## Why this is bigger than the issue says

Issue #130 claims it "builds on #109 (photo proof + AI rating), which shipped
the single-photo flow". **That is wrong.** #109/#110 shipped entities and data
plumbing and nothing else:

| Piece | State in `main` today |
|---|---|
| Camera / `image_picker` dependency | **absent** |
| The Gemini Vision call that would produce a rating | **absent** |
| `CompleteTaskUseCase` | flips status only; never touches a photo |
| Any UI that reads or writes a photo | **none** |

So no task in this app has ever had a photo. This work therefore *builds the
photo feature*, and makes it before/after while doing so.

### There are two competing photo models, both dead

This is the trap, and it must be settled before planning:

| | `Task` (#109/#110 fields) | `TaskCompletion` |
|---|---|---|
| After-photo field | `photoUrl` | `photoUrl` |
| Rating type | `AIRating` (`task.dart:8`) | `AiRating` (`task_completion.dart:63`) |
| Approval data | `approvedBy` / `rejectedBy` / `rejectionReason` / `submittedAt` / `submittedBy` | `ParentApproval` |
| Persisted to Firestore | **yes** — `firebase_task_repository.dart:398,439` | no — never instantiated in the live flow |
| Repository wired into DI | via `TaskRepository` (live) | yes, but nothing calls it |

Two entities model the same feature; the rating classes differ **by one letter**
(`AIRating` vs `AiRating`), which is a trap for anyone reading fast. Neither is
reachable from the UI, but `Task.photoUrl` round-trips through Firestore today,
making it the more real of the two.

**Decision: build on `Task`. Leave `TaskCompletion` untouched and dead.**
`Task` already persists `photoUrl` and already carries the approval fields, so
reusing it means no new repository wiring, no second write path, and no
migration. `TaskCompletion` is not deleted here — that is a separate cleanup
(see Out of scope), and deleting it is not needed to ship this.

This is also the cautionary tale for the work below: a modelled-but-unwired
layer looks finished and rots silently, because no UI or test ever touches it.
It happened twice in the same feature. Everything in this design is wired to a
screen or it is not built.

## Scope

Before + after photos, no AI. (Option B of three considered; A was after-only,
C added Gemini comparing the pair.) A was rejected because "before" must be
captured at task *start*, so A would force reworking the capture path
immediately. C bundles a real product decision — sending photos of children to
Google — into what should be a UI change; it is independently useful once
photos exist and belongs in its own conversation.

## Decisions

1. **One flag, both photos, default off.** `Task.requiresPhotoProof`. Off is
   exactly today's behaviour, so nothing regresses for existing tasks. A task
   either has photo proof or it does not; there is no "after only" third state.
   A lone after-photo is the weakest form of this feature — a tidy room looks
   the same whether it took 20 minutes or was already tidy.
2. **The parent sets the flag at task creation.** Fits the two-role model
   (parents set up, kids execute) and means the camera prompt appears only
   where before/after is meaningful. "Practise piano" has no before.
3. **A new `TaskStatus.inProgress`, reached by a Start action.** The before
   only exists before work begins, and a parent-assigned task is never claimed,
   so claim-time capture would cover only half the tasks. Start gives both
   paths the same shape: claim/assign → **Start (before)** → Complete (after) →
   approve. It also closes a gap DESIGN.md already documents — its status table
   lists `Assigned / in-progress → ▶ play_circle → "In progress"`, a state the
   enum never had.
4. **Both photos live on `Task`.** `Task.photoUrl` (existing, already persisted)
   is the after; `Task.beforePhotoUrl` (new) is the before. `TaskCompletion` is
   not used. This reuses the one photo field that already round-trips through
   Firestore, and it models rework correctly: on `needsRevision` the kid shoots
   a new after and `photoUrl` is overwritten — which is right, the latest
   attempt is what a parent judges — while `beforePhotoUrl` persists, because
   the room was only messy once.
5. **Camera only, never the gallery.** Gallery turns photo proof into "find any
   tidy room on this phone", and it opens a child's whole camera roll inside a
   chore app. `ImageSource.camera` only.
6. **No AI.** Both rating types (`AIRating` on `Task`, `AiRating` on
   `TaskCompletion`) stay unused: not wired, not deleted. See
   [#133](https://github.com/hoquem/hoque-family-chores/issues/133).

## Model

Only one new field and one new enum value:

```
Task
    photoUrl           : String?     // EXISTING — the after. Already persisted.
  + requiresPhotoProof : bool = false
  + beforePhotoUrl     : String?     // set at Start; cleared on "Can't do it"
TaskStatus
  + inProgress                       // between assigned and pendingApproval
```

`Task`'s other #109/#110 fields (`submittedAt`, `submittedBy`, `approvedBy`,
`approvedAt`, `rejectedBy`, `rejectedAt`, `rejectionReason`, `aiRating`) are
left exactly as they are: not read, not written, not deleted. Wiring them is
not needed to ship this, and deleting them is a separate cleanup. Do not let
them expand the scope.

## Flow

Only tasks with the flag are affected. Every other task keeps today's path.

| Step | Behaviour |
|---|---|
| Start | camera → compress → upload → `beforePhotoUrl` set, status `inProgress`. No photo, no start. |
| Complete | camera → compress → upload → `photoUrl` set. Status `pendingApproval`. |
| Can't do it | status back to `available`; `beforePhotoUrl` cleared **and the blob deleted**, or the next kid inherits a stranger's before. |
| Approve / reject | unchanged, except the parent now sees the pair. |

Making the before a precondition of Start is what removes the dead end: a kid
can never be mid-chore and unable to finish, because they could not have
started without it.

Three things the current code will fight, all easy to miss:

- **`CompleteTaskUseCase` guards on status.** It rejects anything that is not
  `assigned` or `needsRevision`, so `inProgress` must be added or every
  photo-proof task becomes uncompletable. This is the single most likely way to
  ship this broken.
- **"Can't do it" only renders in the `assigned` branch** of `task_list_tile`.
  It must also be reachable from `inProgress`, or a kid who starts a task is
  trapped in it.
- **Start is a new action with a new use case.** There is no existing
  `StartTaskUseCase`; the transition, its guard (only the assignee, only from
  `assigned`) and its repository call are all new.

## UI

- **Add Task** — a `Requires photo proof` switch, off by default.
- **Task tile / details** — `inProgress` renders through the existing
  `StatusPill` (carrot tint, `play_circle`, "In progress"); no new pill code.
- **Approval queue** — before/after as a **tap-to-toggle pair**: one image, tap
  to swap, each state labelled. Not a slider — fiddly for a parent clearing a
  queue in seconds, and a slider implies the two frames are aligned, which
  handheld shots never are.

  This is **new work, not a tweak**: no UI reads `photoUrl` anywhere today. The
  surface is `task_details_screen` (which has room for the pair) with the
  `pendingApproval` branch of `task_list_tile` linking to it. The tile's
  Approve/Reject buttons stay where they are — a parent should not approve a
  photo they have not opened.

## Testing

- Widget tests at **320pt**: the before/after pair is a lot of image in a
  narrow column. Non-negotiable — the suite only recently started rendering at
  phone width.
- `image_picker` mocked at its boundary; upload mocked at the repository.
- **The existing BDD task-management flows must pass untouched.** The flag is
  off by default, so any change there means this leaked into the default path.
- Round-trip test: flag on → start → complete → both URLs present on the
  approval surface.

## Out of scope

Gemini rating (#133), photo retention/cleanup policy, gallery import, editing a
before after the fact, and backfilling existing tasks (none have photos).

Also explicitly out: **deleting the dead `TaskCompletion` layer, and
reconciling `AIRating` with `AiRating`.** Both are real debt and neither blocks
this. They want their own issue, so that this feature is not held hostage to a
cleanup.

## Known risks

- **`TaskStatus` grows a sixth arm.** It is referenced across 16 files, with 8
  exhaustive switches in 6 of them: `home_stats.dart:49`,
  `task_list_screen.dart:43`, `task_details_screen.dart:29`,
  `task_list_tile.dart:326` and `:435`, and `status_pill.dart:32`, `:41`, `:49`.
  Dart's exhaustiveness checking makes the compiler find them, which is the
  saving grace — but this is the part most likely to sprawl.
- **Storage cost doubles per proof-task completion.** `flutter_image_compress`
  is already a dependency and must be used on both photos. A retention policy
  is deliberately deferred, which means this grows unbounded until #133-era
  work addresses it.
- **`image_picker` is a new dependency** on a project whose Android build is
  currently broken for an unrelated dependency reason (#129). Verify it does
  not compound that.
