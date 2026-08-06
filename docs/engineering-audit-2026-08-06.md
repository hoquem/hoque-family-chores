# Engineering Audit — Hoque Family Chores

**Date:** 2026-08-06
**Auditor:** Claude Code, against `ENGINEERING.md` and the build-clean audit rubric
**Scope:** `lib/`, `test/`, `test/rules/`, `functions/`, `firestore.rules`
**Baseline:** `docs/engineering-audit-2026-08-01.md` (5 days prior) — this is a **re-score with trend**, and every prior `file:line` claim was re-checked rather than inherited.

---

## Scorecard

| # | Dimension | 08-01 | 08-06 | Trend |
|---|-----------|-------|-------|-------|
| 1 | Domain language | 4 | **4** | → label drift spread from 1 file to 3 |
| 2 | Boundaries | 4 | **4** | → domain layer verified pure; the one known leak is unfixed |
| 3 | Aggregates / invariants | 4 | **4** | → strong, but the guarding suite is not in the default run |
| 4 | Test coverage | 3 | **3** | ↑ 45.6% → 46.8%; mutation quality proven high |
| 5 | Testability | 4 | **4** | → per-file tests run in seconds |
| 6 | Module depth | 3 | **3** | ↓ the four largest files all grew |
| 7 | Change amplification | 3 | **1** | ⚠ re-score correction — measured, not estimated |
| 8 | Error design | 3 | **3** | → 5 silent catch sites, 2 documented on purpose |

**Average: 3.3/5** (was 3.5 — the drop is one re-scored dimension, not a regression; see §7)

**Headline:** The DDD side is genuinely strong and now *verified*, not asserted — `lib/domain/` has zero framework imports, and both invariants sampled by mutation are properly pinned. The TDD side is better than the coverage number suggests but weaker than it looks on process: **18% of feature and fix commits ship no test**, and **23 of 46 use cases have zero covered lines** — including claim, settle, and reject, the client half of the star economy.

Two facts hold at once and both belong in the summary: the suite grew from **414 to 438 tests** in five days, and a quarter of the code that landed alongside them was untested.

---

## 1. Domain language — 4/5

**Good.** The glossary in `ENGINEERING.md` is real and load-bearing. Code names trace to it: `ClaimTaskUseCase`, `SettleRedemptionUseCase`, `ApproveTaskUseCase`, `TaskStatus.pendingApproval`. Test names read as domain sentences, which is the strongest signal a glossary is actually in use:

- `test/domain/usecases/task/start_task_usecase_test.dart` — *"only the assignee may start their own task"*, *"an unclaimed task cannot be started — claim it first"*
- `test/domain/usecases/task/complete_task_usecase_test.dart` — *"a photo-proof task CANNOT be completed straight from assigned — the bypass"*

**Drift (repeat finding, now worse).** `DESIGN.md` calls the state "Waiting"; the code renders "Pending Approval". On 08-01 this was one site. It is now three:

- `lib/presentation/screens/member_detail_screen.dart:328`
- `lib/presentation/screens/task_details_screen.dart:43`
- `lib/presentation/widgets/task_list_tile.dart:619`

The `member_detail_screen.dart` site is new since the baseline — the drift was copied forward into new code. That is the failure mode the glossary exists to prevent.

**Watch, not a defect.** `Reward` (domain type, 18 files) vs `Treat` (user-facing label, 7 files). The glossary explicitly sanctions this split, so it is documented translation rather than inconsistency — but it is the kind of thing that decays.

---

## 2. Boundaries — 4/5

**Good — and now positively verified rather than assumed:**

```
grep -rn "^import 'package:\(cloud_firestore\|firebase_\|flutter/\)" lib/domain/   → (no matches)
grep -rn "import.*\(/data/\|/presentation/\)" lib/domain/                          → (no matches)
```

`lib/domain/` is pure. Every use case depends on an interface in `lib/domain/repositories/`, and every interface has a Firebase and a Mock implementation. That is a 5-level structure.

