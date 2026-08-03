# Engineering Audit — Hoque Family Chores

**Date:** 2026-08-01  
**Auditor:** Claude Code, against the repo's AI-assisted development framework  
**Scope:** `lib/`, `test/`, `functions/`, `firestore.rules`; generated code and third-party packages excluded.

---

## Executive summary

| Dimension | Score | Trend |
|-----------|-------|-------|
| Domain language | 4/5 | Improved — glossary now lives in `ENGINEERING.md`; minor label drift remains. |
| Bounded contexts | 4/5 | Strong — Clean Architecture layers are respected. |
| Aggregates / invariants | 4/5 | Strong — star economy and family isolation enforced server-side. |
| Test coverage | 3/5 | 45.6% `lib/` line coverage; many Firebase repositories and screens untested. |
| Testability | 4/5 | Good DI and mock repos; a few notifiers need heavy setup. |
| Module depth | 3/5 | Several large state classes and repositories; some shallow config leaks. |
| Change amplification | 3/5 | New features usually touch 4+ layers; not extreme, but not plug-and-play. |
| Error design | 3/5 | Mostly explicit, but a few swallowed/empty catches remain. |

**Average:** 3.5/5

The repo is already well-aligned with the framework's intent: Clean Architecture,
Riverpod DI, mock + Firebase repository pairs, server-side invariant
enforcement, and small green commits. The biggest gaps are **coverage on
high-touch UI widgets and Firebase repositories**, plus a handful of shallow
leaks (hardcoded colours, empty catches, large state classes).

---

## 1. Domain language

**Score:** 4/5

### Good

- The new `ENGINEERING.md` locks the ubiquitous language: Chore/Task, Family,
  Member, Parent/Guardian, Child, Stars, Treat, Approval, Claim, Settle.
- Server-side economy and firestore rules use the same terms as the UI.
- `TaskStatus` values map to user-facing labels in `task_list_tile.dart:610-625`:
  - `completed` → "Done"
  - `needsRevision` → "Have another go"

### Drift

- `TaskStatus.pendingApproval` is still rendered as "Pending Approval" while
  `DESIGN.md` calls it "Waiting". The duplicate "Waiting" pill was removed
  (`task_list_tile.dart:582-583`), so this is a one-word inconsistency.
- The README still calls the app "Hoque Family Chores" in places where the
  product is branded "Chores Star" / "Home Chores Star"
  (`README.md:1`, `app-identity` memory).

---

## 2. Bounded contexts

**Score:** 4/5

### Good

- No direct `cloud_firestore`, `firebase_auth`, `firebase_messaging`, or
  `firebase_storage` imports found in `lib/domain/` or `lib/presentation/`.
- Cross-context access happens through declared repository interfaces in
  `lib/domain/repositories/`.
- Six contexts are identifiable: auth, family, task, reward, notification,
  analytics.

### Gap

- `FirebasePushNotificationRepository` imports
  `lib/presentation/providers/riverpod/bottom_nav_notifier.dart`
  (`firebase_push_notification_repository.dart:15`). A data-layer repository
  reaching into a presentation provider breaks the dependency rule.

---

## 3. Aggregates / invariants

**Score:** 4/5

### Good

- Star economy (award/claim/settle/refund) lives in Cloud Functions and locks
  `users.points` from clients — the strongest invariant in the system.
- Family isolation is enforced by `firestore.rules` via `familyInvites/{code}`.
- `ApproveTaskUseCase` documents that approval rules are server-side in the
  Cloud Function (`approve_task_usecase.dart:30-38`).

### Gap

- `ApproveTaskUseCase` has two unfinished invariant side-effects as TODOs:
  - streak update (`approve_task_usecase.dart:64`)
  - push notification to doer (`approve_task_usecase.dart:65`)
- A storage failure during `promoteAfterPhotoToBackground` is intentionally
  swallowed (`approve_task_usecase.dart:54-62`). The comment explains why, but
  it is still an exception to the "fail loudly" principle.

---

## 4. Test coverage

**Score:** 3/5

**Measurement:** `flutter test --coverage` followed by parsing `coverage/lcov.info`
for `lib/` files excluding `.g.dart`.

- **lib/ line coverage:** 3,203 / 7,017 = **45.6%**
- **Tests passing:** 414 / 414

### Top uncovered `lib/` files by missing lines

