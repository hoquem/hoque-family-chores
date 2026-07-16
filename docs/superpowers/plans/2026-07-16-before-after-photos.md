# Before & After Photos Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A parent can mark a task "requires photo proof"; the assigned child then photographs the mess before starting and the result on completing, and the parent sees both before approving.

**Architecture:** Both photos live on the existing `Task` entity — `photoUrl` (already persisted) is the after, a new `beforePhotoUrl` is the before. A new `TaskStatus.inProgress`, reached by a new Start action, gives the before a capture point that works for claimed *and* parent-assigned tasks. A new `PhotoStorageService` owns compress → upload → download-URL → delete. The dead `TaskCompletion` layer is not touched.

**Tech Stack:** Flutter, Riverpod (codegen), dartz `Either`, Firebase Storage + Firestore, `image_picker` (new), `flutter_image_compress` + `cached_network_image` (present but unused), `mocktail`.

**Spec:** `docs/superpowers/specs/2026-07-16-before-after-photos-design.md`. Read it first — it explains why this is larger than issue #130 says.

---

## Read this before Task 1

Four facts about this codebase that will cost you an hour each if you learn them the hard way:

1. **`Task.copyWith` cannot set a field to `null`.** Every line is `x ?? this.x` (`lib/domain/entities/task.dart:118-126`). `copyWith(beforePhotoUrl: null)` is a **silent no-op**. To clear a field, write Firestore directly, as `unassignTask` does.
2. **`completeTask(familyId, taskId)` takes no photo argument.** It does a targeted status + `completedAt` update. `photoUrl` reaches Firestore only through the whole-document `toFirestore` in `createTask`/`updateTask`.
3. **`TaskStatus` is exhaustively switched in 7 places.** Dart's exhaustiveness checking will find them all when you add a value — let the compiler drive Task 1.
4. **No remote image has ever rendered in this test suite.** Flutter's test `HttpClient` returns 400 for everything. Task 11 exists solely to fix this, and Task 13 cannot be written before it.

## File structure

| File | Responsibility | Task |
|---|---|---|
| `lib/domain/entities/task.dart` | `+ TaskStatus.inProgress`, `+ requiresPhotoProof`, `+ beforePhotoUrl` | 1, 2 |
| `lib/data/repositories/firebase_task_repository.dart` | serialise the 2 new fields; `startTask`; clear-before | 2, 6, 9 |
| `lib/domain/repositories/task_repository.dart` | `+ startTask`, `+ setAfterPhoto` | 6, 8 |
| `lib/data/services/photo_storage_service.dart` | **new** — compress, upload, delete. One responsibility. | 4 |
| `lib/domain/usecases/task/start_task_usecase.dart` | **new** — guard + transition + before-photo | 6 |
| `lib/presentation/widgets/status_pill.dart` | render `inProgress` | 1 |
| `lib/presentation/screens/add_task_screen.dart` | the photo-proof switch | 3 |
| `lib/presentation/widgets/task_list_tile.dart` | Start button; "Can't do it" from `inProgress` | 7, 9 |
| `lib/presentation/widgets/before_after_view.dart` | **new** — the tap-to-toggle pair | 12 |
| `lib/presentation/screens/task_details_screen.dart` | host the pair | 12 |
| `storage.rules`, `firebase.json` | **new/modified** — Storage rules + emulator | 5 |
| `ios/Runner/Info.plist` | `NSCameraUsageDescription` | 4 |

---

### Task 1: `TaskStatus.inProgress`

Adds the value and satisfies every switch. No behaviour yet — nothing can reach the state.

**Files:**
- Modify: `lib/domain/entities/task.dart:208`
- Modify: `lib/presentation/widgets/status_pill.dart:32,41,49`
- Modify: `lib/domain/services/home_stats.dart:49`
- Modify: `lib/presentation/screens/task_details_screen.dart:29`
- Modify: `lib/presentation/widgets/task_list_tile.dart:326,435`
- Test: `test/presentation/theme/status_pill_test.dart` (create)

- [ ] **Step 1: Write the failing test**