**Why it is 4 and not 5.** The rubric reserves 5 for boundaries *enforced by test or lint*. Nothing enforces this — the purity above is a property of the current tree, not a guarantee. And the one known violation is unfixed five days on:

- `lib/data/repositories/firebase_push_notification_repository.dart:13-14` still imports `../../presentation/utils/navigator_key.dart` and `../../presentation/providers/riverpod/bottom_nav_notifier.dart`.

A data-layer repository reaching into a presentation provider is the exact arrow the architecture forbids. It survived a full audit cycle, which is the argument for a lint rule over a finding.

---

## 3. Aggregates / invariants — 4/5

**Good.** The star economy is the best-defended part of the system: award/claim/settle live in Cloud Functions, `users.points` is locked from clients, and family isolation is enforced in `firestore.rules`. `approve_task_usecase.dart:29-33` documents in prose that the Function is the authoritative guard — and unusually, the prose is honest about *why* the client re-reads the task (photo handling only).

**Gap 1 — the strongest invariant is guarded by a suite that does not run by default.** `test/rules/functions_economy.test.mjs` (no-self-approval, star awards) and `test/rules/family_isolation.test.mjs` require `firebase emulators:exec` and are invoked by their own `npm test` scripts (`test/rules/package.json`). `flutter test` — the command everything else is verified with — does not touch them. The invariant is enforced; the *guard on the enforcement* is opt-in.

**Gap 2 — repeat finding, unfixed.** `approve_task_usecase.dart:69-70` still carries two invariant side-effects as TODOs: streak update, and push notification to the doer.

**Deliberate exception, correctly documented.** `approve_task_usecase.dart:52-62` swallows a storage failure after approval. The 10-line comment explains the trade (a leaked blob is cheaper than a failed approval) and `test/domain/usecases/task/approve_task_photo_cleanup_test.dart` pins it — *"a failed promotion does NOT fail the approval"*, *"a failed promotion still approves and awards"*. This is what a justified exception to "fail loudly" should look like: reasoned in prose, pinned by a named test.

---

## 4. Test coverage — 3/5

**Measured, not inherited.** `flutter test --coverage`, exit code 0:

```
00:54 +438: All tests passed!
lib/ lines: 3303/7063 = 46.8%   (excluding *.g.dart)
```

Up from **414 tests / 45.6%** at the baseline: +24 tests in five days. 40–60% is the rubric's band 3.

**The quality is better than the quantity.** The rubric's discriminator is whether guards are *pinned* or merely *executed*. Two mutations, both killed exactly one correctly-named test and nothing else:

| Mutation | Result |
|---|---|
| `task_ordering.dart:29` — dropped `.toLowerCase()` from the title tie-break | ✗ `task_ordering_test.dart:58` — *"within a group, titles sort alphabetically and case-insensitively"* died. Nothing else. |
| `start_task_usecase.dart:51` — `if (task.assignedToId != userId)` → `if (false)` | ✗ `start_task_usecase_test.dart` — *"only the assignee may start their own task"* died. Nothing else. |

Both reverted; `git status --porcelain` clean. 2/2 is a small sample, but a precise one — these are not coverage-inflating tests.

**The real gap is *which* code is covered.** Counted from `lcov.info`, not from filename convention: **23 of 46 use cases have zero covered lines** — exactly half the domain's entry points are never executed by the suite. The economy is in that half:

| Use case | Coverage |
|---|---|
| `reward/settle_redemption_usecase.dart` | **0/12** |
| `reward/claim_reward_usecase.dart` | **0** |
| `task/reject_task_usecase.dart` | **0/8** |
| `task/uncomplete_task_usecase.dart` | **0/8** |
| `task/assign_task_usecase.dart` | **0** |
| `task/edit_task_details_usecase.dart` | **0** |
| `task/claim_task_usecase.dart` | 8/15 |