| File | Hit / Total | Missing |
|------|-------------|---------|
| `lib/presentation/screens/task_details_screen.dart` | 0/437 | 437 |
| `lib/data/repositories/firebase_task_repository.dart` | 100/346 | 246 |
| `lib/data/repositories/firebase_push_notification_repository.dart` | 0/202 | 202 |
| `lib/presentation/screens/add_task_screen.dart` | 189/350 | 161 |
| `lib/presentation/widgets/task_list_tile.dart` | 205/358 | 153 |
| `lib/data/repositories/firebase_family_repository.dart` | 28/168 | 140 |
| `lib/presentation/providers/riverpod/auth_notifier.dart` | 118/249 | 131 |
| `lib/data/repositories/firebase_task_completion_repository.dart` | 0/128 | 128 |
| `lib/presentation/providers/riverpod/task_list_notifier.dart` | 48/176 | 128 |
| `lib/data/repositories/firebase_notification_repository.dart` | 0/125 | 125 |

Several complete Firebase repository implementations have **0% coverage**,
meaning the mock variants carry the entire test burden. This is a real risk:
a Firebase-specific bug (e.g., wrong collection path, missing transaction) will
not be caught by the suite.

---

## 5. Testability

**Score:** 4/5

### Good

- Every repository interface has both Firebase and Mock implementations.
- Use cases depend on repository interfaces, not concrete classes.
- Riverpod providers are injected through `lib/di/riverpod_container.dart`.
- Value objects (`UserId`, `FamilyId`, `TaskId`) are trivial to construct in
  tests.

### Gap

- Some notifiers mix state management with small pieces of business logic
  (e.g., `auth_notifier.dart` handles profile completion and deletion),
  making widget tests heavier than pure use-case tests.
- `FirebasePushNotificationRepository` instantiates
  `NotificationPreferencesService()` directly in the constructor if not
  injected (`firebase_push_notification_repository.dart:31`), making it harder
  to unit-test without real SharedPreferences.

---

## 6. Module depth

**Score:** 3/5

### Good

- `UserAvatar` hides avatar precedence (emoji → photo → initial) behind a
  simple widget interface and uses `CachedNetworkImageProvider`.
- `PendingApprovalBadge` now correctly does a one-shot attention draw instead of
  a perpetual pulse (`pending_approval_badge.dart:72-135`).

### Shallow / deep-module violations

- Very large state classes:
  - `_TaskDetailsScreenState` — 959 lines (`task_details_screen.dart`)
  - `_AddTaskScreenState` — 611 lines (`add_task_screen.dart`)
  - `FirebaseTaskRepository` — 651 lines (`firebase_task_repository.dart`)
  - `FirebasePushNotificationRepository` — 603 lines
    (`firebase_push_notification_repository.dart`)
- Hardcoded design-system colour in the data layer:
  - `Color(0xFF6750A4)` (Material 3 default purple) at
    `firebase_push_notification_repository.dart:278` and `:469`, while
    `PRODUCT.md` rejects the M3 template palette.
- `NotificationScreen` uses `NetworkImage(photo)` instead of the cached avatar
  widget (`notifications_screen.dart`, grep result).
- `NotificationPreferencesService` and `NotificationTemplates` are large
  helper classes (229 and 333 lines respectively) that may be leaking decisions
  into callers.

---

## 7. Change amplification

**Score:** 3/5

### Evidence from `git log --since=2026-01-01 --name-only`

Most-edited files (edit count):

| Edits | File |
|-------|------|
| 47 | `pubspec.yaml` |
| 24 | `lib/di/riverpod_container.dart` |
| 21 | `lib/presentation/widgets/task_list_tile.dart` |
| 20 | `lib/main.dart` |
| 17 | `lib/presentation/screens/user_profile_screen.dart` |
| 17 | `lib/presentation/screens/task_list_screen.dart` |
| 16 | `lib/presentation/screens/family_screen.dart` |
| 15 | `lib/presentation/screens/add_task_screen.dart` |
| 14 | `lib/presentation/screens/task_details_screen.dart` |
| 14 | `lib/domain/usecases/usecases.dart` |

Adding a typical task-related feature touches:
`domain/repository` → `domain/usecase` → `data/firebase_repo` +
`data/mock_repo` → `presentation/provider` → `presentation/screen` →
`presentation/widget`. That is 6–7 files, which is moderate amplification.

The `riverpod_container.dart` appearing second-most-edited (24 times) suggests
new providers are frequently added to the DI graph — a natural consequence of
growth, but worth watching.

---

## 8. Error design

**Score:** 3/5

### Good

