# Recurring Chores Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a parent set a repeating chore ("clean the bathroom every Saturday") once; a scheduled Cloud Function spawns each due occurrence as an ordinary task while a client "Repeat" selector and "Stop repeating" action manage the series.

**Architecture:** A rule engine on the server. Parents create a `families/{familyId}/taskRules/{ruleId}` doc (batch-written with the first task) carrying an iCal RRULE and a task template. A Cloud Scheduler tick (`spawnRecurringTasks`, every 15 min) scans enabled rules, and for each due rule transactionally re-reads it, applies a "wait for the previous occurrence" gate, spawns the next task from the template, and advances `nextDueAt` via the `rrule` npm library. The client only maps presets to RRULE strings — no Dart RRULE computation. Tasks spawned carry `ruleId`; the existing `onTaskCreated` trigger notifies the family unchanged.

**Tech Stack:** Flutter/Dart (client), Cloud Functions v2 Node (`firebase-functions/v2/scheduler` `onSchedule`), `rrule` npm package (server-only), Firestore (transactions, batch writes), firestore.rules. Test harnesses: `flutter_test` + `fake_cloud_firestore` + `mocktail` (client), `@firebase/rules-unit-testing` + `firebase emulators:exec` (rules + engine).

## Global Constraints

- **Rule creation:** parents/guardians only; rule `createdBy` must be the writer's own uid (forging it is a rules failure).
- **Assignment:** `assignment: null` = unassigned ("up for grabs"); else fixed child (`{ userId }`). Rotation is out of scope.
- **Overlap gate:** the engine waits for the previous occurrence to resolve — `lastTaskId` set AND that task exists AND its status is not `completed` → skip. A missing task doc counts as resolved. `needsRevision` holds the slot deliberately.
- **First occurrence:** created immediately in the same batch write as the rule; `nextDueAt` = the first task's due date; the engine advances from there.
- **Due date of a spawned task:** `max(nextDueAt, today)` where `today` is start of current day at midnight (the app's date-only convention) — a late catch-up never spawns a back-dated chore.
- **RRULE presets (no Dart RRULE dep):** Daily `FREQ=DAILY`; Weekly `FREQ=WEEKLY;BYDAY=<weekday of picked due date>` (MO…SU); Monthly `FREQ=MONTHLY;BYMONTHDAY=<day-of-month of picked due date>`. `rrule` npm is server-only.
- **Spawned task:** ordinary task doc with `ruleId`, `createdById` = rule `createdBy`, `status` = `assigned` (fixed child) or `available` (unassigned). Existing `onTaskCreated` triggers the push notification — copy reads as coming from the rule creator (accepted MVP copy).
- **Idempotency:** the transaction re-reads the rule; a concurrent tick that already advanced `nextDueAt` is skipped. A per-rule error logs and is skipped; the tick continues.
- **Engine cron:** `7,22,37,52 * * * *` (every 15 min, off the :00/:15 crowd). Single-timezone (UK) is a known simplification — `rrule` computes in UTC; the 15-min tick absorbs the drift.
- **Firestore rules:** `taskRules` read = any family member; create = family member with `me().role in ['parent', 'guardian']` AND `createdBy == request.auth.uid`; delete = parents/guardians; update = `false`. A **widening** change → ships ahead of (or with, never after) the client build.
- **Task validation:** rule creation reuses the exact `CreateTaskUseCase` rules (title 1–100 chars, description ≤ 500, points 1–1000, due date not past by day, tags ≤ 10 each ≤ 20 chars). Engine still guards defensively (missing `template.title` / `template.points` → skip + log).
- **Dead scaffolding:** `recurringPattern` / `lastCompletedAt` on `Task` stay dead. Do not wire them up — the rule engine supersedes them.
- **Verification:** every task ends green (`flutter test <path>` / `npm test` / emulator run shown). Commit per task, imperative one-line subject, body explains the why when non-obvious, `Co-Authored-By: Claude <noreply@anthropic.com>` trailer.

## File Structure

**Client (`lib/`):**
- `domain/entities/recurring_rule.dart` (new) — `RecurringRule` entity.
- `domain/services/recurrence.dart` (new) — `RepeatPreset` enum + `rruleForRepeat()` + `canStopRepeating()` pure helpers.
- `domain/services/task_validation.dart` (new) — `validateTaskInput()` shared validator (extracted from `CreateTaskUseCase`).
- `domain/entities/task.dart` — add `final String? ruleId;` (+ constructor, `copyWith`, `props`).
- `domain/usecases/task/create_recurring_chore_usecase.dart` (new) — builds first task + rule, calls repository.
- `domain/usecases/task/create_task_usecase.dart` — delegate validation to `validateTaskInput()` (no behavior change).
- `domain/repositories/task_repository.dart` — add `createRecurringChore()` + `deleteRecurringRule()`.
- `data/repositories/firebase_task_repository.dart` — batch write (task + rule), rule delete, `ruleId` in task maps, `_mapRuleToFirestore()`.
- `presentation/providers/riverpod/task_creation_notifier.dart` — `repeat` param routing to the recurring use case.
- `di/riverpod_container.dart` — add `createRecurringChoreUseCaseProvider`.
- `presentation/widgets/repeat_selector.dart` (new) — the Repeat dropdown row (parents only).
- `presentation/screens/add_task_screen.dart` — embed `RepeatSelector`; pass `repeat` on submit.
- `presentation/widgets/stop_repeating_button.dart` (new) — confirm-dialog delete button.
- `presentation/screens/task_details_screen.dart` — Recurring badge + `StopRepeatingButton` when `canStopRepeating()`.

**Server (`functions/`):**
- `functions/recurringEngine.js` (new) — `processRule()` + `spawnDueOccurrences()`; pure module (takes `db`, never calls `initializeApp`) so the emulator test can import it.
- `functions/index.js` — add `spawnRecurringTasks` `onSchedule` export.
- `functions/package.json` — add `rrule` dependency + `test:recurring` script.

**Rules / tests:**
- `firestore.rules` — `match /taskRules/{ruleId}` block.
- `test/rules/task_rules.test.mjs` (new) — rules-unit-testing suite.
- `test/rules/recurring_engine.test.mjs` (new) — emulator integration for the engine.
- `test/domain/services/recurrence_test.dart`, `test/domain/entities/recurring_rule_test.dart` (new)
- `test/domain/usecases/task/create_recurring_chore_usecase_test.dart` (new)
- `test/data/repositories/firebase_task_repository_*` — extend with batch + delete + ruleId round-trip tests.
- `test/presentation/widgets/repeat_selector_test.dart`, `stop_repeating_button_test.dart` (new)

---

### Task 1: Domain — `RepeatPreset`, `rruleForRepeat`, `RecurringRule`

**Files:**
- Create: `lib/domain/services/recurrence.dart`
- Create: `lib/domain/entities/recurring_rule.dart`
- Test: `test/domain/services/recurrence_test.dart`
- Test: `test/domain/entities/recurring_rule_test.dart`

**Interfaces:**
- Produces: `enum RepeatPreset { never, daily, weekly, monthly }`; `String? rruleForRepeat(RepeatPreset preset, DateTime dueDate)`; `bool canStopRepeating(UserRole role, String? ruleId)`; `class RecurringRule extends Equatable` with named params `{required String id, required FamilyId familyId, required String rrule, required String title, required String description, required TaskDifficulty difficulty, required Points points, required List<String> tags, required bool requiresPhotoProof, UserId? assignedToId, required UserId createdBy, required DateTime nextDueAt, String? lastTaskId}` and `copyWith`.

- [ ] **Step 1: Write the failing tests**

`test/domain/services/recurrence_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/services/recurrence.dart';

void main() {
  group('rruleForRepeat', () {
    test('never returns null', () {
      expect(rruleForRepeat(RepeatPreset.never, DateTime(2026, 8, 15)), isNull);
    });

    test('daily is FREQ=DAILY regardless of date', () {
      expect(rruleForRepeat(RepeatPreset.daily, DateTime(2026, 8, 15)), 'FREQ=DAILY');
    });

    test('weekly pins the weekday of the due date', () {
      // 2026-08-15 is a Saturday.
      expect(rruleForRepeat(RepeatPreset.weekly, DateTime(2026, 8, 15)),
          'FREQ=WEEKLY;BYDAY=SA');
      // 2026-08-17 is a Monday.
      expect(rruleForRepeat(RepeatPreset.weekly, DateTime(2026, 8, 17)),
          'FREQ=WEEKLY;BYDAY=MO');
      expect(rruleForRepeat(RepeatPreset.weekly, DateTime(2026, 8, 14)),
          'FREQ=WEEKLY;BYDAY=FR');
      expect(rruleForRepeat(RepeatPreset.weekly, DateTime(2026, 8, 13)),
          'FREQ=WEEKLY;BYDAY=TH');
    });

    test('monthly pins the day-of-month', () {
      expect(rruleForRepeat(RepeatPreset.monthly, DateTime(2026, 8, 31)),
          'FREQ=MONTHLY;BYMONTHDAY=31');
      expect(rruleForRepeat(RepeatPreset.monthly, DateTime(2026, 8, 1)),
          'FREQ=MONTHLY;BYMONTHDAY=1');
    });
  });

  group('canStopRepeating', () {
    test('parents and guardians can stop a repeating task', () {
      expect(canStopRepeating(UserRole.parent, 'rule-1'), isTrue);
      expect(canStopRepeating(UserRole.guardian, 'rule-1'), isTrue);
    });

    test('children and one-off tasks cannot be stopped', () {
      expect(canStopRepeating(UserRole.child, 'rule-1'), isFalse);
      expect(canStopRepeating(UserRole.parent, null), isFalse);
    });
  });
}
```

`test/domain/entities/recurring_rule_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/recurring_rule.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

void main() {
  RecurringRule buildRule() => const RecurringRule(
        id: 'rule-1',
        familyId: FamilyId('fam-1'),
        rrule: 'FREQ=WEEKLY;BYDAY=SA',
        title: 'Clean the bathroom',
        description: '',
        difficulty: TaskDifficulty.medium,
        points: Points(25),
        tags: [],
        requiresPhotoProof: false,
        createdBy: UserId('parent-1'),
        nextDueAt: DateTime(2026, 8, 15),
      );

  test('props cover all fields for equality', () {
    expect(buildRule(), equals(buildRule()));
    expect(buildRule().copyWith(rrule: 'FREQ=DAILY'),
        isNot(equals(buildRule())));
    expect(buildRule().copyWith(title: 'Different'),
        isNot(equals(buildRule())));
    expect(buildRule().copyWith(lastTaskId: 'task-9'),
        isNot(equals(buildRule())));
    expect(buildRule().copyWith(assignedToId: UserId('kid-1')),
        isNot(equals(buildRule())));
  });

  test('copyWith only changes the named field', () {
    final r = buildRule().copyWith(assignedToId: UserId('kid-1'));
    expect(r.assignedToId, const UserId('kid-1'));
    expect(r.id, 'rule-1');
    expect(r.nextDueAt, DateTime(2026, 8, 15));
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/domain/services/recurrence_test.dart test/domain/entities/recurring_rule_test.dart`
Expected: FAIL — `recurrence.dart` and `recurring_rule.dart` don't exist (compile error).

- [ ] **Step 3: Write the implementation**

`lib/domain/services/recurrence.dart`:

```dart
import '../entities/user.dart' show UserRole;

/// How often a repeating chore recurs. `never` is a one-off task — the
/// add-task default.
enum RepeatPreset { never, daily, weekly, monthly }

/// Maps a [preset] and the picked [dueDate] to an iCal RRULE string, or null
/// for [RepeatPreset.never]. The pattern derives from the due date: Weekly
/// recurs on that date's weekday, Monthly on its day-of-month. This is the
/// whole of the client's RRULE knowledge — the server's `rrule` lib does the
/// real computation.
String? rruleForRepeat(RepeatPreset preset, DateTime dueDate) {
  switch (preset) {
    case RepeatPreset.never:
      return null;
    case RepeatPreset.daily:
      return 'FREQ=DAILY';
    case RepeatPreset.weekly:
      const days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
      return 'FREQ=WEEKLY;BYDAY=${days[dueDate.weekday - 1]}';
    case RepeatPreset.monthly:
      return 'FREQ=MONTHLY;BYMONTHDAY=${dueDate.day}';
  }
}

/// Whether [role] may stop the recurring series a task belongs to. Only
/// parents/guardians manage rules; a null [ruleId] means the task is a one-off.
bool canStopRepeating(UserRole role, String? ruleId) =>
    ruleId != null &&
    (role == UserRole.parent || role == UserRole.guardian);
```

`lib/domain/entities/recurring_rule.dart`:

```dart
import 'package:equatable/equatable.dart';
import '../entities/task.dart' show TaskDifficulty;
import '../value_objects/family_id.dart';
import '../value_objects/points.dart';
import '../value_objects/user_id.dart';

/// A recurring-chore rule: the template a chore is spawned from, on the
/// schedule its RRULE describes. Stored at families/{familyId}/taskRules.
/// The client only ever *creates* and *deletes* these — reading them back is
/// the engine's job.
class RecurringRule extends Equatable {
  final String id;
  final FamilyId familyId;
  final String rrule;
  final String title;
  final String description;
  final TaskDifficulty difficulty;
  final Points points;
  final List<String> tags;
  final bool requiresPhotoProof;

  /// Null = unassigned ("up for grabs"); otherwise the fixed child.
  final UserId? assignedToId;

  final UserId createdBy;

  /// When the next occurrence is due. At creation this equals the first
  /// task's due date; the engine advances it from there.
  final DateTime nextDueAt;

  /// Gating: the engine waits for the occurrence this points at to resolve
  /// before spawning the next. Set by the creation batch write and the engine.
  final String? lastTaskId;

  const RecurringRule({
    required this.id,
    required this.familyId,
    required this.rrule,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.points,
    required this.tags,
    required this.requiresPhotoProof,
    this.assignedToId,
    required this.createdBy,
    required this.nextDueAt,
    this.lastTaskId,
  });

  RecurringRule copyWith({
    String? id,
    FamilyId? familyId,
    String? rrule,
    String? title,
    String? description,
    TaskDifficulty? difficulty,
    Points? points,
    List<String>? tags,
    bool? requiresPhotoProof,
    UserId? assignedToId,
    UserId? createdBy,
    DateTime? nextDueAt,
    String? lastTaskId,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      rrule: rrule ?? this.rrule,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      points: points ?? this.points,
      tags: tags ?? this.tags,
      requiresPhotoProof: requiresPhotoProof ?? this.requiresPhotoProof,
      assignedToId: assignedToId ?? this.assignedToId,
      createdBy: createdBy ?? this.createdBy,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      lastTaskId: lastTaskId ?? this.lastTaskId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        rrule,
        title,
        description,
        difficulty,
        points,
        tags,
        requiresPhotoProof,
        assignedToId,
        createdBy,
        nextDueAt,
        lastTaskId,
      ];
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/domain/services/recurrence_test.dart test/domain/entities/recurring_rule_test.dart`
Expected: PASS (2 groups, 9 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/domain/services/recurrence.dart lib/domain/entities/recurring_rule.dart \
  test/domain/services/recurrence_test.dart test/domain/entities/recurring_rule_test.dart
git commit -m "feat(chores): add recurring-rule domain types and RRULE presets

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 2: Domain — `Task.ruleId` field + Firestore mapping

**Files:**
- Modify: `lib/domain/entities/task.dart` (add `ruleId`)
- Modify: `lib/data/repositories/firebase_task_repository.dart` (`_mapFirestoreToTask` / `_mapTaskToFirestore`)
- Modify: `test/domain/entities/task_test.dart` (if it constructs/asserts `props`)
- Test: `test/data/repositories/firebase_task_repository_mapping_test.dart` (new, or extend the existing mapping test if one exists)

**Interfaces:**
- Consumes: `Task` entity (adds `final String? ruleId;`).
- Produces: spawned tasks round-trip `ruleId` through Firestore; absent `ruleId` maps to null (one-off tasks unaffected).

- [ ] **Step 1: Write the failing test**

Create `test/data/repositories/firebase_task_repository_mapping_test.dart`:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/repositories/firebase_task_repository.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

// Mirror the seed helper from the existing repository tests.
Future<Task> writeAndRead(FirebaseTaskRepository repo, Task task) async {
  await repo.createTask(task);
  final tasks = await repo.getTasksForFamily(task.familyId);
  return tasks.firstWhere((t) => t.id == task.id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('task with ruleId round-trips ruleId', () async {
    final db = FakeFirestore();
    final repo = FirebaseTaskRepository(firestore: db, photoStorage: _NoopPhotoStorage());
    final task = Task(
      id: const TaskId('task-1'),
      title: 'Clean the bathroom',
      description: '',
      status: TaskStatus.available,
      difficulty: TaskDifficulty.medium,
      dueDate: DateTime(2026, 8, 15),
      assignedToId: null,
      createdById: const UserId('parent-1'),
      createdAt: DateTime(2026, 8, 14),
      completedAt: null,
      points: const Points(25),
      tags: const [],
      recurringPattern: null,
      lastCompletedAt: null,
      familyId: const FamilyId('fam-1'),
      requiresPhotoProof: false,
      ruleId: 'rule-1',
    );

    final read = await writeAndRead(repo, task);

    expect(read.ruleId, 'rule-1');
  });

  test('task without ruleId round-trips as null', () async {
    final db = FakeFirestore();
    final repo = FirebaseTaskRepository(firestore: db, photoStorage: _NoopPhotoStorage());
    final task = Task(
      id: const TaskId('task-2'),
      title: 'Take out bins',
      description: '',
      status: TaskStatus.available,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 8, 15),
      assignedToId: null,
      createdById: const UserId('parent-1'),
      createdAt: DateTime(2026, 8, 14),
      completedAt: null,
      points: const Points(10),
      tags: const [],
      recurringPattern: null,
      lastCompletedAt: null,
      familyId: const FamilyId('fam-1'),
      requiresPhotoProof: false,
    );

    final read = await writeAndRead(repo, task);

    expect(read.ruleId, isNull);
  });
}

class _NoopPhotoStorage implements PhotoStorage {
  // Reuse whatever the existing repository tests use — copy the minimal stub
  // from test/data/repositories/firebase_task_repository_edit_test.dart.
  @override
  Future<void> deletePhotosForTask(Task task) async {}
}
```

Check the actual `PhotoStorage` interface in the existing edit test before finalizing `_NoopPhotoStorage` — it may need more methods.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/repositories/firebase_task_repository_mapping_test.dart`
Expected: FAIL — `ruleId` isn't a `Task` field (compile error) or `read.ruleId` is null.

- [ ] **Step 3: Add the `ruleId` field**

In `lib/domain/entities/task.dart` after `lastCompletedAt`:

```dart
  final String? lastCompletedAt;

  /// Id of the taskRules doc this task was spawned from, when it is a
  /// recurring occurrence. Null for ordinary one-off tasks.
  final String? ruleId;

  final FamilyId familyId;
```

In the constructor after `this.lastCompletedAt`:

```dart
    this.lastCompletedAt,
    this.ruleId,
    required this.familyId,
```

In `copyWith` after `String? lastCompletedAt`:

```dart
    String? lastCompletedAt,
    String? ruleId,
```

and in the body after `lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,`:

```dart
      ruleId: ruleId ?? this.ruleId,
```

In `props`, add `ruleId` to the list.

- [ ] **Step 4: Wire the repository mapping**

In `lib/data/repositories/firebase_task_repository.dart`:

`_mapFirestoreToTask` — after the `lastCompletedAt` parse:

```dart
      ruleId: data['ruleId'] as String?,
```

`_mapTaskToFirestore` — after `'lastCompletedAt': task.lastCompletedAt,`:

```dart
      'ruleId': task.ruleId,
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/data/repositories/firebase_task_repository_mapping_test.dart`
Expected: PASS. Then run the full repository suite to confirm one-off mapping tests still pass: `flutter test test/data/repositories/`.

- [ ] **Step 6: Commit**

```bash
git add lib/domain/entities/task.dart lib/data/repositories/firebase_task_repository.dart \
  test/data/repositories/firebase_task_repository_mapping_test.dart
git commit -m "feat(chores): carry ruleId on spawned tasks

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 3: Repository — batch write + rule delete

**Files:**
- Modify: `lib/domain/repositories/task_repository.dart`
- Modify: `lib/data/repositories/firebase_task_repository.dart`
- Test: `test/data/repositories/firebase_task_repository_recurring_test.dart` (new)

**Interfaces:**
- Produces: `Future<Task> createRecurringChore({required Task firstTask, required RecurringRule rule})` — atomic batch: task doc + rule doc (rule `nextDueAt` = `firstTask.dueDate`, `lastTaskId` = the new task id); returns the task with its real id and `ruleId` set. `Future<void> deleteRecurringRule(FamilyId familyId, String ruleId)` — idempotent delete (missing doc deletes cleanly).

- [ ] **Step 1: Write the failing tests**

`test/data/repositories/firebase_task_repository_recurring_test.dart`:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/data/repositories/firebase_task_repository.dart';
import 'package:hoque_family_chores/domain/entities/recurring_rule.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

// Minimal photo-storage stub — copy from the existing repository tests.
class _NoopPhotoStorage implements PhotoStorage {
  @override
  Future<void> deletePhotosForTask(Task task) async {}
}

Task baseTask() => Task(
      id: const TaskId('new'),
      title: 'Clean the bathroom',
      description: '',
      status: TaskStatus.available,
      difficulty: TaskDifficulty.medium,
      dueDate: DateTime(2026, 8, 15),
      assignedToId: null,
      createdById: const UserId('parent-1'),
      createdAt: DateTime(2026, 8, 14),
      completedAt: null,
      points: const Points(25),
      tags: const [],
      recurringPattern: null,
      lastCompletedAt: null,
      familyId: const FamilyId('fam-1'),
      requiresPhotoProof: false,
    );

RecurringRule baseRule() => const RecurringRule(
      id: 'new',
      familyId: FamilyId('fam-1'),
      rrule: 'FREQ=WEEKLY;BYDAY=SA',
      title: 'Clean the bathroom',
      description: '',
      difficulty: TaskDifficulty.medium,
      points: Points(25),
      tags: [],
      requiresPhotoProof: false,
      createdBy: UserId('parent-1'),
      nextDueAt: DateTime(2026, 8, 15),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('createRecurringChore writes task and rule atomically', () async {
    final db = FakeFirestore();
    final repo = FirebaseTaskRepository(firestore: db, photoStorage: _NoopPhotoStorage());

    final created = await repo.createRecurringChore(firstTask: baseTask(), rule: baseRule());

    expect(created.ruleId, isNotNull);
    expect(created.id, isNot(const TaskId('new')));

    final taskSnap = await db
        .collection('families').doc('fam-1').collection('tasks').doc(created.id.value)
        .get();
    expect(taskSnap.exists, isTrue);
    expect(taskSnap.data()!['ruleId'], created.ruleId);

    final ruleSnap = await db
        .collection('families').doc('fam-1').collection('taskRules').doc(created.ruleId)
        .get();
    expect(ruleSnap.exists, isTrue);
    final rule = ruleSnap.data()!;
    expect(rule['trigger'], {'type': 'schedule', 'rrule': 'FREQ=WEEKLY;BYDAY=SA'});
    expect(rule['enabled'], isTrue);
    expect(rule['lastTaskId'], created.id.value);
    expect((rule['nextDueAt'] as DateTime?)?.toIso8601String(),
        DateTime(2026, 8, 15).toIso8601String());
    expect((rule['template'] as Map)['title'], 'Clean the bathroom');
    expect(rule['createdBy'], 'parent-1');
    expect(rule.containsKey('assignment'), isFalse); // unassigned → field omitted
  });

  test('createRecurringChore with a fixed child writes assignment and assigned status', () async {
    final db = FakeFirestore();
    final repo = FirebaseTaskRepository(firestore: db, photoStorage: _NoopPhotoStorage());
    final task = baseTask().copyWith(assignedToId: const UserId('kid-1'));
    final rule = baseRule().copyWith(assignedToId: const UserId('kid-1'));

    final created = await repo.createRecurringChore(firstTask: task, rule: rule);

    final ruleSnap = await db
        .collection('families').doc('fam-1').collection('taskRules').doc(created.ruleId)
        .get();
    expect(ruleSnap.data()!['assignment'], {'userId': 'kid-1'});
    final taskSnap = await db
        .collection('families').doc('fam-1').collection('tasks').doc(created.id.value)
        .get();
    expect(taskSnap.data()!['status'], 'assigned');
    expect(taskSnap.data()!['assignedToId'], 'kid-1');
  });

  test('deleteRecurringRule deletes the rule and is idempotent', () async {
    final db = FakeFirestore();
    final repo = FirebaseTaskRepository(firestore: db, photoStorage: _NoopPhotoStorage());

    await repo.createRecurringChore(firstTask: baseTask(), rule: baseRule());
    final rules = await db.collection('families').doc('fam-1').collection('taskRules').get();
    final ruleId = rules.docs.single.id;

    await repo.deleteRecurringRule(const FamilyId('fam-1'), ruleId);
    expect((await db.collection('families').doc('fam-1').collection('taskRules').get()).docs, isEmpty);

    // Deleting again is a no-op, not an error.
    await repo.deleteRecurringRule(const FamilyId('fam-1'), ruleId);
  });
}
```

Note: `FakeFirestore` stores `DateTime` and `Timestamp` — check how the existing edit test asserts timestamps; adjust the `nextDueAt` assertion to match (`as Timestamp?` → `.toDate()` or `as DateTime` depending on what `batch.set` with a `DateTime` produces).

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/data/repositories/firebase_task_repository_recurring_test.dart`
Expected: FAIL — `createRecurringChore`/`deleteRecurringRule` don't exist.

- [ ] **Step 3: Add the interface methods**

`lib/domain/repositories/task_repository.dart`:

```dart
  /// Creates the first occurrence of a recurring chore and its rule in one
  /// atomic commit. The rule's [RecurringRule.nextDueAt] is the first task's
  /// due date and its [RecurringRule.lastTaskId] the new task — the engine
  /// advances both from there.
  Future<Task> createRecurringChore({
    required Task firstTask,
    required RecurringRule rule,
  });

  /// Deletes a recurring rule, stopping the series. Existing occurrences stay
  /// (they are ordinary tasks). Deleting a missing rule is a no-op.
  Future<void> deleteRecurringRule(FamilyId familyId, String ruleId);
```

- [ ] **Step 4: Implement in the Firebase repository**

In `firebase_task_repository.dart` (next to `createTask`):

```dart
  @override
  Future<Task> createRecurringChore({
    required Task firstTask,
    required RecurringRule rule,
  }) async {
    try {
      final taskRef = _firestore
          .collection('families')
          .doc(firstTask.familyId.value)
          .collection('tasks')
          .doc();
      // Real rule id comes from Firestore; the use case's placeholder is
      // discarded here. The task's ruleId must point at the same doc.
      final ruleRef = _firestore
          .collection('families')
          .doc(rule.familyId.value)
          .collection('taskRules')
          .doc();
      final taskWithId = firstTask.copyWith(
        id: TaskId(taskRef.id),
        ruleId: ruleRef.id,
      );

      final batch = _firestore.batch();
      batch.set(taskRef, _mapTaskToFirestore(taskWithId));
      batch.set(ruleRef, _mapRuleToFirestore(rule.copyWith(
        id: ruleRef.id,
        lastTaskId: taskRef.id,
      )));
      await batch.commit();
      return taskWithId;
    } catch (e) {
      throw ServerException('Failed to create recurring chore: $e',
          code: 'RECURRING_CREATE_ERROR');
    }
  }

  @override
  Future<void> deleteRecurringRule(FamilyId familyId, String ruleId) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('taskRules')
          .doc(ruleId)
          .delete();
    } catch (e) {
      throw ServerException('Failed to stop repeating: $e',
          code: 'RECURRING_DELETE_ERROR');
    }
  }

  /// Maps a [RecurringRule] to its Firestore document. `assignment` is
  /// omitted entirely when unassigned (Firestore has no null values).
  Map<String, dynamic> _mapRuleToFirestore(RecurringRule rule) => {
        'trigger': {'type': 'schedule', 'rrule': rule.rrule},
        'template': {
          'title': rule.title,
          'description': rule.description,
          'difficulty': rule.difficulty.name,
          'points': rule.points.toInt(),
          'tags': rule.tags,
          'requiresPhotoProof': rule.requiresPhotoProof,
        },
        if (rule.assignedToId != null)
          'assignment': {'userId': rule.assignedToId!.value},
        'enabled': true,
        'nextDueAt': rule.nextDueAt,
        'lastTaskId': rule.lastTaskId,
        'createdBy': rule.createdBy.value,
        'createdAt': FieldValue.serverTimestamp(),
      };