Claim, settle, reject and assign are the star economy's client half. All of `usecases/family/` write-side (create, delete, add member, remove member, update) is also at zero. Unchanged from the baseline: `task_details_screen.dart` **0/437**, `firebase_task_completion_repository.dart` **0/128**, `firebase_notification_repository.dart` **0/125**.

**Process evidence — the weakest finding in this audit.** Coverage is a lines claim; TDD is a process claim, and git answers it directly. Deduplicated by subject (the branch was rebased and several commits re-landed — `506117b`/`7de14d7` are the same work, and the raw log double-counts them), since 2026-06-01:

- 102 distinct commits touch non-generated `lib/`; **24 (24%) ship zero test files**
- restricting to `feat:`/`fix:` and excluding `copy:`/`ux:`/`chore:` — where no test is often legitimate — **16 of 91 (18%)** ship zero tests

Some of those 16 are defensible (`fix(auth): correct Android API key`, `fix(startup): guard Firebase.initializeApp` — config and platform init). Others are not:

```
feat(rewards): the Rewards tab                                        lib:9  test:0
feat(tasks): photo-proof completion flow on the task-details screen   lib:1  test:0
feat(tasks): add Unclaim action to give a claimed task back to pool   lib:1  test:0
feat(tasks): let a parent unassign a task from the edit screen        lib:1  test:0
feat(notifications): actor avatar in notification tiles               lib:1  test:0
```

These are domain behaviours — unclaim, unassign, photo-proof completion — shipped with no failing test having demanded them. That is framework rule 1 violated, and it correlates directly with the zero-coverage use-case list above.

And `d1e91c2 test: MemberDetailScreen widget tests` is a tests-only commit landing *after* the feature. Tests written after the code they cover prove only that the code still does whatever it now does — that is characterization, not TDD, and it was not labelled as such.

---

## 5. Testability — 4/5

**Good.** Both mutation runs were single-file, sub-5-second executions with no emulator, no fixtures, no network:

```
flutter test test/domain/services/task_ordering_test.dart          → 00:01
flutter test test/domain/usecases/task/                            → 00:05, 22 tests
```

Repository interface + Mock pairs (`test/mocks/`) and Riverpod DI (`lib/di/riverpod_container.dart`) mean a new use-case test needs a mock repo and nothing else. Value objects (`UserId`, `FamilyId`, `TaskId`) construct trivially.

**Gap.** The suite does not split cleanly into fast and integration — the rubric's level 5. `flutter test` is 54 seconds and pulls widget tests into the same run as pure domain tests, while the emulator suites (§3) sit outside entirely. There is no `--fast` path and no CI-visible integration tier.

(`lib/test_data/` shows up in a directory listing but tracks zero files — an untracked local leftover, not something that ships.)

---

## 6. Module depth — 3/5

**Deep, in the domain.** `tasksForDisplay(List<Task>) → List<Task>` (`lib/domain/services/task_ordering.dart:24`) is the model: a one-argument signature hiding a four-tier status ranking, case-insensitive title sort, and a recency tiebreak, all documented in a 13-line docstring that the mutation test above proves is true.

**Shallow, in presentation — and getting worse.** All four of the baseline's named large files grew in five days:

| File | 08-01 | 08-06 |
|---|---|---|
| `lib/presentation/screens/task_details_screen.dart` | 959 | **976** |
| `lib/presentation/screens/add_task_screen.dart` | 611 | **778** |
| `lib/presentation/widgets/task_list_tile.dart` | ~600 | **848** |
| `lib/data/repositories/firebase_push_notification_repository.dart` | 603 | 621 |

Plus `lib/presentation/providers/riverpod/auth_notifier.dart` at 702 lines. `add_task_screen.dart` gained 167 lines — 27% — in five days, against a finding that said extract a form controller.

**The structural measurement.** Source lines by layer, and file-touches since 2026-06-01:

