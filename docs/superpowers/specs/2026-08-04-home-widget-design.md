# Home Screen Widget — Design Spec

> **Status:** Approved for implementation. Follows the DDD+TDD+Deep Modules
> framework. The agent briefing at `.claude/briefings/home-screen-widget.md`
> must be filled before coding begins.
>
> **Conceived:** 2026-08-04 · **Inventor:** Mahmudul Hoque · **App:** Chores Star

## Vision

Chorly users frequently request a home-screen widget. For Chores Star, a widget
is a calm, high-value differentiator: it surfaces today's missions and current
streak without opening the app, which reinforces the habit loop and reduces
parent nagging.

The widget must be useful without being noisy. It shows:

1. A short greeting or the current streak.
2. Up to 3 today's missions.
3. A "Open Chores Star" tap target.

No animation, no real-time countdown, no badges beyond the count. The design
reuses the existing home hub data so no new backend is required.

## 1. Domain-Driven Design

### 1.1 Ubiquitous language (additions)

| Term | Means | Is NOT |
|------|-------|--------|
| Widget mission | A task due today, shown in the home-screen widget | A push notification |
| Widget entry | The top-level UI object rendered by iOS/Android home screen | A screen inside the app |

### 1.2 Bounded context

- **Task context** provides the task list.
- **Home context** (existing `home_stats.dart`) provides streak and level.
- The widget is a **read-only adapter** of the home context.

No new aggregate. The widget consumes the same providers the home hub uses.

---

## 2. Deep Module Architecture

### 2.1 Interface sketch

```dart
/// Data needed to render the home-screen widget.
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

/// Builds widget data from domain state.
class BuildHomeWidgetDataUseCase {
  HomeWidgetData call({
    required User user,
    required List<Task> todayTasks,
    required int streakDays,
    required int pendingApprovals,
  });
}
```

**Depth test:** The use case hides truncation, count limits, and fallback
copy. The widget extension only paints `HomeWidgetData`.

### 2.2 Platform implementation

- **iOS:** `HomeWidgetExtension` SwiftUI widget in `ios/HomeWidget/`.
- **Android:** `AppWidgetProvider` in `android/app/src/main/kotlin/.../ChoresStarWidget.kt`.
- **Bridge:** `home_widget` Flutter package for cross-platform data push and
tap handling.

### 2.3 Update trigger

The app calls the bridge whenever the home hub data changes:

```dart
// In the home notifier or after task approval
HomeWidget.updateWidget(
  name: 'ChoresStarWidget',
  androidName: 'ChoresStarWidget',
  iOSName: 'ChoresStarWidget',
);
```

A background refresh every 15 minutes keeps the widget current without draining
battery.

---

## 3. Test-Driven Development

### 3.1 Tests to satisfy

#### Domain / use case

- `widget data truncates mission list to 3 items`
- `widget data shows streak when non-zero`
- `widget data shows pending approval count when non-zero`
- `widget data falls back to a calm greeting when no missions exist`

#### Widget bridge

- `updateWidget is called after home data changes` (integration-style test
  with a mock bridge if possible)

#### Platform widgets

Platform widget tests are limited; verify via the iOS 18.5 simulator and a
physical Android device.

---

## 4. UI/UX design

### 4.1 Calm-UI constraints

- Background: `surface` token with a thin `line` border.
- Text: `ink` for headings, `inkSoft` for missions.
- Accent: `starGold` only for the streak flame and star icon.
- No animation. No countdowns. No progress rings.
- Corner radius 16, matching the app's card style.

### 4.2 Layout (small widget)

```
┌─────────────────────────────┐
│  Hi Aisha! 🔥 5-day streak   │
│                             │
│  Today                      │
│  • Feed the cat             │
│  • Water plants             │
│  • Tidy room                │
│                             │
│  Open Chores Star →         │
└─────────────────────────────┘
```

### 4.3 Medium widget (optional v2)

Adds the pending approval count for parents:

```
┌──────────────────────────────────────┐
│  Hi Aisha! 🔥 5-day streak          │
│                                      │
│  Today              2 waiting ⭐    │
│  • Feed the cat                      │
│  • Water plants                      │
│  • Tidy room                         │
└──────────────────────────────────────┘
```

Start with the **small widget only**. Ship the medium size as a fast follow-up.

---

## 5. Out of scope

- Interactive buttons on the widget.
- Real-time countdowns or timers.
- Multiple widget sizes in v1.
- Android large-screen layouts.
- Deep-linking to a specific task from the widget (tap opens the app to Home).

---

## 6. Incremental delivery

| Increment | Deliverable | Tests |
|---|---|---|
| 1 | `HomeWidgetData` + `BuildHomeWidgetDataUseCase` | Use-case tests |
| 2 | Add `home_widget` package and bridge method | Build passes, analyze clean |
| 3 | iOS widget extension + small widget SwiftUI | Simulator manual test |
| 4 | Android widget provider + Kotlin layout | Device manual test |
| 5 | Trigger widget update from home hub / task approval | Integration check |
| 6 | End-to-end verification on iOS 18.5 simulator | Manual |

---

## 7. Privacy and permissions

The widget reads the same data the app already displays locally. No new data
collection. No network calls from the widget itself; the app pushes data to
it.

On iOS, the widget extension is a separate target and must be added to the
App Store upload (handled by `scripts/deploy_testflight.sh` once the target is
configured in the Xcode project).

---

## 8. Related docs and memories

- Framework: `ENGINEERING.md`
- Existing home hub: `lib/presentation/screens/home_screen.dart`
- Motion/celebrations: memory `[[motion-phase1-progress]]`
- Agent briefing: `.claude/briefings/home-screen-widget.md`