```

Check `ServerException` import (already imported in the file) and the existing `createTask` error pattern for the code string convention.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/data/repositories/firebase_task_repository_recurring_test.dart`
Expected: PASS. Then the full repository suite: `flutter test test/data/repositories/`.

- [ ] **Step 6: Commit**

```bash
git add lib/domain/repositories/task_repository.dart \
  lib/data/repositories/firebase_task_repository.dart \
  test/data/repositories/firebase_task_repository_recurring_test.dart
git commit -m "feat(chores): batch-write recurring rule with first task

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 4: Use case — `CreateRecurringChoreUseCase` + shared validator

**Files:**
- Create: `lib/domain/services/task_validation.dart`
- Modify: `lib/domain/usecases/task/create_task_usecase.dart` (delegate to shared validator)
- Create: `lib/domain/usecases/task/create_recurring_chore_usecase.dart`
- Test: `test/domain/usecases/task/create_recurring_chore_usecase_test.dart` (new)

**Interfaces:**
- Produces: `ValidationFailure? validateTaskInput({required String title, String? description, required int points, required DateTime dueDate, required List<String> tags})` — exact `CreateTaskUseCase` rules, returns null when valid. `Future<Either<Failure, Task>> CreateRecurringChoreUseCase.call({required String title, String? description, required int points, required TaskDifficulty difficulty, required DateTime dueDate, required FamilyId familyId, required UserId createdById, UserId? assignedToId, List<String> tags = const [], bool requiresPhotoProof = false, required String rrule})`.

- [ ] **Step 1: Extract the shared validator and write its test**

Move `_validateTaskInput` body from `create_task_usecase.dart` into `lib/domain/services/task_validation.dart`, unchanged logic, returning `ValidationFailure?` (null = valid) instead of `Either<Failure, void>`:

```dart
import '../../core/error/failures.dart';

