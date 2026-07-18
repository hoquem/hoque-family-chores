# Analytics Event Log — Design

**Status:** approved, building
**Date:** 2026-07-18
**Goal:** Know how the app is used (to decide what to improve) via a thin,
privacy-first event log — not a third-party SDK.

## Decisions (with product owner)

- **Option 2: a Firestore event log**, not Firebase Analytics or a third-party
  tool. Data stays in the family's own Firebase project.
- **On by default, no PII.** Pseudonymous (Firebase uid only) — never names,
  emails, or free text. Disclosed in the privacy policy + store data-safety
  labels. A **kill-switch** can turn it off. (Explicit consent to be revisited
  before a wider public launch.)
- Question-driven: ~10 events chosen because each informs a decision. No
  firehose.

## Storage

Top-level `analyticsEvents` collection, one doc per event:

```
{
  name: string,            // from AnalyticsEventName
  userId: string,          // Firebase uid — pseudonymous, no PII
  familyId: string | null,
  params: map,             // low-card enums/counts only, no PII
  createdAt: serverTimestamp
}
```

**Rules — append-only.** Clients may only `create`; never read, update, or
delete. Analysis happens in BigQuery / Looker Studio, never in the app:

```
match /analyticsEvents/{id} {
  allow create: if isSignedIn();
  allow read, update, delete: if false;
}
```

## Architecture

Analytics is cross-cutting, so a thin app-level facade rather than a
domain-layer repository ceremony:

- `AnalyticsEventName` enum — the fixed event vocabulary.
- `Analytics` facade — `log(name, {userId, familyId, params})`. **Fire-and-forget
  and swallows its own errors (logged), never throws.** This is the one place a
  failure is deliberately tolerated: a dropped analytics event must never cost a
  user anything or break a screen. Honours a `kAnalyticsEnabled` kill-switch.
- `analyticsProvider` (Riverpod) wired to `FirebaseFirestore`.

## Events

Activation funnel (does the core loop work?):
`signed_in`, `family_created`, `family_joined`, `task_created`,
`task_completed`, `task_approved`, `reward_claimed`.

Discovery / engagement:
`screen_viewed` (param: tab), `help_opened` (param: screen), `reward_created`.

## Instrumentation points

- `signed_in` — AuthNotifier, after a successful sign-in.
- `family_created` / `family_joined` — after the respective use case succeeds.
- `task_created` / `task_completed` / `task_approved` — after the task notifier
  calls succeed.
- `reward_created` / `reward_claimed` — after the reward flows succeed.
- `screen_viewed` — MainScreen, on tab change (param: tab name).
- `help_opened` — HelpButton, on open (param: screen title).

## Out of scope

- Sessions/`app_open` (awkward to model in Firestore; infer from event
  timestamps later).
- Remote Config kill-switch (a `const` for now).
- Dashboards (Looker Studio over BigQuery — separate, user-side).
- Event retention/TTL (fine at pilot volume; revisit later).

## Testing

- `Analytics.log` writes a well-formed doc (fake_cloud_firestore) with name,
  userId, params, and never throws when the write fails.
- The kill-switch suppresses writes.
- No-PII guard is a review/discipline concern, not a runtime test.
