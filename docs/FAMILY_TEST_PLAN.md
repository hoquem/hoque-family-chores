# Hoque Family Chores — Family Test Plan

**Build:** 1.0.0+23 (TestFlight) · **Date:** July 2026
**Testers:** Mahmud (parent), Alima (parent), Tazim, Ehsaan, Yamin, Amira (children)

The goal: over about a week, use the app for real chores and tick off each
check below. Anything that fails or feels wrong goes in the bug log at the
bottom — one line is enough.

---

## Phase 1 — Devices & installs (Mahmud)

- [ ] Everyone's device has TestFlight installed and an invite from the
      "Family" tester group (auto-distributes new builds).
- [ ] App installs and opens on every device — no crash on launch.
- [ ] App icon, name, and version (1.0.0 build 23+) look right in TestFlight.

## Phase 2 — Parent accounts (Mahmud, then Alima)

- [ ] Mahmud: sign in with Google — lands on Home with his profile.
- [ ] Mahmud: sign in with **Apple** — this was broken ("Sign-Up Not
      Completed"); a fix was applied on the Apple developer side. Retest.
- [ ] Alima: create her account (Apple, Google, or email+password — pick
      one; email+password is the least-tested path, so trying that helps).
- [ ] Mahmud: Family tab → confirm the family exists and shows the
      **invite code**.
- [ ] Alima: join the family with the invite code → she appears in the
      member list on both parents' phones.

## Phase 3 — Kids join (one at a time, with a parent nearby)

For each of Tazim, Ehsaan, Yamin, Amira:

- [ ] On the login screen, tap the kids' button → enter first name + the
      family code → lands in the app, no email needed.
- [ ] Their name shows up in the Family tab on the parents' phones.
- [ ] Their Home greets them by name ("Hi Tazim! 👋") with Level 1 / 0 ⭐.

## Phase 4 — Setting up chores (parents)

- [ ] Tasks tab → + button → "Add New Task": create one small task per
      child, assigned to them, due **today** (title, effort size, assignee,
      due date).
- [ ] Create one **unassigned** task — it should show under the
      "Available" filter for anyone to claim.
- [ ] The due-date field: pick a date, then clear it with the ✕ — both work.
- [ ] Filters on the Tasks tab actually change the list: All / Available /
      My Tasks / Needs Approval / Completed.

## Phase 5 — A kid's day (each child, on their own device)

- [ ] Home shows **Today's Missions** with exactly their tasks for today
      (and anything overdue) with the star reward on each.
- [ ] Tap the circle on a mission → it moves to "Waiting for approval ⏳".
- [ ] Finish the last mission of the day → the 🎉 "All done for today!"
      celebration appears.
- [ ] A task a parent sends back for rework reappears in their missions.
- [ ] The weekly leaderboard shows 🥇🥈🥉 and updates as siblings earn stars.

## Phase 6 — A parent's day

- [ ] Parent Home shows the "Needs your approval" card with the right count.
- [ ] Tapping it opens the Tasks tab already filtered to Needs Approval.
- [ ] Approve a task → the child's stars go up; their level bar moves.
- [ ] Reject one (needs rework) → it returns to the child's missions.

## Phase 7 — Over the week

- [ ] Streaks: a child who completes something every day sees their 🔥
      streak count grow; missing a day resets it.
- [ ] Levels: crossing 100 ⭐ moves a child to Level 2.
- [ ] Leaderboard resets its weekly count on Monday.
- [ ] Pull-to-refresh works on Home and Tasks.
- [ ] The app behaves after being backgrounded for a day (stays signed in,
      data refreshes).

## Phase 8 — Settings & edges (parents)

- [ ] Edit Profile: change a display name; it updates around the app.
- [ ] Notifications screen: preferences save and persist after restart.
- [ ] Push notifications arrive (task assigned, approval requested/result) —
      note which ones do and don't.
- [ ] Security: change password (email accounts only).
- [ ] Sign out and back in — profile, family, and tasks all come back.
- [ ] Wrong family code on the kids' join screen shows a clear error.

---

## Bug log

| # | Who | Where (screen) | What happened | What you expected |
|---|-----|----------------|---------------|-------------------|
| 1 |     |                |               |                   |
| 2 |     |                |               |                   |
| 3 |     |                |               |                   |

**Known issues going in:** Apple sign-in fix is unverified (Phase 2);
Apple only shares your email on the very first sign-in — if an Apple
sign-in got stuck before, remove the app under Settings → Apple ID →
Sign-In & Security → "Sign in with Apple" and try fresh.