- Custom failure classes in `lib/core/error/failures.dart` and exceptions in
  `lib/core/error/exceptions.dart`.
- Repository interfaces document which failures may escape.
- `ApproveTaskUseCase` maps `DataException` to `ServerFailure` explicitly.

### Gaps

- Two empty catches in `main_screen.dart:102` and `:179`:
  ```dart
  } catch (_) {}
  ```
  Failures here are silently discarded.
- `ApproveTaskUseCase` swallows a storage failure after approval
  (`approve_task_usecase.dart:60-62`). The comment justifies it, but it is a
  deliberate silent path.
- `pending_approvals_notifier_provider` returns `SizedBox.shrink()` on error
  (`pending_approval_badge.dart:35`), hiding the error from the user.

---

## Top 3 fixes

Ranked by **(5 − dimension score) × change frequency**, where the dimension
score is the worst score affecting the file. This rewards hot files with the
biggest quality gaps.

### 1. `lib/presentation/widgets/task_list_tile.dart`

- **Dimensions:** coverage 3/5, depth 4/5, language 4/5 → worst = 3
- **Change frequency:** 21 edits (highest UI file)
- **Score × freq:** (5 − 3) × 21 = **42**
- **Problems:** 153 missing coverage lines; the widget is the primary task
  surface yet lacks comprehensive tests for its action buttons and status
  transitions.
- **First step:** Add characterization/widget tests for the six task states
  and their action rows; keep behavior unchanged.
- **Effort:** S–M (1–2 days)

### 2. `lib/presentation/screens/add_task_screen.dart`

- **Dimensions:** coverage 3/5, depth 3/5 (611-line state class), language 3/5
  (redundant "Effort Size" label + helper)
- **Change frequency:** 15 edits
- **Score × freq:** (5 − 3) × 15 = **30**
- **Problems:** 161 missing coverage lines; form logic and validation are
  tightly coupled in a single large state class.
- **First step:** Extract a small `AddTaskForm` value object or controller
  and write unit tests for validation logic before any refactor.
- **Effort:** M (2–3 days)

### 3. `lib/data/repositories/firebase_push_notification_repository.dart` + `lib/presentation/screens/notifications_screen.dart`

- **Dimensions:** coverage 0/5, depth 2/5 (603-line repo, data→presentation
  import, hardcoded M3 purple), error design 3/5
- **Change frequency:** 5 (repo) + 5 (screen) = 10
- **Score × freq:** (5 − 0) × 10 = **50** if merged; individually lower.
- **Problems:**
  - Notification colour hardcoded to Material 3 purple (`#6750A4`) at
    `firebase_push_notification_repository.dart:278` and `:469`.
  - `notifications_screen.dart` uses `NetworkImage(photo)` instead of
    `UserAvatar` / `CachedNetworkImage`.
  - Repository imports a presentation provider, breaking layer boundaries.
  - 0% test coverage; Android badge/channel TODO remains
    (`firebase_push_notification_repository.dart` comment near channel setup).
- **First step:** Replace `NetworkImage` with `UserAvatar`; fix the hardcoded
  colour to marigold (`#E08A1E`); add widget tests for the notification tile.
- **Effort:** S (1 day)

---

## Incremental roadmap

No rewrite proposals. Use strangler extraction and boy-scout improvements only.

1. **Week 1 — hot-widget coverage**
   - Characterization tests for `task_list_tile.dart`.
   - Fix the one remaining status-label mismatch (`Pending Approval` → `Waiting`)
     if `DESIGN.md` is still authoritative.

2. **Week 2 — notification quality**
   - Replace `NetworkImage` with `UserAvatar` in `notifications_screen.dart`.
   - Fix M3 purple hardcodes in `firebase_push_notification_repository.dart`.
   - Remove the data→presentation import from the push notification repository.
   - Add widget tests for notification tiles.

3. **Week 3 — error-design cleanup**
   - Replace empty catches in `main_screen.dart` with logged failures or user
    feedback.
   - Decide whether `pending_approval_badge.dart` should show an error state
     instead of `SizedBox.shrink()`.

4. **Week 4+ — large screens**
   - Extract form controllers / value objects from `add_task_screen.dart` and
     `task_details_screen.dart` to improve depth and coverage incrementally.

---

## Not audited

- Generated files (`*.g.dart`, Flutter/plugin generated code).
- `functions/node_modules/`.
- `ios/`, `android/`, `macos/`, `windows/`, `linux/` native platform code except
  for deployment metadata.
- Third-party packages.
