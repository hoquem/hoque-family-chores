# Agent Briefing — Home Screen Widget

## Task

Add a small iOS/Android home-screen widget for Chores Star. The widget shows
a greeting, the current streak, and up to 3 of today's missions. Tapping it
opens the app on the Home screen.

The widget is a read-only adapter of the existing home-hub data. Use the
`home_widget` Flutter package to bridge data to native widget extensions.
Start with the **small widget only**.

This work is scoped to the spec in
`docs/superpowers/specs/2026-08-04-home-widget-design.md`.

---

## Glossary (excerpt)

| Term | Means | Is NOT |
|------|-------|--------|
| Widget mission | A task due today, shown in the home-screen widget | A push notification |
| Widget entry | The top-level UI object rendered by iOS/Android | A screen inside the app |
| Widget bridge | The Flutter package that pushes data to native widgets | A data source or repository |

---

## Bounded context

- **This task lives in:** Home context.
- **May touch:**
  - `lib/domain/services/home_stats.dart`
  - `lib/domain/entities/task.dart`, `user.dart`
  - `lib/domain/usecases/home/` (new `BuildHomeWidgetDataUseCase`)
  - `lib/presentation/providers/riverpod/` (home hub notifiers)
  - `lib/presentation/screens/home_screen.dart` (trigger updates)
  - `lib/utils/home_widget_bridge.dart` (new wrapper around the package)
  - `ios/` — add HomeWidgetExtension target and SwiftUI widget
  - `android/app/src/main/kotlin/...` — add `AppWidgetProvider` and XML
  - Corresponding tests under `test/`
- **Must NOT reach into:** Reward context, Notification context, or Auth context
  beyond reading the current user identity.

---

## Interface (agreed — do not change without asking)

### Data model

```dart
class HomeWidgetData {
  final String greeting;
  final int currentStreakDays;
  final List<String> missionTitles;
  final int pendingApprovalCount;

  const HomeWidgetData({
    required this.greeting,
    required this.currentStreakDays,
    required this.missionTitles,
    required this.pendingApprovalCount,
  });
}
```

### Use case

```dart
class BuildHomeWidgetDataUseCase {
  HomeWidgetData call({
    required User user,
    required List<Task> todayTasks,
    required int streakDays,
    required int pendingApprovals,
  });
}
```

### Bridge

```dart
class HomeWidgetBridge {
  Future<void> update(HomeWidgetData data);
}
```

### Native widgets

- iOS: `ChoresStarWidget` SwiftUI widget in `ios/HomeWidgetExtension/`.
- Android: `ChoresStarWidget` `AppWidgetProvider`.

---

## Tests to satisfy

### Use case

- `widget data truncates mission list to 3 items`
- `widget data shows streak when non-zero`
- `widget data shows pending approval count when non-zero`
- `widget data falls back to a calm greeting when no missions exist`

### Bridge

- `updateWidget is called after home data changes` (mock the bridge in a
  provider test if possible)

### Native

- iOS widget renders in simulator without crashes.
- Android widget renders on a device without crashes.

---

## Invariants

- The widget reads only data the app already displays locally.
- The widget makes no network calls; the app pushes data to it.
- Mission list is truncated to 3 items.
- Tapping the widget opens the app to the Home screen.
- Widget updates are triggered after task approval, claim, or completion.

---

## Hard rules

1. **Test-first.** No production code without a failing test.
2. **Never weaken/delete/skip a test** to make the suite pass.
3. **Names from the glossary only.** `Widget mission`, `Widget entry`,
   `Widget bridge`.
4. **Interface adherence.** Do not redesign `HomeWidgetData` or
   `BuildHomeWidgetDataUseCase` without approval.
5. **Small green commits.** Each commit is a single verified behavior;
   `flutter analyze` and `flutter test` pass at every commit.
6. **Calm UI.** No animations, countdowns, or progress rings. Use the existing
   token palette.
7. **Start small.** Ship the small widget first; medium/large sizes are out of
   scope for v1.
8. **Done =** green tests + `flutter analyze` clean + native widget renders on
   iOS 18.5 simulator and Android device + deploy script still works (widget
   target included in the upload).

---

## Out of scope

- Interactive buttons on the widget.
- Real-time countdowns or timers.
- Multiple widget sizes in v1.
- Deep-linking to a specific task (tap opens Home).
- Background refresh scheduling beyond a simple 15-minute periodic update.

---

## Notes / links

- Spec: `docs/superpowers/specs/2026-08-04-home-widget-design.md`
- Framework: `ENGINEERING.md`
- Existing home hub: `lib/presentation/screens/home_screen.dart`
- Companion feature briefing: `.claude/briefings/weekly-chore-view.md`