```dart
// test/presentation/theme/status_pill_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/status_pill.dart';

void main() {
  testWidgets('inProgress renders the play icon and its label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: appLightTheme,
      home: const Scaffold(
        body: StatusPill(status: TaskStatus.inProgress, label: 'In progress'),
      ),
    ));
    expect(find.byIcon(Icons.play_circle), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/presentation/theme/status_pill_test.dart`
Expected: compile error — `inProgress` isn't a `TaskStatus` value.

- [ ] **Step 3: Add the enum value**

```dart
// lib/domain/entities/task.dart — in enum TaskStatus, after `assigned`
  inProgress, // Started; before-photo taken if the task requires proof
```

- [ ] **Step 4: Let the compiler find every switch**

Run: `flutter analyze`
It will list each non-exhaustive switch. Fix each, per DESIGN.md's status table:
- `status_pill.dart` — tone `t.carrot`, iconTone `t.carrotDeep`, icon `Icons.play_circle`
- `task_details_screen.dart:29` `_statusLabel` — `'In progress'`
- `home_stats.dart:49` — treat as active work, same arm as `assigned`
- `task_list_tile.dart:326` (`_buildActionButtons`) — `return null` for now; Task 7 fills it
- `task_list_tile.dart:435` (`_getStatusText`) — `'In progress'`

- [ ] **Step 5: Verify**

Run: `flutter analyze && flutter test`
Expected: no issues; all tests pass (252+).

- [ ] **Step 6: Commit**

```bash
git add lib/domain/entities/task.dart lib/presentation lib/domain/services test/presentation/theme/status_pill_test.dart
git commit -m "feat(task): add TaskStatus.inProgress

Closes the gap DESIGN.md already documented: its status table lists
Assigned / in-progress with a play_circle icon, a state the enum never had.
Nothing reaches it yet."
```

---

### Task 2: The two new `Task` fields

**Files:**
- Modify: `lib/domain/entities/task.dart` (field, ctor, copyWith, props)
- Modify: `lib/data/repositories/firebase_task_repository.dart:398,439`
- Test: `test/domain/entities/task_test.dart` (create)

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/entities/task_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
// Reuse whatever Task factory the existing tests use; see
// test/features/task/test_helpers.dart for the fixture pattern.

