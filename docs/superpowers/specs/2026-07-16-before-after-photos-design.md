# Before & After Photos — Design

Date: 2026-07-16
Issue: [#130](https://github.com/hoquem/hoque-family-chores/issues/130)
Status: approved, not yet planned

## Why this is bigger than the issue says

Issue #130 claims it "builds on #109 (photo proof + AI rating), which shipped
the single-photo flow". **That is wrong.** #109 shipped entities and a data
layer and nothing else:

| Piece | State in `main` today |
|---|---|
| `TaskCompletion` entity (`photoUrl`, `AiRating`, `ParentApproval`) | exists |
| `TaskCompletionRepository` + Firebase impl, registered in DI | exists |
| Any UI or use-case that calls it | **none — orphaned** |
| Camera / `image_picker` dependency | **absent** |
| The Gemini Vision call that would produce an `AiRating` | **absent** |
| `CompleteTaskUseCase` | flips status only; never touches a photo |

So no completion in this app has ever had a photo. This work therefore *builds
the photo feature*, and makes it before/after while doing so. The dead layer is
also the cautionary tale: a modelled-but-unwired layer looks finished and rots
silently, because no UI or test ever touches it. Everything below is wired to a
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
4. **The before lives on `Task`, not `TaskCompletion`.** It is captured at
   Start; the completion record does not exist until Complete. Putting it on
   the completion would force a half-built record with a nullable `photoUrl`.
   It also models rework correctly: on `needsRevision` the kid shoots a new
   after, but the before is unchanged — the room was only messy once. One
   before, many completions.
5. **Camera only, never the gallery.** Gallery turns photo proof into "find any
   tidy room on this phone", and it opens a child's whole camera roll inside a
   chore app. `ImageSource.camera` only.
6. **No AI.** `AiRating` stays an unused type: not wired, not deleted. See
   [#133](https://github.com/hoquem/hoque-family-chores/issues/133).

## Model

```
Task
  + requiresPhotoProof : bool = false
  + beforePhotoUrl     : String?     // set at Start; cleared on "Can't do it"
TaskStatus
  + inProgress                       // between assigned and pendingApproval
TaskCompletion
    photoUrl : String                // the after; stays required, unchanged
```

## Flow

Only tasks with the flag are affected. Every other task keeps today's path.

| Step | Behaviour |
|---|---|
| Start | camera → compress → upload → `beforePhotoUrl` set, status `inProgress`. No photo, no start. |
| Complete | camera → upload → `TaskCompletion` created with the after. Status `pendingApproval`. |
| Can't do it | status back to `available`; `beforePhotoUrl` cleared **and the blob deleted**, or the next kid inherits a stranger's before. |
| Approve / reject | unchanged, except the parent now sees the pair. |

Making the before a precondition of Start is what removes the dead end: a kid
can never be mid-chore and unable to finish, because they could not have
started without it.

## UI

- **Add Task** — a `Requires photo proof` switch, off by default.
- **Task tile / details** — `inProgress` renders through the existing
  `StatusPill` (carrot tint, `play_circle`, "In progress"); no new pill code.
- **Approval queue** — before/after as a **tap-to-toggle pair**: one image, tap
  to swap, each state labelled. Not a slider — fiddly for a parent clearing a
  queue in seconds, and a slider implies the two frames are aligned, which
  handheld shots never are.

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
before after the fact, and backfilling existing completions (there are none).

## Known risks

- **`TaskStatus` grows a sixth arm.** Its switches appear in ~5 places. It is
  contained now that the status pill is a single component, but this is the
  part most likely to sprawl.
- **Storage cost doubles per proof-task completion.** `flutter_image_compress`
  is already a dependency and must be used on both photos. A retention policy
  is deliberately deferred, which means this grows unbounded until #133-era
  work addresses it.
- **`image_picker` is a new dependency** on a project whose Android build is
  currently broken for an unrelated dependency reason (#129). Verify it does
  not compound that.
