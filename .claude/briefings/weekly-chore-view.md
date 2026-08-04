# Agent Briefing — Weekly Chore View

## Task

Add a calm weekly chore planner to Chores Star. The view shows the family's
tasks grouped by day for the current week, plus an "Unplanned" bucket for
tasks without a due date. Parents can drag a task to a different day to
reschedule it. Children get a preview of the week ahead.

The feature is read-only with one mutation path: dragging a task updates its
`dueDate` through the existing `editTaskDetails` use case. No new backend
entities are required.

This work is scoped to the spec in
`docs/superpowers/specs/2026-08-04-weekly-chore-view-design.md`.

---

## Glossary (excerpt)

| Term | Means | Is NOT |
|------|-------|--------|
| Week plan | The set of tasks with due dates in the current calendar week | A schedule that auto-creates tasks |
| Day column | One day in the week plan showing its tasks | A calendar grid cell with hourly slots |
| Unplanned | Tasks with no due date or due outside the current week | Overdue or completed tasks |
| Reschedule | Change a task's dueDate | Change its status or assignee |

---

## Bounded context

- **This task lives in:** Task context.
- **May touch:**
  - `lib/domain/entities/task.dart`
  - `lib/domain/usecases/task/` (new `BuildWeeklyPlanUseCase`)
  - `lib/domain/repositories/task_repository.dart` (read-only stream)
  - `lib/presentation/screens/weekly_plan_screen.dart` (create)
  - `lib/presentation/widgets/weekly/` (create)
  - `lib/presentation/screens/home_screen.dart` (add entry link)
  - `lib/presentation/screens/task_list_screen.dart` (optional week tab)
  - Corresponding tests under `test/`
- **Must NOT reach into:** Reward context, Notification context, or Auth context.

---

## Interface (agreed — do not change without asking)

### Entity

```dart
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
```

### Use case

```dart
class BuildWeeklyPlanUseCase {
  Stream<WeeklyPlan> call({required FamilyId familyId, DateTime? anchor});
}
```

### Screen

```dart
class WeeklyPlanScreen extends ConsumerWidget {
  const WeeklyPlanScreen({super.key});
}
```

### Widgets

- `DayColumn` — scrollable column for one day.
- `WeekTaskCard` — smaller read-only task card (tap opens detail).
- `UnplannedBucket` — drag target + list.

---

## Tests to satisfy

### Use case

- `a task with a due date appears in the correct day column`
- `a task without a due date appears in the unplanned bucket`
- `completed tasks are included but marked done`
- `the week range covers the current week starting Monday`

### Widget

- `weekly plan screen shows seven day columns`
- `tapping a task opens TaskDetailsScreen`
- `dragging a task to another day calls editTaskDetails with new dueDate`
- `empty days show a calm empty state`

### Regression

- Existing `TaskListTile` and home hub tests remain green.

---

## Invariants

- A task appears on the day matching its `dueDate`.
- Tasks without a due date appear in the "Unplanned" bucket.
- Completed tasks are visually muted but still visible.
- Dragging a task to a new day updates only `dueDate` through the existing use
  case; status, assignee, and proof photos are untouched.
- The week starts on Monday and shows 7 days.

---

## Hard rules

1. **Test-first.** No production code without a failing test.
2. **Never weaken/delete/skip a test** to make the suite pass.
3. **Names from the glossary only.** `Week plan`, `Day column`, `Unplanned`,
   `Reschedule`.
4. **Interface adherence.** Do not redesign `WeeklyPlan` or
   `BuildWeeklyPlanUseCase` without approval.
5. **Small green commits.** Each commit is a single verified behavior;
   `flutter analyze` and `flutter test` pass at every commit.
6. **Calm UI.** No bright per-day colors, no badges, no leaderboards. Use the
   existing token palette and card style.
7. **Done =** green tests + `flutter analyze` clean + deep-module checklist +
   end-to-end verification on iOS 18.5 simulator.

---

## Out of scope

- Recurring chores / auto-scheduling.
- Calendar month view.
- Drag-and-drop across weeks.
- Time-of-day scheduling.
- Real-time collaborative cursors.

---

## Notes / links

- Spec: `docs/superpowers/specs/2026-08-04-weekly-chore-view-design.md`
- Framework: `ENGINEERING.md`
- Task ordering background: `docs/superpowers/specs/2026-07-09-auth-redesign-design.md`
- Agent briefing for the companion feature (home widget):
  `.claude/briefings/home-screen-widget.md`