void main() {
  test('requiresPhotoProof defaults to false so existing tasks are unchanged', () {
    expect(makeTask().requiresPhotoProof, isFalse);
  });

  test('beforePhotoUrl round-trips through copyWith', () {
    expect(makeTask().copyWith(beforePhotoUrl: 'x').beforePhotoUrl, 'x');
  });

  test('copyWith CANNOT clear beforePhotoUrl — documents the ?? idiom', () {
    // Pinning the trap: the `x ?? this.x` idiom means passing null is a no-op.
    // Clearing must go through a direct Firestore write (see Task 9).
    final t = makeTask().copyWith(beforePhotoUrl: 'x');
    expect(t.copyWith(beforePhotoUrl: null).beforePhotoUrl, 'x');
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/domain/entities/task_test.dart`
Expected: compile error — no such named parameter.

- [ ] **Step 3: Add the fields**

In `task.dart`: add `final bool requiresPhotoProof;` and `final String? beforePhotoUrl;` beside the existing `photoUrl`; add `this.requiresPhotoProof = false` and `this.beforePhotoUrl` to the constructor; add both to `copyWith` (same `??` idiom — consistency beats cleverness here) and to `props`.

- [ ] **Step 4: Serialise both**

```dart
// firebase_task_repository.dart — in _fromFirestore, beside photoUrl
      requiresPhotoProof: data['requiresPhotoProof'] as bool? ?? false,
      beforePhotoUrl: data['beforePhotoUrl'] as String?,
// — in toFirestore, beside 'photoUrl'
      'requiresPhotoProof': task.requiresPhotoProof,
      'beforePhotoUrl': task.beforePhotoUrl,
```

The `?? false` matters: every task already in Firestore lacks the key.

- [ ] **Step 5: Verify and commit**

```bash
flutter analyze && flutter test
git add lib/domain/entities/task.dart lib/data/repositories/firebase_task_repository.dart test/domain/entities/task_test.dart
git commit -m "feat(task): add requiresPhotoProof and beforePhotoUrl

Defaults false and reads a missing Firestore key as false, so every existing
task is unaffected. photoUrl (existing, already persisted) stays the after."
```

---

### Task 3: The photo-proof switch in Add Task

**Files:**
- Modify: `lib/presentation/screens/add_task_screen.dart`
- Test: `test/presentation/add_task_photo_proof_test.dart` (create)

- [ ] **Step 1: Write the failing test** — pump `AddTaskScreen` at 320pt (copy the harness from `test/presentation/add_task_effort_fits_test.dart`), assert a `SwitchListTile` keyed `photo_proof_switch` exists, is off by default, and toggles.
- [ ] **Step 2: Run it, watch it fail.**
- [ ] **Step 3:** Add `bool _requiresPhotoProof = false;` and a `SwitchListTile` below the effort field, title `Requires photo proof`, subtitle `Ask for a photo before starting and after finishing`. Pass it into `createTask`.
- [ ] **Step 4:** Thread `requiresPhotoProof` through `TaskCreationNotifier.createTask` and the create use case to the entity.
- [ ] **Step 5:** `flutter analyze && flutter test`. The existing add-task tests must still pass — the switch defaults off.
- [ ] **Step 6: Commit** `feat(add-task): parent can require photo proof`

---

### Task 4: `PhotoStorageService` + `image_picker` + iOS permission

**Files:**
- Create: `lib/data/services/photo_storage_service.dart`
- Modify: `pubspec.yaml`, `ios/Runner/Info.plist`
- Test: `test/data/services/photo_storage_service_test.dart` (create)

- [ ] **Step 1: Add the dependency**

```bash
flutter pub add image_picker
```

Android needs **nothing**: `image_picker` uses an intent. Do **not** add a `CAMERA` permission — it would impose a runtime-grant flow the app otherwise avoids.

- [ ] **Step 2: Add the iOS usage string**

`ios/Runner/Info.plist` has no usage-description key at all today, so the camera crashes on first use.

```xml
	<key>NSCameraUsageDescription</key>
	<string>Take before and after photos of your chores so a grown-up can see your work.</string>
```

- [ ] **Step 3: Write the failing test** for `PhotoStorageService.upload` — mock `FirebaseStorage`/`Reference` with `mocktail`, assert the path is `families/{familyId}/tasks/{taskId}/before-<ts>.jpg` and that a compress failure returns `Left(ServerFailure)`.
- [ ] **Step 4: Run it, watch it fail.**
- [ ] **Step 5: Implement.** Copy the compression settings from `firebase_task_completion_repository.dart:24-84` (quality 85, min 1920) — they are sound. Do **not** import that class; it is dead and slated for deletion.

```dart
enum PhotoKind { before, after }

class PhotoStorageService {
  Future<Either<Failure, String>> upload({
    required File photo, required FamilyId familyId,
    required TaskId taskId, required PhotoKind kind,
  }) async { /* compress -> putData -> getDownloadURL */ }

  Future<Either<Failure, void>> delete(String downloadUrl);
}
```

The path is family-scoped **on purpose** — the old `quest_photos/{taskId}/` cannot be secured per family, and uses pre-rename vocabulary. Nothing has ever written to it, so there is nothing to migrate.

- [ ] **Step 6:** Register a `photoStorageServiceProvider` in `lib/di/riverpod_container.dart`, following the `@riverpod` pattern at line 90.
- [ ] **Step 7: Verify and commit** `feat(storage): add PhotoStorageService`

---

### Task 5: Storage rules + emulator (**infrastructure — cannot be verified by unit tests**)

**This is the task that fails silently if skipped.** There is no `storage.rules` and `firebase.json` has no `storage` block. The first upload hits default-deny, at runtime, while every test passes — because Task 4's tests mock the upload.

**Files:** Create `storage.rules`; modify `firebase.json`

- [ ] **Step 1: Write `storage.rules`** — a member of `{familyId}` may read; the assignee may write/delete under their own task; cap size (~5MB) and require `image/*`.
- [ ] **Step 2: Add the `storage` block** to `firebase.json` pointing at it.
- [ ] **Step 3: Add a `storage` emulator** to the `emulators` block. It currently contains **only `dataconnect`** — no storage, no firestore. This is not free.
- [ ] **Step 4: Verify against the emulator** — an authed family member can read; a non-member cannot; an oversized file is rejected.
- [ ] **Step 5: Deploy** — `firebase deploy --only storage`. **Requires the user.** Stop and ask.
- [ ] **Step 6: Commit** `feat(infra): Firebase Storage rules for task photos`

---

### Task 6: `StartTaskUseCase`

**Files:**
- Create: `lib/domain/usecases/task/start_task_usecase.dart`
- Modify: `lib/domain/repositories/task_repository.dart`, `lib/data/repositories/firebase_task_repository.dart`, `lib/di/riverpod_container.dart`
- Test: `test/domain/usecases/start_task_usecase_test.dart` (create)

- [ ] **Step 1: Write the failing test** — starting from `assigned` succeeds and sets `inProgress` + `beforePhotoUrl`; starting from any other status returns `Left(BusinessFailure)`; a non-assignee returns `Left(PermissionFailure)`.
- [ ] **Step 2: Run it, watch it fail.**
- [ ] **Step 3: Implement**, copying the shape of `complete_task_usecase.dart` exactly — same guard order, same `Either`, same failure types.
- [ ] **Step 4:** Add `startTask(familyId, taskId, beforePhotoUrl)` to the repository interface and the Firebase impl (targeted update of `status` + `beforePhotoUrl`).
- [ ] **Step 5:** Register `startTaskUseCaseProvider`, then `dart run build_runner build --delete-conflicting-outputs`.
- [ ] **Step 6: Verify and commit** `feat(task): add StartTaskUseCase`

---

### Task 7: The Start button

**Files:** Modify `lib/presentation/widgets/task_list_tile.dart:326`; Test: `test/presentation/task_list_tile_start_test.dart`

- [ ] **Step 1: Write the failing test** at 320pt — an `assigned` + `requiresPhotoProof` task shows Start; an `assigned` task **without** the flag does not.
- [ ] **Step 2: Run it, watch it fail.**
- [ ] **Step 3: Implement** — in the `assigned` arm, when `widget.task.requiresPhotoProof`, render a Start button (`Icons.play_circle`, label `Start`). Its handler: `ImagePicker().pickImage(source: ImageSource.camera)` → **if null, do nothing and do not change status** (no photo, no start) → `PhotoStorageService.upload(kind: before)` → `StartTaskUseCase`.
- [ ] **Step 4:** If the upload succeeds and the write then fails, **surface the error and leave the status alone**. Do not swallow it. The blob is orphaned; that is the accepted trade (see spec).
- [ ] **Step 5: Verify and commit** `feat(task): Start action captures the before photo`

---

### Task 8: Completion writes the after photo

**Files:** Modify `lib/domain/usecases/task/complete_task_usecase.dart:36-38`, `lib/domain/repositories/task_repository.dart`, `lib/presentation/widgets/task_list_tile.dart`

- [ ] **Step 1: Write the failing test** — completing from `inProgress` succeeds and sets `photoUrl`; a proof task completed with no photo returns a failure.
- [ ] **Step 2: Run it, watch it fail** — it fails on the guard, which rejects `inProgress`. **This is the single most likely way to ship this broken.**
- [ ] **Step 3:** Relax the guard to allow `inProgress`. Add `setAfterPhoto` (or extend `completeTask`) — `completeTask` takes no photo argument today and does a targeted update, so the write must be threaded deliberately.
- [ ] **Step 4:** In the tile's complete handler, capture → upload (`kind: after`) → complete.
- [ ] **Step 5: Verify and commit** `fix(task): allow completing from inProgress, and store the after photo`

---

### Task 9: "Can't do it" clears the before

**Files:** Modify `lib/presentation/widgets/task_list_tile.dart:326`, `lib/data/repositories/firebase_task_repository.dart`

- [ ] **Step 1: Write the failing test** — returning an `inProgress` task to `available` leaves `beforePhotoUrl` null.
- [ ] **Step 2: Run it, watch it fail.**
- [ ] **Step 3:** Make "Can't do it" reachable from `inProgress` — today it renders **only** in the `assigned` arm, so a kid who starts is trapped.
- [ ] **Step 4:** Clear the before with a **direct Firestore field update** (`{'beforePhotoUrl': null, 'status': ...}`), as `unassignTask` does. **`copyWith(beforePhotoUrl: null)` is a silent no-op** — the `?? this.x` idiom. Then `PhotoStorageService.delete`, or the next kid inherits a stranger's before.
- [ ] **Step 5: Verify and commit** `fix(task): clear and delete the before photo on Can't do it`

---

### Task 10: Round-trip test

- [ ] Write one test: flag on → start (before set, `inProgress`) → complete (after set, `pendingApproval`) → both URLs present. This is the test that proves the feature, and the first one that would catch a regression across the whole flow.
- [ ] Commit `test(task): round-trip the photo-proof flow`

---

### Task 11: An image-rendering test harness (**blocks Task 13**)

**No remote image has ever rendered in this suite.** Flutter's test `HttpClient` returns 400 for every request, so a remote image throws. Every fixture sets `photoUrl: null`, which is why nobody has hit it. This is a known-hard Flutter problem — budget it as real work, not one more mock.

- [ ] **Step 1:** `flutter pub add --dev mocktail_image_network` (or hand-roll an `HttpOverrides` harness).
- [ ] **Step 2:** Prove it: a throwaway test that pumps `CachedNetworkImage` inside the harness and does not throw.
- [ ] **Step 3: Commit** `test: add a harness so remote images can render under test`

---

### Task 12: The before/after pair

**Files:** Create `lib/presentation/widgets/before_after_view.dart`; modify `lib/presentation/screens/task_details_screen.dart`; Test: `test/presentation/before_after_view_test.dart`

- [ ] **Step 1: Write the failing test** at **320pt**, inside Task 11's harness — shows the before by default with a visible "Before" label; tapping swaps to the after; nothing overflows.
- [ ] **Step 2: Run it, watch it fail.**
- [ ] **Step 3: Implement** with `CachedNetworkImage` (already a dependency, used nowhere) **with explicit `placeholder` and `errorWidget`**. A photo that silently fails to load, on the screen where a parent decides whether their child did a chore, is the worst place in the app for an ambiguous blank.
- [ ] **Step 4:** Tap-to-toggle, not a slider — a slider implies the frames are aligned, and handheld shots never are. Add a `Semantics` label naming which photo is shown; the swap must be announced, not just seen.
- [ ] **Step 5:** Host it in `task_details_screen` above the actions. Render nothing when `beforePhotoUrl` is null.
- [ ] **Step 6: Verify and commit** `feat(task): show the before/after pair on task details`

---

### Task 13: Verify on the simulator

Tests passing is not the same as it working. See `.claude` memory: get the device-screen origin from the accessibility tree, drive with a process-scoped `click at`, screenshot with `xcrun simctl io booted screenshot`.

- [ ] Create a photo-proof task; confirm the switch persists.
- [ ] Start it; confirm the camera opens and the pill reads "In progress".
- [ ] Complete it; confirm the pair renders for the parent.
- [ ] Confirm **against the deployed rules**, not the emulator. This is the only step that proves Task 5 actually worked.

---

## Definition of done

- [ ] `flutter analyze` clean; `flutter test` green at phone width
- [ ] The existing BDD task-management flows pass **untouched** — the flag is off by default, so any change there means this leaked into the default path
- [ ] Storage rules deployed and verified on a device
- [ ] Issue #130 updated with what shipped, and with the correction that #109 never shipped a photo flow