| Layer | Lines | Touches |
|---|---|---|
| `presentation/screens` | 5,506 | 228 (all of `presentation/`) |
| `data` | 3,622 | 48 |
| `presentation/providers` | 2,640 | — |
| `domain/usecases` | 2,592 | 87 (all of `domain/`) |
| `presentation/widgets` | 2,019 | — |
| `domain/entities` | 1,120 | — |
| `domain/repositories` | 477 | — |
| `domain/value_objects` | 302 | — |
| **`domain/services`** | **193** | — |

`domain/services` — the pure-decision layer, no I/O, no framework — is **193 lines**, two files. It is also the only place in the repo where mutation testing proved the guards are genuinely pinned (§4). Against 5,506 lines of screens.

Note this is *not* a coverage gradient: domain is 55.6% covered and presentation 53.1%, near-identical. The asymmetry is in **thickness and churn**, not in test discipline per layer. Decisions are being made in code that is expensive to test, not left untested in code that is cheap to test.

**Related observation.** 20 of 46 use cases are ≤45 lines — largely repository pass-throughs. That is the rubric's band-1 shape ("pass-through methods") and part of the amplification tax in §7, since each one still costs a registration in `usecases.dart` and `riverpod_container.dart`. Recorded as an observation only; unpicking the use-case layer would be a rewrite, which this audit does not propose.

**Fixed since baseline (verified gone):** the hardcoded `Color(0xFF6750A4)` M3 purple, and `NetworkImage` in `notifications_screen.dart`.

---

## 7. Change amplification — 1/5 (re-score, not regression)

The baseline scored 3/5 on an estimate of "6–7 files". The rubric says *measure* the last three conceptual changes and do not estimate. Measured — non-generated `lib/` files per commit, excluding rebase re-lands:

| Commit | `lib/` files |
|---|---|
| `7de14d7` feat: notifications badge, member detail, motion integration | **11** |
| `e17365c` feat(motion): everyday snappy tier | **10** |
| `76a7b24` feat(photos): auto-expire at 90 days + in-app delete | 5 |

Median 10 lands in the rubric's 10+ band (0/5); the mean of 8.7 lands in 5–9 (1/5). Widening the sample to five to check for cherry-picking gives `df5f02f` = 4 and `cddeef0` = 5, so the fuller picture is 11 / 10 / 5 / 5 / 4 — median 5.

**Scoring 1/5** as the honest read: the rubric's prescribed three-change sample says 0–1, the wider sample says 1–2. Two of the three prescribed samples are broad motion/notification features where some breadth is inherent, which is why this is not 0.

This is a **correction to the baseline's methodology, not a five-day regression** — nothing about the codebase got worse on this dimension; the previous score was estimated rather than measured.

The structural cause is unchanged and visible in the hot-file list (`git log --since=2026-05-01`): `riverpod_container.dart` at 13 edits and `usecases.dart` at 9 are pure registration churn — every new capability edits both. A task feature walks `domain/repository → domain/usecase → data/firebase_repo + data/mock_repo → provider → screen → widget`, plus two registration files.

---

## 8. Error design — 3/5

**Good.** Typed failures in `lib/core/error/failures.dart`, `Either<Failure, T>` returns throughout the use cases, `DataException → ServerFailure` mapping at `approve_task_usecase.dart:66`.

**Five silent-catch sites** in `lib/` (excluding generated):

| Site | Verdict |
|---|---|
| `approve_task_usecase.dart:60` | ✅ documented and test-pinned (§3) |
| `help_button.dart:38` | ✅ documented — `/* telemetry is never fatal */` |
| `main_screen.dart:102` | ❌ `catch (_) {}` — bare, repeat finding |
| `main_screen.dart:179` | ❌ `catch (_) {}` — bare, repeat finding |
| `family_screen.dart:154` | ❌ undocumented |

The two documented ones are exactly right — a swallowed error with a stated reason and a test is a design decision. The three bare ones are the defect, and `main_screen.dart` has now carried its two for a full audit cycle.

