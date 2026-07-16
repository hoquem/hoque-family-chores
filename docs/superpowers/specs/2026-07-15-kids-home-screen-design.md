# Kids' Home Screen Redesign — Design Spec

**Date:** 2026-07-15
**Status:** Approved (user, in-session)

## Problem

The Home tab shows only an avatar, a points row, and a read-only task-count
summary. It gives children no reason to open the app and no path into their
work. (Separately fixed in this session: the screen had no AppBar, so its
content rendered under the iPhone notch.)

## Goals

The user chose all four directions:

1. **Today's missions** — the child's daily starting point, with
   tap-to-complete.
2. **Progress & streaks** — level progress and a consecutive-day streak.
3. **Celebrations** — an animated "all done" state.
4. **Family leaderboard peek** — stars earned this week, top three.

Role-based: children get the leaderboard; parents get a "needs approval"
card in that slot instead. Everything else is shared.

## Approach (chosen: A)

Derive all stats client-side from data the app already loads. `Task` carries
`completedAt`, `assignedToId`, and `points`, so streaks, today's missions,
and weekly stars are pure functions over the task list. No schema, backend,
or security-rule changes. Persisted streaks via Cloud Functions (approach B)
can layer on later without UI changes; a cosmetic facelift (C) was rejected
as not delivering the goals.

## Components

### Domain: `lib/domain/services/home_stats.dart` (pure, unit-tested)

- `TodayMissions todayMissions(List<Task> tasks, UserId userId, DateTime now)`
  — tasks assigned to the user due today or overdue, split into `toDo`
  (assigned / needsRevision), `waiting` (pendingApproval), and `done`
  (completed today). `allDone` = nothing to do and at least one waiting/done.
- `int streakDays(List<Task> tasks, UserId userId, DateTime now)` —
  consecutive calendar days (ending today, or yesterday if today has no
  completion yet) with ≥1 task the user completed (`completedAt`).
- `List<MemberStars> weeklyStars(List<Task> tasks, List<User> members, DateTime now)`
  — per member, sum of `points` of tasks completed since Monday 00:00,
  sorted descending.
- `int levelFromPoints(int points)` / `double levelProgress(int points)` —
  existing `points ~/ 100 + 1` rule, shared by header and progress card.

All functions take `now` as a parameter for testability.

### Presentation: `lib/presentation/widgets/home/` (one card per file)

- `greeting_header.dart` — avatar, "Hi {first name}! 👋", level + star balance.
- `progress_card.dart` — progress bar to next level, 🔥 streak line
  ("Start a streak today!" at zero).
- `today_missions_card.dart` — mission rows: difficulty marker, title,
  "+N ⭐" reward; tap-to-complete calls the existing
  `TaskListNotifier.completeTask` flow (→ pendingApproval); waiting rows
  show "Waiting for approval ⏳"; empty state "No missions today 🎈".
- `celebration_card.dart` — replaces the missions card when `allDone`;
  implicit animation (TweenAnimationBuilder), no new dependencies.
- `leaderboard_card.dart` — 🥇🥈🥉 top three from `weeklyStars` (child view).
- `approval_queue_card.dart` — family-wide pendingApproval count (parent
  view); tapping switches to the Tasks tab with the Needs Approval filter.

### Screen & navigation

- `home_screen.dart` composes the cards by `user.role`; keeps its existing
  auth-error and no-family states and the pull-to-refresh (now refreshing
  the task list + family members providers).
- New `BottomNavIndexNotifier` (riverpod codegen) so the approval card can
  switch `MainScreen` to the Tasks tab; `MainScreen` becomes a
  ConsumerWidget watching it.

### Removals

`TaskSummaryWidget` and `taskSummaryNotifierProvider` (plus generated
files) — the redesigned Home is their only consumer.

## Error handling

Task-list load failure surfaces the provider's error with a Retry (same
pattern as the Add Task assignee dropdown fixed earlier this session); no
silent empty states.

## Testing

- Unit tests for every `home_stats` function (streak edges: none today but
  yesterday unbroken, gap breaks streak; week boundary for stars).
- Widget tests: child sees missions/progress/leaderboard; completing a
  mission moves it to waiting; celebration on all-done; parent sees the
  approval card and tap-through sets tab + filter.
- TDD throughout (red first), matching the session's established mock +
  double-pump(300ms) test pattern.
