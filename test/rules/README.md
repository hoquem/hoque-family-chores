# Firestore security-rules tests

Emulator-based tests for `firestore.rules`, focused on **cross-family data
isolation** — proving one family cannot read or write another family's data,
and that joining a family requires a valid invite code (not just the family id).

These can't run under `flutter test`: a mock repository can't evaluate real
security rules, so they run a Node script against the Firestore emulator.

## Run

Requires the Firebase CLI and a JDK (for the emulator).

```bash
cd test/rules
npm install          # once
npm test             # boots the emulator, runs the checks, tears down
```

`npm test` runs:

```bash
firebase emulators:exec --only firestore --project demo-hoque \
  "node family_isolation.test.mjs"
```

Exit code is non-zero if any isolation check fails.

## What it checks

- A member of family A cannot read/write family B's `tasks`, `rewards`,
  `redemptions`, or user profiles.
- A bare family id no longer grants a family-doc read or a memberIds self-add
  (the join now requires a `joinRequests/{uid}` doc that is only creatable with
  a code resolving to that family).
- A legitimate invite-code join still works end to end.