---

## Top 3 fixes — ranked by (5 − worst score) × change frequency

### 1. `lib/presentation/screens/task_details_screen.dart` — score 65

- **Worst dimension:** coverage 0/5 (**0/437 lines**), depth 3/5 (976 lines)
- **Change frequency:** 13 edits since 2026-05-01
- **Why highest-leverage:** it is the screen where approve, reject, complete, and photo-proof all converge — every economy action the user can take — and not one line is executed by the suite. It is also the single largest file in the repo and still growing.
- **Effort:** M
- **First step:** characterization widget tests for the six `TaskStatus` action rows. Pin current behaviour including any bug, marked as a bug. No refactor until they are green.

### 2. `lib/presentation/widgets/task_list_tile.dart` — score 34

- **Worst dimension:** coverage 3/5 (214/358), depth 3/5 (848 lines), language 4/5 (the "Pending Approval" drift site)
- **Change frequency:** 17 edits — the hottest non-config file in the repo
- **Why:** hottest × largest gap. Every task feature touches it, and it grew ~40% in five days.
- **Effort:** S–M
- **First step:** extract the status→label mapping (`:619`) into a single glossary-owned function shared with `task_details_screen.dart:43` and `member_detail_screen.dart:328`. That is one boy-scout change that fixes the language drift in all three sites and creates the first testable seam in the file.

### 3. The client half of the star economy — score ~48

- **Files:** `settle_redemption_usecase.dart` (0/12), `claim_reward_usecase.dart` (0), `reject_task_usecase.dart` (0/8), `uncomplete_task_usecase.dart` (0/8), `assign_task_usecase.dart` (0), `claim_task_usecase.dart` (8/15)
- **Change frequency:** `rewards_screen.dart` 12, `firebase_task_repository.dart` 9
- **Why:** §3 rates invariants 4/5 on the strength of server-side enforcement — but the client paths that call those Functions are in the 23-of-46 zero-coverage set, and the emulator suite that tests the server half is not in the default run. The two mutations in §4 show that when a test exists here it is a good one. There just aren't enough of them.
- **Effort:** S — these are the cheapest tests in the repo to write (mock repo, no I/O)
- **First step:** `settle_redemption_usecase_test.dart`, mirroring the shape of `start_task_usecase_test.dart`.

---

## Incremental roadmap

Strangler and boy-scout only. No rewrites.

**Week 1 — stop the bleeding (process, not code)**
- Adopt the rule that a `feat:`/`fix:` commit touching `lib/` either ships a test or states in its body why not. 18% currently ship none, and some of those are legitimate — the point is to make the exceptions *declared* rather than silent.
- Add `test/rules/` to whatever runs before a release. The economy's strongest guard should not be opt-in.