/// The task-input rules shared by one-off and recurring creation. Returns a
/// [ValidationFailure] describing the problem, or null when valid. The rule
/// engine relies on these checks, so recurring creation uses the exact same
/// rules as a hand-added chore.
ValidationFailure? validateTaskInput({
  required String title,
  String? description,
  required int points,
  required DateTime dueDate,
  required List<String> tags,
}) {
  if (title.trim().isEmpty) {
    return ValidationFailure('Task title cannot be empty');
  }
  if (title.trim().length > 100) {
    return ValidationFailure('Task title cannot exceed 100 characters');
  }
  if (description != null && description.trim().length > 500) {
    return ValidationFailure('Task description cannot exceed 500 characters');
  }
  if (points < 1 || points > 1000) {
    return ValidationFailure('Task points must be between 1 and 1000');
  }

  // Compare calendar days, not moments: the date picker returns midnight of
  // the chosen day, so "today" is 00:00 — always before `now`. Only genuinely
  // past days are refused.
  final now = DateTime.now();
  final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final today = DateTime(now.year, now.month, now.day);
  if (dueDay.isBefore(today)) {
    return ValidationFailure('Due date cannot be in the past');
  }

  if (tags.length > 10) {
    return ValidationFailure('Cannot have more than 10 tags');
  }
  for (final tag in tags) {
    if (tag.trim().isEmpty) {
      return ValidationFailure('Tag cannot be empty');
    }
    if (tag.trim().length > 20) {
      return ValidationFailure('Tag cannot exceed 20 characters');
    }
  }

  return null;
}
```

In `create_task_usecase.dart`, replace the `_validateTaskInput` call with:

```dart
      final validationFailure = validateTaskInput(
        title: title,
        description: description,
        points: points,
        dueDate: dueDate,
        tags: tags,
      );
      if (validationFailure != null) {
        return Left(validationFailure);
      }
