# Weekly Chore View — Design Spec

> **Status:** Approved for implementation. Follows the DDD+TDD+Deep Modules
> framework. The agent briefing at `.claude/briefings/weekly-chore-view.md`
> must be filled before coding begins.
>
> **Conceived:** 2026-08-04 · **Inventor:** Mahmudul Hoque · **App:** Chores Star

## Vision

Parents want to see the week ahead at a glance. The existing home hub shows
"Today's Missions" but has no weekly plan. Chorly users repeatedly request a
calendar/list view of chores across the week.

A weekly view should feel like a calm family planner, not a busy project
tool. It lives on a dedicated screen reachable from the home hub or task tab.
It shows tasks grouped by day for the current week, lets parents assign or
re-plan chores, and gives children a preview of what's coming.

## 1. Domain-Driven Design

### 1.1 Ubiquitous language (additions)

| Term | Means | Is NOT |
|------|-------|--------|
| Week plan | The set of tasks with due dates in the current calendar week | A schedule that auto-creates tasks |
| Day column | One day in the week plan, showing its assigned/open tasks | A calendar grid cell |
| Unplanned | Tasks with no due date or due outside the current week | Overdue or completed tasks |

### 1.2 Bounded context

- **Task context** — owns the task list, statuses, and due dates.
- The weekly view is a **read-only presentation projection** of the task list.
  It does not own new data.

### 1.3 Aggregate

No new aggregate. The `Task` aggregate root remains authoritative. The weekly
view queries `TaskRepository.streamTasksForFamily(familyId)` and groups by
`dueDate`.

### 1.4 Invariants

- A task appears on the day matching its `dueDate`.
- Tasks without a due date appear in an "Unplanned" bucket.
- Completed tasks are visible but visually muted.
- Dragging a task to a different day updates the task's `dueDate` through the
  existing `editTaskDetails` use case.

---

## 2. Deep Module Architecture

### 2.1 Interface sketch

```dart
/// Projects the family's tasks into a week plan.
class WeeklyPlan {
  final WeekRange week;
  final Map<DateTime, List<Task>> tasksByDay;
  final List<Task> unplanned;

  const WeeklyPlan({
    required this.week,
    required this.tasksByDay,
    required this.unplanned,
  });
}

/// Use case: build a week plan from the task stream.
class BuildWeeklyPlanUseCase {
  Stream<WeeklyPlan> call({required FamilyId familyId, DateTime? anchor});
}
```

**Depth test:** The use case hides grouping, date normalization, and
unplanned bucketing. Presentation only consumes `WeeklyPlan`.

### 2.2 Presentation layer

New screen: `WeeklyPlanScreen`. Reachable via:
- A "Week" icon in the Home app bar, or
- A tab in the Tasks screen's top tab bar.

Initial recommendation: add a subtle **"This week"** link on the home hub below
"Today's Missions" to keep navigation discoverable without adding a new tab.

### 2.3 Widget decomposition

- `WeeklyPlanScreen` — scaffold + horizontal day strip.
- `DayColumn` — one day's tasks.
- `WeekTaskCard` — a smaller, calmer version of `TaskListTile` for the week
  view (no full action row; tap opens detail).
- `UnplannedBucket` — drag target for tasks without a due date.

---

## 3. Test-Driven Development

### 3.1 Tests to satisfy

#### Domain / use case

- `a task with a due date appears in the correct day column`
- `a task without a due date appears in the unplanned bucket`
- `tasks completed are included but marked done`
- `the week range covers the current week starting Monday`

#### Widget

- `week plan screen shows seven day columns`
- `tapping a task opens TaskDetailsScreen`
- `dragging a task to another day calls editTaskDetails with new dueDate`
- `empty days show a calm empty state`

#### Existing behavior

- Characterization tests for `TaskListTile` and home hub remain green; no
  existing screens are broken.

---

## 4. UI/UX design

### 4.1 Calm-UI constraints

- No bright colors per day. Use the existing token palette.
- No badges or star counts on every card — only on the day header.
- The day strip is horizontal and swipeable.
- Each day column scrolls vertically independently.
- Completed tasks are 60% opacity and struck through.

### 4.2 Layout

```
[ Home ] [ This week → ]

This Week
Mon 4  Tue 5  Wed 6  Thu 7  Fri 8  Sat 9  Sun 10
────────────────────────────────────────────────
│ Feed cat     │ Mop kit... │            │
│ (Aisha)      │            │            │
│              │            │            │
────────────────────────────────────────────────
Unplanned
  • Clean windows
  • Organise toys
```

### 4.3 Interactions

- **Tap task card** → open `TaskDetailsScreen`.
- **Long-press + drag** → move to another day or Unplanned.
- **Pull to refresh** → re-fetch task stream.

---

## 5. Out of scope

- Recurring chores / auto-scheduling (TASK-468 territory).
- Calendar month view.
- Drag-and-drop across weeks.
- Time-of-day scheduling.

---

## 6. Incremental delivery

| Increment | Deliverable | Tests |
|---|---|---|
| 1 | `BuildWeeklyPlanUseCase` + `WeeklyPlan` entity | Use-case tests |
| 2 | `WeeklyPlanScreen` with read-only day columns | Widget tests |
| 3 | Tap-to-open task detail | Widget test |
| 4 | Drag to re-schedule via existing `editTaskDetails` | Widget + use-case tests |
| 5 | Home hub "This week" entry point | Widget test |
| 6 | Simulator verification | Manual |

---

## 7. Related docs and memories

- Framework: `ENGINEERING.md`
- Existing task ordering: `docs/superpowers/specs/2026-07-09-auth-redesign-design.md`
- Product philosophy: `[[product-philosophy-trust-based]]`
- Agent briefing: `.claude/briefings/weekly-chore-view.md`