**Week 2 — the three-site language fix (Top-3 #2, first step)**
- One shared status-label function; fixes the "Pending Approval" / "Waiting" drift everywhere at once and opens `task_list_tile.dart` for extraction.

**Week 3 — characterization before the big screens**
- `task_details_screen.dart` action-row tests (Top-3 #1). Pin, do not fix.
- `settle_redemption_usecase_test.dart` + `reject_task_usecase_test.dart` (Top-3 #3).

**Week 4 — the leaks that survived an audit cycle**
- Remove the `data → presentation` import from `firebase_push_notification_repository.dart:13-14`, then add a lint or a test asserting `lib/data/` never imports `lib/presentation/` — the finding recurred because nothing prevents it.
- Replace the three bare `catch (_)` sites with logged failures, or document them the way `approve_task_usecase.dart:52-62` does.
- Land the two `ApproveTaskUseCase` TODOs (streak, push) or convert them to tracked tickets — a TODO on an invariant side-effect should not be permanent.

**Ongoing**
- `add_task_screen.dart` and `task_details_screen.dart` extraction, only under green characterization tests.

---

## Follow-up started same day — branch `feat/pure-decision-layer`

Everything above describes the tree at `95ae713`. Five commits have since acted
on Top-3 #2 and the §6 finding:

| | Before | After |
|---|---|---|
| `domain/services` | 193 lines, 2 files | **281 lines, 3 files, 98.8% covered** |
| `task_list_tile.dart` | 848 lines | **766** |
| `task_details_screen.dart` | 976 lines, **0/412 covered** | **897 lines, 152/412 (36.9%)** |
| `lib/` coverage | 46.8% | **49.0%** |
| Tests | 438 | **469** |

- `taskStatusLabel` (`presentation/utils`) — the three-way duplicated status
  wording, now one pinned function. Deliberately *not* in `domain/`: it is copy,
  and `DESIGN.md` owns it.
- `pendingApproval` now reads **"Waiting"**, matching `DESIGN.md:204,261,442`.
  Separate commit, two test assertions updated with it.
- `taskActionsFor` (`domain/services/task_actions.dart`) — the workflow rules
  that were written twice. 15 tests, no framework imports, mutation-checked.
- Both screens migrated to it; −144/+81 and −82 lines respectively.
- **§1's root cause fixed.** The glossary entry read `| Chore / Task |` —
  one concept with two blessed names, which is what made the drift legal
  rather than a mistake. Split to mirror the existing Treat/Reward entry:
  **Chore** is the user-facing name, **Task** is the code identifier and is
  never user-facing. All user-facing copy renamed to match (52 strings in
  `lib/`, 19 test assertions, `DESIGN.md`), including the nav tab, which now
  reads **Chores** — the tab beside it had already made this move from
  Rewards to Treats. Code identifiers untouched: mass-renaming `Task*` across
  a tested codebase churns the most valuable asset for zero behaviour change.

**The extraction found a live inconsistency.** The two copies had drifted: the
detail screen offered "Give it back" on a `needsRevision` chore and the tile did
not, so a child sent back a chore they could not redo had no way out from the
Tasks list. Resolved in the tile's favour losing nothing — it gained the action.
That divergence had been invisible precisely because the rule lived in two
places; it surfaced the moment there was one.

**Top-3 #1 partly closed as a side effect.** The detail-screen migration was
initially verified only by reading, because the screen had no tests — so nine
characterization tests were added for its action section, taking it from 0 to
152 covered lines and `lib/` from 46.8% to 49.0%. They pin button *order*
explicitly, which was the one thing the extraction could have silently reversed.

Those tests immediately earned their keep twice: they exposed a 27px header
overflow that turned out to be flutter_test's fixed-width fallback font rather
than a real defect (verified before touching production code), and they cover
the states a rule-by-rule reading is weakest on.

**Glyph collision, found and fixed.** Adding hand-back to `needsRevision` put
two `Icons.undo` on one tile: `StatusPill` uses it as the `needsRevision` status
glyph, which `DESIGN.md:205` specifies. The pill kept it and the hand-back
action moved to `Icons.assignment_return` in both screens. Eight test assertions
that used `byIcon(undo)` to mean "the hand-back action" moved with it — the one
in the `needsRevision` state now matches by tooltip, which cannot collide.

## Not audited

- Generated code: `*.g.dart`, `lib/di/riverpod_container.g.dart`, Flutter/plugin generated sources.
- `functions/node_modules/`, `test/rules/node_modules/`, third-party packages.
- Native platform code: `ios/`, `android/`, `macos/`, `windows/`, `linux/`, `web/` — including the widget extensions, which are covered only by manual TestFlight verification.
- `functions/` TypeScript source was read only where §3 required it; the Cloud Functions are **not** independently scored here. Their tests exist (`test/rules/functions_economy.test.mjs`) but were not executed in this audit — no emulator was started.
- `integration_test/` — present, not run.
- The 46.8% coverage figure is from `flutter test --coverage` only. It excludes anything the emulator suites and integration tests would cover, so it understates true behavioural coverage by an unmeasured amount.