```

and delete the private `_validateTaskInput` method. Existing `create_task_usecase_test.dart` (or the suite that covers it) must still pass — run it.

- [ ] **Step 2: Write the failing use-case test**

`test/domain/usecases/task/create_recurring_chore_usecase_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/recurring_rule.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/repositories/task_repository.dart';
import 'package:hoque_family_chores/domain/usecases/task/create_recurring_chore_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late _MockTaskRepository repo;
  late CreateRecurringChoreUseCase useCase;

  setUp(() {
    repo = _MockTaskRepository();
    useCase = CreateRecurringChoreUseCase(repo);
  });

  test('creates the recurring chore with a valid template', () async {
    final created = Task(
      id: const TaskId('task-1'),
      title: 'Clean the bathroom',
      description: '',
      status: TaskStatus.available,
      difficulty: TaskDifficulty.medium,
      dueDate: DateTime(2026, 8, 15),
      assignedToId: null,
      createdById: const UserId('parent-1'),
      createdAt: DateTime(2026, 8, 14),
      completedAt: null,
      points: const Points(25),
      tags: const [],
      recurringPattern: null,
      lastCompletedAt: null,
      familyId: const FamilyId('fam-1'),
      requiresPhotoProof: false,
      ruleId: 'rule-1',
    );
    when(() => repo.createRecurringChore(
        firstTask: any(named: 'firstTask'), rule: any(named: 'rule')))
        .thenAnswer((_) async => created);

    final result = await useCase.call(
      title: 'Clean the bathroom',
      points: 25,
      difficulty: TaskDifficulty.medium,
      dueDate: DateTime(2026, 8, 15),
      familyId: const FamilyId('fam-1'),
      createdById: const UserId('parent-1'),
      rrule: 'FREQ=WEEKLY;BYDAY=SA',
    );

    expect(result, isA<Right<Failure, Task>>());
    expect(result.getOrElse(() => throw StateError('unreachable')).ruleId, 'rule-1');

    final captured = verify(() => repo.createRecurringChore(
        firstTask: captureAny(named: 'firstTask'), rule: captureAny(named: 'rule')))
        .captured;
    final rule = captured[1] as RecurringRule;
    expect(rule.rrule, 'FREQ=WEEKLY;BYDAY=SA');
    expect(rule.nextDueAt, DateTime(2026, 8, 15));
    expect(rule.lastTaskId, isNull); // repository assigns the real id
    final firstTask = captured[0] as Task;
    expect(firstTask.status, TaskStatus.available);
    expect(firstTask.ruleId, isNull);
  });

  test('passes through an invalid title as a ValidationFailure', () async {
    final result = await useCase.call(
      title: '   ',
      points: 25,
      difficulty: TaskDifficulty.medium,
      dueDate: DateTime(2026, 8, 15),
      familyId: const FamilyId('fam-1'),
      createdById: const UserId('parent-1'),
      rrule: 'FREQ=DAILY',
    );

    expect(result, isA<Left<Failure, Task>>());
    expect(result.swap().getOrElse(() => throw StateError('unreachable')),
        isA<ValidationFailure>());
    verifyNever(() => repo.createRecurringChore(
        firstTask: any(named: 'firstTask'), rule: any(named: 'rule')));
  });

  test('past due date is rejected before touching the repository', () async {
    final result = await useCase.call(
      title: 'Clean the bathroom',
      points: 25,
      difficulty: TaskDifficulty.medium,
      dueDate: DateTime(2020, 1, 1),
      familyId: const FamilyId('fam-1'),
      createdById: const UserId('parent-1'),
      rrule: 'FREQ=WEEKLY;BYDAY=SA',
    );

    expect(result, isA<Left<Failure, Task>>());
    verifyNever(() => repo.createRecurringChore(
        firstTask: any(named: 'firstTask'), rule: any(named: 'rule')));
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/domain/usecases/task/create_recurring_chore_usecase_test.dart`
Expected: FAIL — class doesn't exist.

- [ ] **Step 4: Write the use case**

`lib/domain/usecases/task/create_recurring_chore_usecase.dart`:

```dart
import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../entities/recurring_rule.dart';
import '../../entities/task.dart';
import '../../repositories/task_repository.dart';
import '../../services/task_validation.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/points.dart';
import '../../value_objects/task_id.dart';
import '../../value_objects/user_id.dart';

/// Creates the first occurrence of a recurring chore together with its rule.
/// Shares the exact validation rules of [CreateTaskUseCase] so the engine
/// never sees a garbage template.
class CreateRecurringChoreUseCase {
  final TaskRepository _taskRepository;

  CreateRecurringChoreUseCase(this._taskRepository);

  Future<Either<Failure, Task>> call({
    required String title,
    String? description,
    required int points,
    required TaskDifficulty difficulty,
    required DateTime dueDate,
    required FamilyId familyId,
    required UserId createdById,
    UserId? assignedToId,
    List<String> tags = const [],
    bool requiresPhotoProof = false,
    required String rrule,
  }) async {
    final validationFailure = validateTaskInput(
      title: title,
      description: description,
      points: points,
      dueDate: dueDate,
      tags: tags,
    );
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    final firstTask = Task(
      id: const TaskId('new'), // placeholder — repository assigns the real id
      title: title.trim(),
      description: description?.trim() ?? '',
      status: assignedToId != null ? TaskStatus.assigned : TaskStatus.available,
      difficulty: difficulty,
      dueDate: dueDate,
      assignedToId: assignedToId,
      createdById: createdById,
      createdAt: DateTime.now(),
      completedAt: null,
      points: Points(points),
      tags: tags,
      recurringPattern: null,
      lastCompletedAt: null,
      familyId: familyId,
      requiresPhotoProof: requiresPhotoProof,
      ruleId: null,
    );

    final rule = RecurringRule(
      id: 'new', // placeholder — repository assigns the real id
      familyId: familyId,
      rrule: rrule,
      title: title.trim(),
      description: description?.trim() ?? '',
      difficulty: difficulty,
      points: Points(points),
      tags: tags,
      requiresPhotoProof: requiresPhotoProof,
      assignedToId: assignedToId,
      createdBy: createdById,
      nextDueAt: dueDate,
      lastTaskId: null,
    );

    try {
      final created = await _taskRepository.createRecurringChore(
        firstTask: firstTask,
        rule: rule,
      );
      return Right(created);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to create recurring chore: $e'));
    }
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/domain/usecases/task/create_recurring_chore_usecase_test.dart` and `flutter test test/domain/usecases/task/` (CreateTaskUseCase must be unaffected by the validator extraction).

- [ ] **Step 6: Commit**

```bash
git add lib/domain/services/task_validation.dart \
  lib/domain/usecases/task/create_task_usecase.dart \
  lib/domain/usecases/task/create_recurring_chore_usecase.dart \
  test/domain/usecases/task/create_recurring_chore_usecase_test.dart
git commit -m "feat(chores): add CreateRecurringChoreUseCase with shared validation

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 5: Notifier — `repeat` param routing + DI provider

**Files:**
- Modify: `lib/presentation/providers/riverpod/task_creation_notifier.dart`
- Modify: `lib/di/riverpod_container.dart`
- Modify: `lib/di/riverpod_container.g.dart` (regenerated)
- Test: `test/presentation/providers/riverpod/task_creation_notifier_test.dart` (new)

**Interfaces:**
- Consumes: `createRecurringChoreUseCaseProvider`, `rruleForRepeat`, `RepeatPreset`.
- Produces: `TaskCreationNotifier.createTask({..., RepeatPreset repeat = RepeatPreset.never})` — non-`never` routes to the recurring use case with `rrule = rruleForRepeat(repeat, dueDate!)`.

- [ ] **Step 1: Write the failing test**

`test/presentation/providers/riverpod/task_creation_notifier_test.dart` — model it on how the existing notifier is tested (search for `taskCreationNotifierProvider` tests; if none exist, use `ProviderContainer` with overrides):

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/usecases/task/create_recurring_chore_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/task/create_task_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_creation_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _FakeCreateTaskUseCase extends Fake implements CreateTaskUseCase {
  // no-op for the recurring path
}

class _FakeCreateRecurringChoreUseCase extends Fake
    implements CreateRecurringChoreUseCase {
  @override
  Future<Either<Failure, Task>> call({
    required String title,
    String? description,
    required int points,
    required TaskDifficulty difficulty,
    required DateTime dueDate,
    required FamilyId familyId,
    required UserId createdById,
    UserId? assignedToId,
    List<String> tags = const [],
    bool requiresPhotoProof = false,
    required String rrule,
  }) async {
    capturedRrule = rrule;
    return Right(Task(
      id: const TaskId('task-1'),
      title: title,
      description: description ?? '',
      status: TaskStatus.available,
      difficulty: difficulty,
      dueDate: dueDate,
      assignedToId: assignedToId,
      createdById: createdById,
      createdAt: DateTime(2026, 8, 14),
      completedAt: null,
      points: Points(points),
      tags: tags,
      recurringPattern: null,
      lastCompletedAt: null,
      familyId: familyId,
      requiresPhotoProof: requiresPhotoProof,
      ruleId: 'rule-1',
    ));
  }
}

String? capturedRrule;

void main() {
  test('repeat != never routes to the recurring use case with derived rrule',
      () async {
    capturedRrule = null;
    final container = ProviderContainer(overrides: [
      createTaskUseCaseProvider.overrideWithValue(_FakeCreateTaskUseCase()),
      createRecurringChoreUseCaseProvider
          .overrideWithValue(_FakeCreateRecurringChoreUseCase()),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(taskCreationNotifierProvider.notifier);
    await notifier.createTask(
      title: 'Clean the bathroom',
      description: '',
      difficulty: TaskDifficulty.medium,
      familyId: const FamilyId('fam-1'),
      creatorId: const UserId('parent-1'),
      dueDate: DateTime(2026, 8, 15), // Saturday
      repeat: RepeatPreset.weekly,
    );

    expect(capturedRrule, 'FREQ=WEEKLY;BYDAY=SA');
    expect(container.read(taskCreationNotifierProvider).isSuccess, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/providers/riverpod/task_creation_notifier_test.dart`
Expected: FAIL — `RepeatPreset`/`repeat` param/`createRecurringChoreUseCaseProvider` don't exist.

- [ ] **Step 3: Add the DI provider**

`lib/di/riverpod_container.dart` (next to `createTaskUseCaseProvider`):

```dart
CreateRecurringChoreUseCase createRecurringChoreUseCase(Ref ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return CreateRecurringChoreUseCase(taskRepository);
}
```

Regenerate: `dart run build_runner build --delete-conflicting-outputs` (updates `riverpod_container.g.dart`).

- [ ] **Step 4: Add the `repeat` param to the notifier**

`lib/presentation/providers/riverpod/task_creation_notifier.dart` — import `../widgets/` no; import `../../domain/services/recurrence.dart` and `../../domain/usecases/task/create_recurring_chore_usecase.dart`. Add to the signature:

```dart
    bool requiresPhotoProof = false,
    RepeatPreset repeat = RepeatPreset.never,
```

and, before the existing `createTaskUseCase.call(...)` path:

```dart
      if (repeat != RepeatPreset.never) {
        final rrule = rruleForRepeat(repeat, dueDate ?? DateTime.now().add(const Duration(days: 1)));
        if (rrule == null) {
          state = state.copyWith(
            isLoading: false,
            error: 'Unknown repeat pattern',
          );
          return;
        }
        _logger.i('Creating recurring task for family ${familyId.value} '
            'with rrule $rrule');
        final createRecurringChoreUseCase = ref.read(createRecurringChoreUseCaseProvider);
        final result = await createRecurringChoreUseCase.call(
          title: title,
          description: description,
          points: points,
          difficulty: difficulty,
          dueDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
          familyId: familyId,
          createdById: creatorId,
          assignedToId: assignedTo?.id,
          tags: const [],
          requiresPhotoProof: requiresPhotoProof,
          rrule: rrule,
        );
        result.fold(
          (failure) {
            _logger.e('Recurring task creation failed: ${failure.message}');
            state = state.copyWith(isLoading: false, error: failure.message);
          },
          (task) {
            _logger.i('Recurring task created: ${task.id.value}');
            state = state.copyWith(isLoading: false, isSuccess: true);
          },
        );
        return;
      }
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/presentation/providers/riverpod/task_creation_notifier_test.dart`
Expected: PASS. Then `flutter analyze` (the `.g.dart` regeneration must be clean).

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/providers/riverpod/task_creation_notifier.dart \
  lib/di/riverpod_container.dart lib/di/riverpod_container.g.dart \
  test/presentation/providers/riverpod/task_creation_notifier_test.dart
git commit -m "feat(chores): route Repeat selection to the recurring use case

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 6: Engine — `recurringEngine.js` + scheduled function + emulator test

**Files:**
- Create: `functions/recurringEngine.js`
- Modify: `functions/index.js`
- Modify: `functions/package.json`
- Test: `test/rules/recurring_engine.test.mjs` (new)

**Interfaces:**
- Produces: `async processRule(db, ruleRef, now)` → `{ spawned: boolean, reason?: string, taskId?: string }`; `async spawnDueOccurrences(db, { now = new Date() })` → `{ processed, spawned, skipped }`. `db` is a Firestore instance (admin or emulator). `now` is a JS `Date`.

- [ ] **Step 1: Add the dependency and test script**

In `functions/`: `npm install rrule` (adds to `package.json` + `package-lock.json`).

In `functions/package.json` scripts:

```json
"test:recurring": "firebase emulators:exec --only firestore --project demo-hoque \"node ../test/rules/recurring_engine.test.mjs\"",
```

- [ ] **Step 2: Write the failing engine test**

`test/rules/recurring_engine.test.mjs` — mirror the seeding/teardown shape of `test/rules/functions_economy.test.mjs`:

```js
// Engine integration test: drives functions/recurringEngine.js against the
// Firestore emulator. onSchedule cannot be invoked via httpsCallable, so the
// engine is a standalone module that takes db — this test imports it directly.
import adminPkg from 'firebase-admin';
import assert from 'node:assert/strict';

const PROJECT = 'demo-hoque';
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';

const admin = adminPkg.initializeApp({ projectId: PROJECT }, 'engine-test');
const db = adminPkg.firestore();
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
```

Wait — the file uses `describe`/`beforeEach`/`after` — check whether the existing `test/rules/*.mjs` files import a test runner (mocha via `firebase emulators:exec --only firestore --project demo-hoque "mocha ..."`). Mirror whatever `functions_economy.test.mjs` uses (likely `import { describe, it, beforeEach, after } from 'node:test'` or mocha globals). Adjust the runner line in `package.json` accordingly.

Continue the test body:

```js
  it('spawns when due and the gate is open', async () => {
    await seedRule(db, 'fam-1', 'rule-1', { rrule: 'FREQ=WEEKLY;BYDAY=SA', nextDueAt: midnight(2026, 8, 14) });

    const res = await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 12, 0, 0) });

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
    // nextDueAt advanced to the next Saturday: 2026-08-21.
    assert.equal(r.nextDueAt.toDate().getTime(), new Date(2026, 7, 21).getTime());
  });

  it('holds when the slot is occupied (needsRevision included)', async () => {
    await seedRule(db, 'fam-1', 'rule-1', {
      rrule: 'FREQ=WEEKLY;BYDAY=SA', nextDueAt: midnight(2026, 8, 14), lastTaskId: 'task-1',
    });
    await seedTask(db, 'fam-1', 'task-1', 'needsRevision');

    const res = await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 12, 0, 0) });

    assert.deepEqual(res, { processed: 0, spawned: 0, skipped: 1 });
    assert.equal((await tasks(db, 'fam-1')).length, 1);
    const r = await rule(db, 'fam-1', 'rule-1');
    assert.equal(r.nextDueAt.toDate().getTime(), new Date(2026, 7, 14).getTime()); // unchanged
  });

  it('spawns when the previous task doc is missing', async () => {
    await seedRule(db, 'fam-1', 'rule-1', {
      rrule: 'FREQ=WEEKLY;BYDAY=SA', nextDueAt: midnight(2026, 8, 14), lastTaskId: 'task-9',
    });

    const res = await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 12, 0, 0) });

    assert.equal(res.spawned, 1);
    assert.equal((await tasks(db, 'fam-1')).length, 1);
  });

  it('is idempotent across concurrent ticks', async () => {
    await seedRule(db, 'fam-1', 'rule-1', { rrule: 'FREQ=WEEKLY;BYDAY=SA', nextDueAt: midnight(2026, 8, 14) });

    await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 12, 0, 0) });
    const second = await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 12, 5, 0) });

    assert.equal(second.spawned, 0);
    assert.equal((await tasks(db, 'fam-1')).length, 1);
  });

  it('skips a due-but-disabled rule', async () => {
    await seedRule(db, 'fam-1', 'rule-1', { rrule: 'FREQ=WEEKLY;BYDAY=SA', nextDueAt: midnight(2026, 8, 14), enabled: false });

    const res = await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 12, 0, 0) });

    assert.equal(res.spawned, 0);
    assert.equal((await tasks(db, 'fam-1')).length, 0);
  });

  it('a per-rule error does not abort sibling rules', async () => {
    await seedRule(db, 'fam-1', 'rule-bad', {
      rrule: 'NOT-A-RRULE;;', nextDueAt: midnight(2026, 8, 14),
    });
    await seedRule(db, 'fam-1', 'rule-ok', { rrule: 'FREQ=DAILY', nextDueAt: midnight(2026, 8, 14) });

    const res = await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 12, 0, 0) });

    // The bad rule must not be spawned again; the good one still fires.
    const rBad = await rule(db, 'fam-1', 'rule-bad');
    assert.equal(rBad.enabled, false); // engine disables a malformed rule and logs
    assert.equal((await tasks(db, 'fam-1')).length, 1);
    assert.equal((await tasks(db, 'fam-1'))[0].ruleId, 'rule-ok');
  });

  it('catch-up: a late completion spawns "due today", then settles to the RRULE', async () => {
    // Chore due 2026-08-08 was completed late, on 2026-08-13. Tick on 2026-08-14.
    await seedRule(db, 'fam-1', 'rule-1', {
      rrule: 'FREQ=WEEKLY;BYDAY=SA', nextDueAt: midnight(2026, 8, 8), lastTaskId: 'task-1',
    });
    await seedTask(db, 'fam-1', 'task-1', 'completed');

    await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 9, 0, 0) });
    const first = (await tasks(db, 'fam-1')).find((t) => t.id !== 'task-1');
    assert.equal(first.dueDate.toDate().getTime(), new Date(2026, 7, 14).getTime()); // due today

    await db.doc(`families/fam-1/tasks/${first.id}`).update({ status: 'completed' });
    const settle = await spawnDueOccurrences(db, { now: new Date(2026, 7, 14, 9, 30, 0) });
    assert.equal(settle.spawned, 1);
    const r = await rule(db, 'fam-1', 'rule-1');
    assert.equal(r.nextDueAt.toDate().getTime(), new Date(2026, 7, 21).getTime()); // cadence restored
  });
});
```

Note: the "per-rule error" test asserts the engine **disables a malformed rule** rather than skipping it — a bad RRULE that is merely skipped would loop forever re-spawning every tick. Make the engine do that (Step 3 below implements it). If you'd rather keep the engine simpler (skip + log), change the assertion to `res.spawned === 1` with `rule-ok` only — but the disable is the correct MVP behaviour.

- [ ] **Step 3: Run test to verify it fails**

Run: `cd functions && npm run test:recurring`
Expected: FAIL — `recurringEngine.js` doesn't exist / module not found.

- [ ] **Step 4: Write the engine**

`functions/recurringEngine.js`:

```js
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

/// Spawn one due occurrence for [ruleRef], inside a transaction on the rule.
/// Returns { spawned, reason?, taskId? }.
async function processRule(db, ruleRef, now) {
  const nowTs = Timestamp.fromDate(now);
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

    const template = rule.template || {};
    const assigned = rule.assignment && rule.assignment.userId
      ? rule.assignment.userId
      : null;

    const taskRef = db.collection(`families/${familyId}/tasks`).doc();
    tx.set(taskRef, {
      title: template.title,
      description: template.description || '',
      status: assigned ? 'assigned' : 'available',
      difficulty: template.difficulty || 'easy',
      // Never back-date a spawned chore: a late catch-up lands "due today".
      dueDate: nextDueAt > now ? Timestamp.fromDate(nextDueAt) : nowTs,
      assignedToId: assigned,
      createdById: rule.createdBy || '',
      createdAt: nowTs,
      points: Number(template.points) || 0,
      tags: template.tags || [],
      requiresPhotoProof: !!template.requiresPhotoProof,
      ruleId: ruleRef.id,
      version: 0,
    });

    let next;
    try {
      const rrule = new RRule({
        ...RRule.parseString(rule.trigger && rule.trigger.rrule),
        dtstart: nextDueAt,
      });
      next = rrule.after(nextDueAt);
    } catch (e) {
      // A malformed RRULE must not loop (every tick would re-spawn and
      // duplicate). Disable the series and fail loudly instead.
      console.error(
        `[recurring] Bad RRULE on ${ruleRef.id}: ${
          rule.trigger && rule.trigger.rrule
        }`, e.message,
      );
      tx.update(ruleRef, { enabled: false, lastFiredAt: nowTs });
      return { spawned: true, taskId: taskRef.id, reason: 'disabled-bad-rrule' };
    }
    if (!next) {
      // No further occurrences — end the series cleanly.
      tx.update(ruleRef, {
        enabled: false, nextDueAt: null,
        lastTaskId: taskRef.id, lastFiredAt: nowTs,
      });
      return { spawned: true, taskId: taskRef.id, reason: 'series-ended' };
    }

    tx.update(ruleRef, {
      nextDueAt: Timestamp.fromDate(next),
      lastTaskId: taskRef.id,
      lastFiredAt: nowTs,
    });
    return { spawned: true, taskId: taskRef.id };
  });
}

/// Scan all enabled rules and spawn every due occurrence.
/// Returns { processed, spawned, skipped } for observability.
async function spawnDueOccurrences(db, { now = new Date() } = {}) {
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
      const result = await processRule(db, doc.ref, now);
      processed += 1;
      if (result.spawned) spawned += 1;
    } catch (e) {
      // Fail loudly per rule, resilient as a batch: one bad rule must not
      // starve the rest. Firestore's transaction retry handles concurrent
      // ticks.
      console.error(`[recurring] Rule ${doc.id} failed:`, e.message);
    }
  }
  return { processed, spawned, skipped: rulesSnap.docs.length - processed };
}

module.exports = { processRule, spawnDueOccurrences };
```

- [ ] **Step 5: Wire the scheduled function**

In `functions/index.js`:

```js
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { spawnDueOccurrences } = require('./recurringEngine');

// First scheduled function. Every 15 min at :07/:22/:37/:52 — off the
// :00/:15 crowd so the tick never lands on the same instant as other jobs.
exports.spawnRecurringTasks = onSchedule('7,22,37,52 * * * *', async (event) => {
  const result = await spawnDueOccurrences(db, { now: new Date() });
  console.log(
    `[recurring] tick: ${result.spawned} spawned, ${result.processed} processed, ${result.skipped} skipped`,
  );
});
```

Check how `db` is already initialized in `index.js` and reuse it.

- [ ] **Step 6: Run the test to verify it passes**

Run: `cd functions && npm run test:recurring`
Expected: PASS (all 7 engine tests).

- [ ] **Step 7: Commit**

```bash
git add functions/recurringEngine.js functions/index.js functions/package.json \
  functions/package-lock.json test/rules/recurring_engine.test.mjs
git commit -m "feat(functions): spawn recurring chores on a 15-minute tick

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 7: Firestore rules — `taskRules` block + rules tests

**Files:**
- Modify: `firestore.rules`
- Test: `test/rules/task_rules.test.mjs` (new)
- Modify: `test/rules/package.json` (if scripts live there; else functions scripts)

**Interfaces:**
- Produces: `taskRules` readable by any family member; create only by parents/guardians with `createdBy == request.auth.uid`; delete only by parents/guardians; update always `false`. Engine writes via admin SDK (rules don't apply).

- [ ] **Step 1: Write the failing rules test**

`test/rules/task_rules.test.mjs` — mirror `test/rules/role_lock.test.mjs` (initialise test environment, seed family + users, `assertSucceeds`/`assertFails`):

```js
// taskRules collection: parents/guardians may create and delete, all family
// members may read, nobody may update. A child forging createdBy must fail.
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(join(__dirname, '..', '..', 'firestore.rules'), 'utf8');

// Match the project id / setup of the existing role_lock.test.mjs.
const PROJECT_ID = 'demo-hoque';
const testEnv = await initializeTestEnvironment({ projectId: PROJECT_ID, firestore: { rules } });

const parentUid = 'parent-1';
const childUid = 'kid-1';
const otherUid = 'outsider-1';

async function seed() {
  const admin = testEnv.unauthenticatedContext();
  await admin.firestore().doc('families/fam-1').set({ name: 'Hoque', memberIds: [parentUid, childUid] });
  await admin.firestore().doc(`users/${parentUid}`).set({ displayName: 'Parent', role: 'parent', familyId: 'fam-1' });
  await admin.firestore().doc(`users/${childUid}`).set({ displayName: 'Kid', role: 'child', familyId: 'fam-1' });
  await admin.firestore().doc(`users/${otherUid}`).set({ displayName: 'Outsider', role: 'parent', familyId: 'fam-2' });
}

function ruleDoc() {
  return {
    trigger: { type: 'schedule', rrule: 'FREQ=WEEKLY;BYDAY=SA' },
    template: { title: 'Clean the bathroom', description: '', difficulty: 'medium', points: 25, tags: [], requiresPhotoProof: false },
    enabled: true,
    nextDueAt: new Date('2026-08-15T00:00:00Z'),
    lastTaskId: 'task-1',
    createdBy: parentUid,
    createdAt: new Date(),
  };
}

before(async () => {
  await testEnv.clearFirestore();
  await seed();
});

after(async () => {
  await testEnv.cleanup();
});

it('parent can create a taskRule carrying their own uid', async () => {
  const ctx = testEnv.authenticatedContext(parentUid, { uid: parentUid });
  await assertSucceeds(ctx.firestore().doc('families/fam-1/taskRules/rule-1').set(ruleDoc()));
});

it('parent cannot create a taskRule with a forged createdBy', async () => {
  const ctx = testEnv.authenticatedContext(parentUid, { uid: parentUid });
  const forged = { ...ruleDoc(), createdBy: 'someone-else' };
  await assertFails(ctx.firestore().doc('families/fam-1/taskRules/rule-forged').set(forged));
});

it('child cannot create a taskRule', async () => {
  const ctx = testEnv.authenticatedContext(childUid, { uid: childUid });
  await assertFails(ctx.firestore().doc('families/fam-1/taskRules/rule-2').set(ruleDoc()));
});

it('any family member can read a taskRule; an outsider cannot', async () => {
  const parentCtx = testEnv.authenticatedContext(parentUid, { uid: parentUid });
  await assertSucceeds(parentCtx.firestore().doc('families/fam-1/taskRules/rule-1').get());

  const childCtx = testEnv.authenticatedContext(childUid, { uid: childUid });
  await assertSucceeds(childCtx.firestore().doc('families/fam-1/taskRules/rule-1').get());

  const outsiderCtx = testEnv.authenticatedContext(otherUid, { uid: otherUid });
  await assertFails(outsiderCtx.firestore().doc('families/fam-1/taskRules/rule-1').get());
});

it('parent can delete a taskRule; a child cannot; nobody updates', async () => {
  const parentCtx = testEnv.authenticatedContext(parentUid, { uid: parentUid });
  await assertSucceeds(parentCtx.firestore().doc('families/fam-1/taskRules/rule-1').delete());

  const childCtx = testEnv.authenticatedContext(childUid, { uid: childUid });
  await assertFails(childCtx.firestore().doc('families/fam-1/taskRules/rule-3').delete());

  const update = { ...ruleDoc(), enabled: false };
  await assertFails(parentCtx.firestore().doc('families/fam-1/taskRules/rule-1').update(update));
});
```

Match the exact seed helper names (`isFamilyMember` reads `families/{familyId}.memberIds` — check `firestore.rules` for how membership is stored) and the test-runner conventions of `role_lock.test.mjs` (mocha globals vs `node:test`).

- [ ] **Step 2: Run test to verify it fails**

Run the same way the existing rules tests run (see `test/rules/` npm scripts — e.g. `firebase emulators:exec --only firestore --project demo-hoque "mocha task_rules.test.mjs"`).
Expected: FAIL — no `match /taskRules` block, so reads/writes are denied.

- [ ] **Step 3: Add the rules block**

In `firestore.rules`, after the existing tasks match block:

```
    match /taskRules/{ruleId} {
      allow read: if isFamilyMember(familyId);
      allow create: if isFamilyMember(familyId)
        && me().role in ['parent', 'guardian']
        && request.resource.data.createdBy == request.auth.uid;
      allow delete: if isFamilyMember(familyId)
        && me().role in ['parent', 'guardian'];
      allow update: if false;
    }
```

Check the exact helper names in this file (`isFamilyMember`, `me()`, the role list pattern used for user updates) and match them.

- [ ] **Step 4: Run test to verify it passes**

Run the rules suite again. Expected: PASS. Also run the existing rules tests to confirm no regression.

- [ ] **Step 5: Commit**

```bash
git add firestore.rules test/rules/task_rules.test.mjs
git commit -m "feat(rules): gate taskRules to parents for create/delete

Widening change (new collection) — ships ahead of the client build per the
standing deploy-ordering rule.

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 8: Client — Repeat selector on add-task

**Files:**
- Create: `lib/presentation/widgets/repeat_selector.dart`
- Modify: `lib/presentation/screens/add_task_screen.dart`
- Test: `test/presentation/widgets/repeat_selector_test.dart` (new)

**Interfaces:**
- Consumes: `RepeatPreset`, `rruleForRepeat` not needed here (the notifier derives the RRULE).
- Produces: `RepeatSelector({required RepeatPreset value, required ValueChanged<RepeatPreset> onChanged, required bool visible})` — a dropdown row (Never / Daily / Weekly / Monthly); `visible: false` renders nothing (children never see it). `add_task_screen` holds `RepeatPreset _repeat = RepeatPreset.never`, embeds the selector when the viewer is a parent, and passes `repeat: _repeat` to `createTask`.

- [ ] **Step 1: Write the failing widget test**

`test/presentation/widgets/repeat_selector_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/services/recurrence.dart';
import 'package:hoque_family_chores/presentation/widgets/repeat_selector.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows the four presets and reports selection', (tester) async {
    RepeatPreset? chosen;
    await tester.pumpWidget(wrap(RepeatSelector(
      value: RepeatPreset.never,
      visible: true,
      onChanged: (p) => chosen = p,
    )));

    expect(find.text('Repeat'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<RepeatPreset>));
    await tester.pumpAndSettle();

    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);

    await tester.tap(find.text('Weekly').last);
    await tester.pumpAndSettle();

    expect(chosen, RepeatPreset.weekly);
  });

  testWidgets('renders nothing when hidden (children)', (tester) async {
    await tester.pumpWidget(wrap(RepeatSelector(
      value: RepeatPreset.never,
      visible: false,
      onChanged: (_) {},
    )));

    expect(find.text('Repeat'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/widgets/repeat_selector_test.dart`
Expected: FAIL — widget doesn't exist.

- [ ] **Step 3: Write the widget**

`lib/presentation/widgets/repeat_selector.dart`:

```dart
import 'package:flutter/material.dart';
import '../domain/services/recurrence.dart';

/// The "Repeat" row on the add-task screen — Never / Daily / Weekly / Monthly.
/// Shown to parents only ([visible]); children never see it.
class RepeatSelector extends StatelessWidget {
  final RepeatPreset value;
  final ValueChanged<RepeatPreset> onChanged;
  final bool visible;

  const RepeatSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.visible,
  });

  static const Map<RepeatPreset, String> _labels = {
    RepeatPreset.never: 'Never',
    RepeatPreset.daily: 'Daily',
    RepeatPreset.weekly: 'Weekly',
    RepeatPreset.monthly: 'Monthly',
  };

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    // Match the row style of the date picker on this screen.
    return ListTile(
      leading: const Icon(Icons.repeat),
      title: const Text('Repeat'),
      trailing: DropdownButton<RepeatPreset>(
        value: value,
        underline: const SizedBox.shrink(),
        items: [
          for (final preset in RepeatPreset.values)
            DropdownMenuItem(
              value: preset,
              child: Text(_labels[preset]!),
            ),
        ],
        onChanged: (p) {
          if (p != null) onChanged(p);
        },
      ),
    );
  }
}
```

Check the actual import style used in this app (`package:hoque_family_chores/...` for all lib imports) and the widget conventions of `add_task_screen.dart` — a plain `ListTile` may not match; adapt to the screen's row idiom while keeping the `DropdownButton<RepeatPreset>` contract the test relies on.

- [ ] **Step 4: Embed it in add-task and pass `repeat` on submit**

In `lib/presentation/screens/add_task_screen.dart`:

```dart
import '../../domain/services/recurrence.dart' show RepeatPreset;
import '../widgets/repeat_selector.dart';
```

State field (near `_selectedAssignee`):

```dart
  RepeatPreset _repeat = RepeatPreset.never;
```

In the build (where the other task rows are, guarded by parent check — the screen already knows `currentUser`):

```dart
    RepeatSelector(
      visible: currentUser?.role == UserRole.parent ||
          currentUser?.role == UserRole.guardian,
      value: _repeat,
      onChanged: (p) => setState(() => _repeat = p),
    ),
```

In `_submitTask`, pass through (only when not editing — the screen already has an `_isEditing` branch; a recurring rule is never edited):

```dart
      repeat: _isEditing ? RepeatPreset.never : _repeat,
```

- [ ] **Step 5: Run the tests**

Run: `flutter test test/presentation/widgets/repeat_selector_test.dart` — PASS. Then `flutter analyze` and the add-task screen's existing tests if any (`grep -rl add_task test/`).

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/widgets/repeat_selector.dart \
  lib/presentation/screens/add_task_screen.dart \
  test/presentation/widgets/repeat_selector_test.dart
git commit -m "feat(chores): add Repeat selector to the add-task screen

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 9: Client — Recurring badge + "Stop repeating"

**Files:**
- Create: `lib/presentation/widgets/stop_repeating_button.dart`
- Modify: `lib/presentation/screens/task_details_screen.dart`
- Test: `test/presentation/widgets/stop_repeating_button_test.dart` (new)

**Interfaces:**
- Consumes: `canStopRepeating`, `Task.ruleId`, `TaskRepository.deleteRecurringRule` (via the screen's existing repository/provider wiring).
- Produces: `StopRepeatingButton({required Future<void> Function() onStop})` — an outlined button with a confirm dialog; on confirm calls `onStop`; shows a snackbar on success and on failure. Task details shows a "Recurring" badge and the button when `canStopRepeating(viewerRole, task.ruleId)` is true; hiding the affordance after a successful stop is the screen's job.

- [ ] **Step 1: Write the failing widget test**

`test/presentation/widgets/stop_repeating_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/presentation/widgets/stop_repeating_button.dart';

void main() {
  testWidgets('confirms before calling onStop', (tester) async {
    var stopped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StopRepeatingButton(
          onStop: () async {
            stopped = true;
          },
        ),
      ),
    ));

    await tester.tap(find.text('Stop repeating'));
    await tester.pumpAndSettle();
    // The confirm dialog is asking, not yet acting.
    expect(stopped, isFalse);
    expect(find.text('Stop this recurring chore?'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();

    expect(stopped, isTrue);
    expect(find.text('Recurring series stopped'), findsOneWidget);
  });

  testWidgets('cancelling the dialog does nothing', (tester) async {
    var stopped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StopRepeatingButton(
          onStop: () async {
            stopped = true;
          },
        ),
      ),
    ));

    await tester.tap(find.text('Stop repeating'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(stopped, isFalse);
  });

  testWidgets('a failing onStop shows the error and no success snackbar',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StopRepeatingButton(
          onStop: () async => throw Exception('boom'),
        ),
      ),
    ));

    await tester.tap(find.text('Stop repeating'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();

    expect(find.text('Recurring series stopped'), findsNothing);
    expect(find.textContaining('Could not stop'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/widgets/stop_repeating_button_test.dart`
Expected: FAIL — widget doesn't exist.

- [ ] **Step 3: Write the widget**

`lib/presentation/widgets/stop_repeating_button.dart`:

```dart
import 'package:flutter/material.dart';

/// The only way to turn a recurring series off (rule editing is future work).
/// A confirm dialog guards the delete because it is irreversible — the rule
/// doc is gone, though existing occurrences stay as ordinary tasks.
class StopRepeatingButton extends StatelessWidget {
  final Future<void> Function() onStop;

  const StopRepeatingButton({super.key, required this.onStop});

  Future<void> _confirm(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop this recurring chore?'),
        content: const Text(
            'New occurrences will stop. Existing ones stay on the list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await onStop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Recurring series stopped')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not stop repeating — try again')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirm(context),
      icon: const Icon(Icons.repeat_off),
      label: const Text('Stop repeating'),
    );
  }
}
```

- [ ] **Step 4: Wire it into task details**

In `lib/presentation/screens/task_details_screen.dart`:

- Import `../../domain/services/recurrence.dart` (for `canStopRepeating`) and `../widgets/stop_repeating_button.dart`.
- Add a `bool _seriesStopped = false;` local field.
- In the build, after the existing action area, when the task carries a ruleId and the viewer may manage it:

```dart
    if (!_seriesStopped && canStopRepeating(viewerRole, task.ruleId)) ...[
      const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.repeat, size: 16),
            SizedBox(width: 4),
            Text('Recurring'),
          ],
        ),
      ),
      StopRepeatingButton(
        onStop: () async {
          await ref.read(taskRepositoryProvider).deleteRecurringRule(
                task.familyId,
                task.ruleId!,
              );
          setState(() => _seriesStopped = true);
        },
      ),
    ],
```

If the screen reads `taskRepository` through a different provider (`repositoryFactoryProvider` per `riverpod_container.dart`), use that. When the rule is already deleted server-side, `deleteRecurringRule` is a no-op success — same user outcome, simpler than an existence check.

- [ ] **Step 5: Run the tests**

Run: `flutter test test/presentation/widgets/stop_repeating_button_test.dart` — PASS. Then `flutter analyze` and the task-details screen tests if any.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/widgets/stop_repeating_button.dart \
  lib/presentation/screens/task_details_screen.dart \
  test/presentation/widgets/stop_repeating_button_test.dart
git commit -m "feat(chores): add Recurring badge and Stop repeating action

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage check** (against `docs/superpowers/specs/2026-08-14-recurring-chores-design.md`):

- Data model `families/{familyId}/taskRules/{ruleId}` (trigger/template/assignment/enabled/nextDueAt/lastTaskId/lastFiredAt/createdBy/createdAt) → Task 3 `_mapRuleToFirestore` + Task 6 engine. ✓
- Task `ruleId` field + existing client parsing unchanged → Task 2. ✓
- RRULE division of labour — presets table, no Dart dependency, `rrule` server-only → Tasks 1, 6. ✓
- Engine: scan → re-read + gate → spawn → advance → notify (no new notify) → Tasks 6. ✓
- `*/15` tick → `7,22,37,52 * * * *` (open question resolved) → Task 6. ✓
- Gate statuses incl. `needsRevision`; missing doc counts resolved → Task 6 (OCCUPIED set + missing-doc branch) + engine test. ✓
- Due date = `max(nextDueAt, today)` (start of day) → Task 6 (`dueDate` branch) + catch-up test. ✓
- Catch-up behaviour → Task 6 catch-up test. ✓
- One timezone simplification → Global Constraints. ✓
- Repeat selector parents-only → Task 8 (visible flag) + widget test. ✓
- Batch write (task + rule atomic, nextDueAt = due date, lastTaskId = task id) → Task 3. ✓
- Recurring badge + Stop repeating (idempotent delete, affordance hidden when rule gone) → Task 9 (`deleteRecurringRule` no-op; `_seriesStopped` hides after success; a missing rule still deletes cleanly — the affordance-hiding-on-missing-rule refinement is subsumed by idempotent delete). ✓
- Preset → RRULE helper unit-tested incl. month-end → Task 1. ✓
- Firestore rules block + tests (parent create/delete, child cannot, all read) → Task 7. ✓
- Error handling: per-rule try/catch, defensive template guards, client validation reuse → Tasks 4, 6. ✓
- Deployment ordering (rules ahead of client) → Task 7 commit message + Global Constraints. ✓
- Engine tests from spec's testing section: spawns/holds-per-status/missing-doc/advances-exact-date/idempotent/per-rule-error/catch-up → Task 6 covers each (one test per occupying status collapsed into the `needsRevision` representative + OCCUPIED set; acceptable — the set literal is the single source of truth, one integration test proves the branch). ✓

**Placeholder scan:** No TBD/TODO. The two "check the existing test/pattern and adapt" notes (PhotoStorage stub, rules test runner) name the exact files to read and what to preserve — deliberate because the plan must not invent a stub interface that differs from the repo's real one.

**Type consistency:**
- `RepeatPreset` (never/daily/weekly/monthly) used identically in Tasks 1, 5, 8. ✓
- `rruleForRepeat(RepeatPreset, DateTime) → String?` — Task 1 defines, Task 5 consumes. ✓
- `canStopRepeating(UserRole, String?) → bool` — Task 1 defines, Task 9 consumes. ✓
- `RecurringRule` fields — Task 1 defines, Task 3 maps, Task 4 builds. `copyWith` covers every field. ✓
- `createRecurringChore({required Task firstTask, required RecurringRule rule}) → Future<Task>` — Tasks 3/4. ✓
- `deleteRecurringRule(FamilyId, String) → Future<void>` — Tasks 3/9. ✓
- `validateTaskInput(...) → ValidationFailure?` — Task 4 defines + refactors CreateTaskUseCase. ✓
- `spawnDueOccurrences(db, {now}) → {processed, spawned, skipped}` / `processRule(db, ruleRef, now)` — Task 6. ✓
- `RepeatSelector({value, onChanged, visible})` — Task 8. `StopRepeatingButton({onStop})` — Task 9. ✓
- Task entity `ruleId` — added in Task 2, used by Tasks 3, 9. ✓
