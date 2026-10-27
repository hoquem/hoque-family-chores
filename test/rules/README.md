# Firestore security-rules tests

Emulator-based tests for `firestore.rules`: **cross-family data isolation**,
and the fields a client must never be able to move on its own — `points` and
`role`.

These can't run under `flutter test`: a mock repository can't evaluate real
security rules, so they run Node scripts against the Firestore emulator.

## Run

Requires the Firebase CLI and a JDK (for the emulator).

```bash
cd test/rules
npm install          # once
npm test             # every rules suite, each in its own emulator boot
npm run test:roles   # just one suite
npm run test:functions   # the star economy, needs the functions + auth emulators
```

Each suite gets its own `firebase emulators:exec` so one suite's seed data
can't leak into another's assertions. Exit code is non-zero if any check fails.

## What it checks

| Suite | Proves |
| --- | --- |
| `family_isolation` | A member of family A cannot read/write family B's `tasks`, `rewards`, `redemptions`, or user profiles. A bare family id grants nothing — the join needs a `joinRequests/{uid}` doc, only creatable with a code that resolves to that family — while a legitimate invite-code join still works end to end. |
| `family_create` | A family cannot be created on someone else's behalf; invites cannot be minted for another family, repointed, deleted, or listed. |
| `points_lock` | No client writes `points`, self or parent. All star movement goes through the Cloud Functions. |
| `role_lock` | `role` is pinned once you are in a family, so nobody can promote themselves into `approveTask`'s parent exemption — while a joiner picking parent or child, and a parent re-grading a member, both still work. |
| `notification_read` | Notifications are readable and markable only by their owner. |
| `member_cleanup` | Deleting an account releases the leaver's unfinished chores and recurring-rule assignments and drops them from `memberIds`; `pendingApproval` work stays approvable; a second run is a no-op. |
| `managed_lock` | No client sets or clears `managed`, and no client reads or writes `profileLinks`; renaming a managed child still works. |
| `storage_managed` | `storage.rules` (storage + firestore emulators): a parent or guardian may upload, replace and delete JPEG task photos for any of the family's chores, a managed child's or a signed-in child's (trust-based; covers the child view on the parent's phone); another family's parent and a child who is not the assignee may not; the assignee still can; non-JPEG is refused. The emulator does not enforce production's two-documents-per-evaluation limit, so `storage.rules` documents the read count per allow. Run alone with `npm run test:storage`. |

**Adding a suite?** Wire it into `package.json` — `npm test` runs the named
scripts, so a file that isn't listed never runs.
